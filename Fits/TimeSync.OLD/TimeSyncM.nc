/*
 * Copyright (c) 2002, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * @author: Miklos Maroti, Brano Kusy (kusy@isis.vanderbilt.edu)
 * Date last modified: jan05
 *
 * suggestions, contributions:  Barbara Hohlt
 *                              Janos Sallai
 */
includes Timer;
includes TimeSyncMsg;

module TimeSyncM
{
    provides 
    {
        interface StdControl;
        interface GlobalTime;
        
        //interfaces for extra fcionality: need not to be wired 
        interface TimeSyncInfo;
        interface TimeSyncMode;
        interface TimeSyncNotify;
    }
    uses
    {
        interface SendMsg;
        interface ReceiveMsg;
        interface Timer;
        interface Leds;
        interface TimeStamping;
#ifdef TIMESYNC_SYSTIME
        interface SysTime;
#else
        interface LocalTime;
#endif
#ifdef TIMESYNC_DEBUG   // this code can be used to simulate multiple hopsf
        interface NodeConnectivity;
#endif
    }
}
implementation
{
#ifndef TIMESYNC_RATE
#define TIMESYNC_RATE   30
#endif

    enum {
        MAX_ENTRIES = 8,        // number of entries in the table
        BEACON_RATE = TIMESYNC_RATE,    // how often send the beacon msg (in seconds)
        ROOT_TIMEOUT = 5,           //time to declare itself the root if no msg was received (in sync periods)
        IGNORE_ROOT_MSG = 4,    // after becoming the root ignore other roots messages (in send period)
        ENTRY_VALID_LIMIT = 4,      // number of entries to become synchronized
        ENTRY_SEND_LIMIT = 3,       // number of entries to send sync messages
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICAZ)
        ENTRY_THROWOUT_LIMIT = 100, // if time sync error is bigger than this clear the table
#else
        ENTRY_THROWOUT_LIMIT = 800, // MICA and MICA2DOT have slower CPU
#endif
    };

    typedef struct TableItem
    {
        uint8_t     state;
        uint32_t    localTime;
        int32_t     timeOffset; // globalTime - localTime
    } TableItem;

    enum {
        ENTRY_EMPTY = 0,
        ENTRY_FULL = 1,
    };

    TableItem   table[MAX_ENTRIES];
    uint8_t tableEntries;

    enum {
        STATE_IDLE = 0x00,
        STATE_PROCESSING = 0x01,
        STATE_SENDING = 0x02,
        STATE_INIT = 0x04,
    };

    uint8_t state, mode;
    
