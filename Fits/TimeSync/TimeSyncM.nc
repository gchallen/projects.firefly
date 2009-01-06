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

module TimeSyncM {
    provides {
        interface StdControl;
        interface GlobalTime;
        
        // 25 May 2005 : GWA : Optional interfaces.

        interface TimeSyncInfo;
        interface TimeSyncMode;
        interface TimeSyncNotify;
    } uses {
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

// 25 May 2005 : GWA : If defined use our connectivity simulation code.

#ifdef SOFTWARE_TOPOLOGY_FTSP
        interface NodeConnectivity;
#endif
    }
} implementation {

  // 25 May 2005 : GWA : Some magic numbers controlling FTSP operation.  I've
  //               moved these to allow modification through preprocessor
  //               defines.

  enum {
    
    // 25 May 2005 : GWA : Number of entries in our history table.

#ifdef FTSP_MAX_ENTRIES
    MAX_ENTRIES = FTSP_MAX_ENTRIES,        
#else
    MAX_ENTRIES = 8,
#endif

    // 25 May 2005 : GWA : How often to send the beacon message (seconds).

#ifdef FTSP_TIMESYNC_RATE
    BEACON_RATE = FTSP_TIMESYNC_RATE,
#else
    BEACON_RATE = 30,
#endif

    // 25 May 2005 : GWA : Number of sync periods before a node declares
    //               itself the root.
#ifdef FTSP_ROOT_TIMEOUT
    ROOT_TIMEOUT = FTSP_ROOT_TIMEOUT,
#else
    ROOT_TIMEOUT = 4,
#endif

    // 25 May 2005 : GWA : Number of sync periods to ignore other root
    //               messages after becoming the root.

#ifdef FTSP_IGNORE_ROOT_MSG
    IGNORE_ROOT_MSG = FTSP_IGNORE_ROOT_MSG,
#else
    IGNORE_ROOT_MSG = 4,
#endif

    // 25 May 2005 : GWA : Number of entries in the table to become
    //               synchronized.
#ifdef FTSP_ENTRY_VALID_LIMIT
    ENTRY_VALID_LIMIT = FTSP_ENTRY_VALID_LIMIT,
#else
    ENTRY_VALID_LIMIT = 4,
#endif

    // 25 May 2005 : GWA : Number of entries in the table before we begin
    //               sending syncronization messages.
#ifdef FTSP_ENTRY_SEND_LIMIT
    ENTRY_SEND_LIMIT = FTSP_ENTRY_SEND_LIMIT,
#else
    ENTRY_SEND_LIMIT = 3,
#endif

    // 25 May 2005 : GWA : Defines the time sync error at which point we
    //               clear the table.
#ifdef FTSP_ENTRY_THROWOUT_LIMIT
      ENTRY_THROWOUT_LIMIT = FTSP_ENTRY_THROWOUT_LIMIT,
#else
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICAZ) || defined(PLATFORM_TELOS) || defined (PLATFORM_TELOSB)
      ENTRY_THROWOUT_LIMIT = 100,
#else
      // 25 May 2005 : GWA : Slower CPU on Mica/Mica2DOT.

      ENTRY_THROWOUT_LIMIT = 800,
#endif
#endif
  };

    typedef struct TableItem
    {
        uint16_t     state;
        uint32_t    localTime;
        int32_t     timeOffset; // globalTime - localTime
    } TableItem;

    enum {
        ENTRY_EMPTY = 0,
        ENTRY_FULL = 1,
    };

    TableItem   table[MAX_ENTRIES];
    uint16_t tableEntries;

    enum {
        STATE_IDLE = 0x00,
        STATE_PROCESSING = 0x01,
        STATE_SENDING = 0x02,
        STATE_INIT = 0x04,
    };

    uint16_t state, mode;
    
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
    uint16_t     numEntries; // the number of full entries in the table

    uint16_t missedSendStamps, missedReceiveStamps;

    TOS_Msg processedMsgBuffer;
    TOS_MsgPtr processedMsg;

    TOS_Msg outgoingMsgBuffer;
    #define outgoingMsg ((TimeSyncMsg*)outgoingMsgBuffer.data)

    uint16_t heartBeats; // the number of sucessfully sent messages
                // since adding a new entry with lower beacon id than ours

    async command uint32_t GlobalTime.getLocalTime()
    {
#ifdef TIMESYNC_SYSTIME
        return call SysTime.getTime32();
#else
        return call LocalTime.read();
#endif
    }

    result_t is_synced()
    {
        return numEntries>=ENTRY_VALID_LIMIT || outgoingMsg->rootID==TOS_LOCAL_ADDRESS;
    }
    
    async command result_t GlobalTime.getGlobalTime(uint32_t *time)
    { 
        *time = call GlobalTime.getLocalTime();
// 04 Jun 2005 : GWA : Something weird happens here when the root starts to
//               calculate a skew and offset (from what???).  Let's try and
//               preclude that.
        if (outgoingMsg->rootID == TOS_LOCAL_ADDRESS) {
          return is_synced();
        } else {
          return call GlobalTime.local2Global(time);
        }
    }
    
    async command result_t GlobalTime.local2Global(uint32_t *time)
    {
        if (outgoingMsg->rootID == TOS_LOCAL_ADDRESS) {
          return is_synced();
        }
        *time += offsetAverage + (int32_t)(skew * (int32_t)(*time - localAverage));
        return is_synced();
    }

    async command result_t GlobalTime.global2Local(uint32_t *time)
    {
        uint32_t approxLocalTime = *time - offsetAverage;
        if (outgoingMsg->rootID == TOS_LOCAL_ADDRESS) {
          return is_synced();
        }
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
            (timeError > ENTRY_THROWOUT_LIMIT || timeError < -ENTRY_THROWOUT_LIMIT)) {
                clearTable();
                // 04 Jun 2004 : GWA : Try just dropping this entry.
                //return;
        }

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
        TimeSyncMsg * msg = (TimeSyncMsg*) processedMsg->data;

#ifdef FTSP_STATIC_ROOT
        if (TOS_LOCAL_ADDRESS == FTSP_STATIC_ROOT_ID) {
          goto exit;
        }
#endif
        //call Leds.greenToggle();
        if( msg->rootID < outgoingMsg->rootID && 
            ~(heartBeats < IGNORE_ROOT_MSG && outgoingMsg->rootID == TOS_LOCAL_ADDRESS) ){
          call Leds.redToggle();
            outgoingMsg->rootID = msg->rootID;
            outgoingMsg->seqNum = msg->seqNum;
        } else if( outgoingMsg->rootID == msg->rootID && (int8_t)(msg->seqNum - outgoingMsg->seqNum) > 0 ) {
            call Leds.yellowToggle();
            outgoingMsg->seqNum = msg->seqNum;
        }
        else
            goto exit;
        addNewEntry(msg);
        calculateConversion();
        signal TimeSyncNotify.msg_received();   

    exit:
        state &= ~STATE_PROCESSING;
    }

    event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p) {

      TOS_MsgPtr old;
      TimeSyncMsg * newMessage = (TimeSyncMsg *) p->data;

#ifdef SOFTWARE_TOPOLOGY_FTSP
      uint16_t incomingID = (uint16_t)((TimeSyncMsg*)p->data)->nodeID;
      bool connResult = 
        call NodeConnectivity.connected(incomingID,
                                        TOS_LOCAL_ADDRESS);
      if (connResult == FALSE) {
        return p;
      }
#endif

      // 26 Jun 2005 : GWA : Bail if the arrival timestamp that we retrieve
      //               doesn't match this message.

      if (call TimeStamping.getStamp(p, 
                                     &(newMessage->arrivalTime)) != SUCCESS) { 
        atomic missedReceiveStamps++;
        return p;
      }

      // 26 Jun 2005 : GWA : Bail if this message doesn't have a valid
      //               sending timestamp.
      
      if (newMessage->wroteStamp != SUCCESS) {
        atomic missedSendStamps++;
        return p;
      }

      atomic {
        if (state & STATE_PROCESSING) {
          return p;
        } else {
          state |= STATE_PROCESSING;
        } 
      }

      // 26 Jun 2005 : GWA : Swap pointers and get to work.

      old = processedMsg;
      processedMsg = p;

      post processMsg();
      return old;
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
#ifndef FTSP_STATIC_ROOT
        else if( heartBeats >= ROOT_TIMEOUT ) {
            heartBeats = 0; //to allow ROOT_SWITCH_IGNORE to work
            outgoingMsg->rootID = TOS_LOCAL_ADDRESS;
            ++(outgoingMsg->seqNum); // maybe set it to zero?
        }
#endif

        outgoingMsg->sendingTime = globalTime - localTime;
        outgoingMsg->wroteStamp = FAIL;

        // we don't send time sync msg, if we don't have enough data
#ifndef FTSP_STATIC_ROOT
        if( numEntries < ENTRY_SEND_LIMIT && outgoingMsg->rootID != TOS_LOCAL_ADDRESS ){
            ++heartBeats;
#else
        if (numEntries < ENTRY_SEND_LIMIT && outgoingMsg->rootID != FTSP_STATIC_ROOT_ID) {
#endif
            state &= ~STATE_SENDING;
        }
        else{
          //call Leds.greenToggle();
            if(call SendMsg.send(TOS_BCAST_ADDR, TIMESYNCMSG_LEN, &outgoingMsgBuffer) != SUCCESS ) {
                state &= ~STATE_SENDING;
                signal TimeSyncNotify.msg_sent();
            }
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
#ifndef FTSP_STATIC_ROOT
            if( outgoingMsg->rootID == TOS_LOCAL_ADDRESS )
                ++(outgoingMsg->seqNum);
#else
            if (TOS_LOCAL_ADDRESS == FTSP_STATIC_ROOT_ID) {
              ++(outgoingMsg->seqNum);
            }
#endif
        }

        state &= ~STATE_SENDING;
        signal TimeSyncNotify.msg_sent();
        
        return SUCCESS;
    }

    void timeSyncMsgSend()  
    {
#ifndef FTSP_STATIC_ROOT
        if( outgoingMsg->rootID == 0xFFFF && ++heartBeats >= ROOT_TIMEOUT ) {
            outgoingMsg->seqNum = 0;
            outgoingMsg->rootID = TOS_LOCAL_ADDRESS;
        }
#endif
        
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

    command result_t TimeSyncMode.setMode(uint16_t mode_){
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
    
    command uint16_t TimeSyncMode.getMode(){
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
#ifndef FTSP_STATIC_ROOT
        outgoingMsg->rootID = 0xFFFF;
#else
        if (TOS_LOCAL_ADDRESS == FTSP_STATIC_ROOT_ID) {
          outgoingMsg->rootID = TOS_LOCAL_ADDRESS;
        } else {
          outgoingMsg->rootID = 0xFFFF;
        }
#endif
        processedMsg = &processedMsgBuffer;
        state = STATE_INIT;
        atomic missedSendStamps = missedReceiveStamps = 0;

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
    async command uint16_t   TimeSyncInfo.getSeqNum() { return outgoingMsg->seqNum; }
    async command uint16_t   TimeSyncInfo.getNumEntries() { return numEntries; } 
    async command uint16_t   TimeSyncInfo.getHeartBeats() { return heartBeats; }
    async command uint32_t   TimeSyncInfo.getLocalAverage() { 
      return localAverage;
    }
    async command int32_t    TimeSyncInfo.getOffsetAverage() {
      return offsetAverage;
    }
    async command uint16_t TimeSyncInfo.getMissedSendStamps() {
      return missedSendStamps;
    }
    async command uint16_t TimeSyncInfo.getMissedReceiveStamps() {
      return missedReceiveStamps;
    }
    default event void TimeSyncNotify.msg_received(){};
    default event void TimeSyncNotify.msg_sent(){};
}