/*
    We do linear regression from localTime to timeOffset (globalTime - localTime). 
    This way we can keep the slope close to zero (ideally) and represent it 
    as a float with high precision.
        
        timeOffset - offsetAverage = skew * (localTime - localAverage)
        timeOffset = offsetAverage + skew * (localTime - localAverage) 
        globalTime = localTime + offsetAverage + skew * (localTime - localAverage)
*/

    float       skew;
    uint32_t    localAverage;
    int32_t     offsetAverage;
    uint8_t     numEntries; // the number of full entries in the table

    TOS_Msg processedMsgBuffer;
    TOS_MsgPtr processedMsg;

    TOS_Msg outgoingMsgBuffer;
    #define outgoingMsg ((TimeSyncMsg*)outgoingMsgBuffer.data)

    uint8_t heartBeats; // the number of sucessfully sent messages
                // since adding a new entry with lower beacon id than ours

    async command uint32_t GlobalTime.getLocalTime()
    {
#ifdef TIMESYNC_SYSTIME
        return call SysTime.getTime32();
#else
        return call LocalTime.read();
#endif
    }

    async command result_t GlobalTime.getGlobalTime(uint32_t *time)
    { 
        *time = call GlobalTime.getLocalTime();
        return call GlobalTime.local2Global(time);
    }

    result_t is_synced()
    {
        return numEntries>=ENTRY_VALID_LIMIT || outgoingMsg->rootID==TOS_LOCAL_ADDRESS;
    }
    
    
    async command result_t GlobalTime.local2Global(uint32_t *time)
    {
        *time += offsetAverage + (int32_t)(skew * (int32_t)(*time - localAverage));
        return is_synced();
    }

    async command result_t GlobalTime.global2Local(uint32_t *time)
    {
        uint32_t approxLocalTime = *time - offsetAverage;
        *time = approxLocalTime - (int32_t)(skew * (int32_t)(approxLocalTime - localAverage));
        return is_synced();
    }

    void calculateConversion()
    {
        float newSkew = skew;
        uint32_t newLocalAverage;
        int32_t newOffsetAverage;

        int64_t localSum;
        int64_t offsetSum;

        int8_t i;

        for(i = 0; i < MAX_ENTRIES && table[i].state != ENTRY_FULL; ++i)
            ;

        if( i >= MAX_ENTRIES )  // table is empty
            return;
/*
        We use a rough approximation first to avoid time overflow errors. The idea 
        is that all times in the table should be relatively close to each other.
*/
        newLocalAverage = table[i].localTime;
        newOffsetAverage = table[i].timeOffset;

        localSum = 0;
        offsetSum = 0;

        while( ++i < MAX_ENTRIES )
            if( table[i].state == ENTRY_FULL ) {
                localSum += (int32_t)(table[i].localTime - newLocalAverage) / tableEntries;
                offsetSum += (int32_t)(table[i].timeOffset - newOffsetAverage) / tableEntries;
            }

        newLocalAverage += localSum;
        newOffsetAverage += offsetSum;

        localSum = offsetSum = 0;
        for(i = 0; i < MAX_ENTRIES; ++i)
            if( table[i].state == ENTRY_FULL ) {
                int32_t a = table[i].localTime - newLocalAverage;
                int32_t b = table[i].timeOffset - newOffsetAverage;

                localSum += (int64_t)a * a;
                offsetSum += (int64_t)a * b;
            }

        if( localSum != 0 )
            newSkew = (float)offsetSum / (float)localSum;

        atomic
        {
            skew = newSkew;
            offsetAverage = newOffsetAverage;
            localAverage = newLocalAverage;
            numEntries = tableEntries;
        }
    }

    void clearTable()
    {
        int8_t i;
        for(i = 0; i < MAX_ENTRIES; ++i)
            table[i].state = ENTRY_EMPTY;

        atomic numEntries = 0;
    }

    void addNewEntry(TimeSyncMsg *msg)
    {
        int8_t i, freeItem = -1, oldestItem = 0;
        uint32_t age, oldestTime = 0;
        int32_t timeError;

        tableEntries = 0;

        // clear table if the received entry is inconsistent
        timeError = msg->arrivalTime;
        call GlobalTime.local2Global(&timeError);
        timeError -= msg->sendingTime;          
        if( is_synced() &&
            (timeError > ENTRY_THROWOUT_LIMIT || timeError < -ENTRY_THROWOUT_LIMIT))
                clearTable();

        for(i = 0; i < MAX_ENTRIES; ++i) {
            ++tableEntries;
            age = msg->arrivalTime - table[i].localTime;

            //logical time error compensation
            if( age >= 0x7FFFFFFFL )
                table[i].state = ENTRY_EMPTY;

            if( table[i].state == ENTRY_EMPTY ){ 
                --tableEntries;
                freeItem = i;
            }

            if( age >= oldestTime ) {
                oldestTime = age;
                oldestItem = i;
            }
        }

        if( freeItem < 0 )
            freeItem = oldestItem;
        else
            ++tableEntries;

        table[freeItem].state = ENTRY_FULL;

        table[freeItem].localTime = msg->arrivalTime;
        table[freeItem].timeOffset = msg->sendingTime - msg->arrivalTime;
    }

    void task processMsg()
    {
        TimeSyncMsg* msg = (TimeSyncMsg*)processedMsg->data;
        call Leds.greenToggle();

        if( msg->rootID < outgoingMsg->rootID && 
            ~(heartBeats < IGNORE_ROOT_MSG && outgoingMsg->rootID == TOS_LOCAL_ADDRESS) ){
            outgoingMsg->rootID = msg->rootID;
            outgoingMsg->seqNum = msg->seqNum;
        }
        else if( outgoingMsg->rootID == msg->rootID && (int8_t)(msg->seqNum - outgoingMsg->seqNum) > 0 ) {
            outgoingMsg->seqNum = msg->seqNum;
        }
        else
            goto exit;

        if( outgoingMsg->rootID < TOS_LOCAL_ADDRESS )
            heartBeats = 0;

        addNewEntry(msg);
        calculateConversion();
        signal TimeSyncNotify.msg_received();   

    exit:
        state &= ~STATE_PROCESSING;
    }

    event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p)
    {
#ifdef TIMESYNC_DEBUG   // this code can be used to simulate multiple hopsf
        uint8_t incomingID = (uint8_t)((TimeSyncMsg*)p->data)->nodeID;
        (int8_t)((TimeSyncMsg *)p->data)->nodeID = 
        bool connResult = 
          call NodeConnectivity.connected(incomingID,
                                          TOS_LOCAL_ADDRESS);
        if (connResult == FALSE) {
          call Leds.redToggle();
          return p;
        }
#endif

        if( (state & STATE_PROCESSING) == 0 ) {
            TOS_MsgPtr old = processedMsg;

            processedMsg = p;
            ((TimeSyncMsg*)(processedMsg->data))->arrivalTime = call TimeStamping.getStamp();

            state |= STATE_PROCESSING;
            post processMsg();

            return old;
        }

        return p;
    }

    task void sendMsg()
    {
        uint32_t localTime, globalTime;

        globalTime = localTime = call GlobalTime.getLocalTime();
        call GlobalTime.local2Global(&globalTime);

        // we need to periodically update the reference point for the root
        // to avoid wrapping the 32-bit (localTime - localAverage) value
        if( outgoingMsg->rootID == TOS_LOCAL_ADDRESS ) {
            if( (int32_t)(localTime - localAverage) >= 0x20000000 )
            {
                atomic
                {
                    localAverage = localTime;
                    offsetAverage = globalTime - localTime;
                }
            }
        }
        else if( heartBeats >= ROOT_TIMEOUT ) {
            heartBeats = 0; //to allow ROOT_SWITCH_IGNORE to work
            outgoingMsg->rootID = TOS_LOCAL_ADDRESS;
            ++(outgoingMsg->seqNum); // maybe set it to zero?
        }

        outgoingMsg->sendingTime = globalTime - localTime;

        // we don't send time sync msg, if we don't have enough data
        if( numEntries < ENTRY_SEND_LIMIT && outgoingMsg->rootID != TOS_LOCAL_ADDRESS ){
            ++heartBeats;
            state &= ~STATE_SENDING;
        }
        else{
          call Leds.greenToggle();
            if( call SendMsg.send(TOS_BCAST_ADDR, TIMESYNCMSG_LEN, &outgoingMsgBuffer) != SUCCESS ){
                state &= ~STATE_SENDING;
                signal TimeSyncNotify.msg_sent();
            }
            else
                call TimeStamping.addStamp(offsetof(TimeSyncMsg,sendingTime));
        }
    }
    
    event result_t SendMsg.sendDone(TOS_MsgPtr ptr, result_t success)
    {
        /* not our Msg ! hohlt */
        if (ptr != &outgoingMsgBuffer)
          return SUCCESS;

        if( success )
        {
            ++heartBeats;
            //call Leds.redToggle();

            if( outgoingMsg->rootID == TOS_LOCAL_ADDRESS )
                ++(outgoingMsg->seqNum);
        }

        state &= ~STATE_SENDING;
        signal TimeSyncNotify.msg_sent();
        
        return SUCCESS;
    }

    void timeSyncMsgSend()  
    {
        if( outgoingMsg->rootID == 0xFFFF && ++heartBeats >= ROOT_TIMEOUT ) {
            outgoingMsg->seqNum = 0;
            outgoingMsg->rootID = TOS_LOCAL_ADDRESS;
        }
        
        if( outgoingMsg->rootID != 0xFFFF && (state & STATE_SENDING) == 0 ) {
            state |= STATE_SENDING;
            post sendMsg();
        }
    }

    event result_t Timer.fired()
    {
      if (mode == TS_TIMER_MODE)
        timeSyncMsgSend();
      else
        call Timer.stop();
        
      return SUCCESS;
    }

    command result_t TimeSyncMode.setMode(uint8_t mode_){
        if (mode == mode_)
            return SUCCESS;
            
        if (mode_ == TS_USER_MODE){
            if (call Timer.start(TIMER_REPEAT, (uint32_t)1000 * BEACON_RATE) == FAIL)
                return FAIL;
        }
        else if (call Timer.stop() == FAIL)
            return FAIL;
            
        mode = mode_;
        return SUCCESS;        
    }
    
    command uint8_t TimeSyncMode.getMode(){
        return mode;
    }
    
    command result_t TimeSyncMode.send(){
        if (mode == TS_USER_MODE){
            timeSyncMsgSend();
            return SUCCESS;
        }
        return FAIL;
    }
    
    command result_t StdControl.init() 
    { 
        atomic{
            skew = 0.0;
            localAverage = 0;
            offsetAverage = 0;
        };

        clearTable();

        outgoingMsg->rootID = 0xFFFF;

        processedMsg = &processedMsgBuffer;
        state = STATE_INIT;

        return SUCCESS;
    }

    command result_t StdControl.start() 
    {
        mode = TS_TIMER_MODE;
        heartBeats = 0;
        outgoingMsg->nodeID = TOS_LOCAL_ADDRESS;
        call Timer.start(TIMER_REPEAT, (uint32_t)1000 * BEACON_RATE);

        return SUCCESS; 
    }

    command result_t StdControl.stop() 
    {
        call Timer.stop();
        return SUCCESS; 
    }

    async command float     TimeSyncInfo.getSkew() { return skew; }
    async command uint32_t  TimeSyncInfo.getOffset() { return offsetAverage; }
    async command uint32_t  TimeSyncInfo.getSyncPoint() { return localAverage; }
    async command uint16_t  TimeSyncInfo.getRootID() { return outgoingMsg->rootID; }
    async command uint8_t   TimeSyncInfo.getSeqNum() { return outgoingMsg->seqNum; }
    async command uint8_t   TimeSyncInfo.getNumEntries() { return numEntries; } 
    async command uint8_t   TimeSyncInfo.getHeartBeats() { return heartBeats; }

    default event void TimeSyncNotify.msg_received(){};
    default event void TimeSyncNotify.msg_sent(){};
}
