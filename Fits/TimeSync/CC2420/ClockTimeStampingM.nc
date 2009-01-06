/*
 * @author: Brano Kusy, kusy@isis.vanderbilt.edu; Geoffrey Werner-Allen,
 *          werner@eecs.harvard.edu
 * Date last modified: 26 Jun 2005
 *
 * provides timestamping on transmitting/receiving SFD interrupt.
 */

#include "AM.h"
includes TimeSyncMsg;

module ClockTimeStampingM {
  provides {
    interface TimeStamping;
  } uses {
    interface RadioCoordinator as RadioSendCoordinator;
    interface RadioCoordinator as RadioReceiveCoordinator;
    interface LocalTime;
    interface HPLCC2420RAM;
  }
} implementation {
 
  uint32_t rcv_time;
  TOS_MsgPtr rcv_message;

  enum {
    TX_FIFO_MSG_START = 10,

    // 24 Jun 2005 : GWA : Cory's suggestion for TELOSB.

    SEND_TIME_CORRECTION = 0,
  };
      
  // 26 Jun 2005 : GWA : This function used to be part of a more general
  //               purpose library for timestamping outgoing messages.  That
  //               didn't seem to work all that well and it relied on timing
  //               issues that I don't understand well.  For our purposes we
  //               want FTSP to work and don't really give a damn about
  //               preserving the general semantics, so I've changed this to
  //               simply add stamps to all messages with the FTSP AM type.
  //
  // 26 Jun 2005 : GWA : There also seems to be a subtle race going on here
  //               concerning the timestamping of outgoing messages.  The
  //               correct operation of FTSP is current almost _entirely_
  //               exigent on this getting done.  If a node receives a
  //               message with this information that doesn't line up
  //               correctly with it's past history it discards the history
  //               (is that the right thing to do?) and usually ends up with
  //               a skew and view of the world that are totally wrong.  For
  //               a period of time this crap infects everyone, especially in
  //               networks where connectivity is limited (such as ours).
  //               I'm trying a solution here that adds a flag that lets us
  //               know whether we wrote the timestamp correctly or not.  If
  //               we didn't we'll dump the message on the receiver side.

  async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, 
                                                    uint8_t offset, 
                                                    TOS_MsgPtr msgBuff) {
    uint32_t send_time;
    
    // 24 Jun 2005 : GWA : Just do filtering based on AM type.

    if (msgBuff->type != AM_TIMESYNCMSG) {
      return;
    }

    // 26 Jun 2005 : GWA : Adding a guard to prevent us from in some strange
    //               cases adding multiple stamps!  I don't think that this
    //               happens but hell, might as well.
    
    if (((TimeSyncMsg *) msgBuff->data)->wroteStamp == SUCCESS) {
      return;
    }
    
    atomic send_time = call LocalTime.read() - SEND_TIME_CORRECTION;
   
    ((TimeSyncMsg *) msgBuff->data)->sendingTime += send_time;
    ((TimeSyncMsg *) msgBuff->data)->wroteStamp = SUCCESS;
    
    // 26 Jun 2005 : GWA : Write the fields.

    call HPLCC2420RAM.write(TX_FIFO_MSG_START + 
                            offsetof(TimeSyncMsg, sendingTime),
                            TIMESYNC_LENGTH_SENDFIELDS,
                            (void*) (msgBuff->data + 
                                     offsetof(TimeSyncMsg, sendingTime)));
    return;
  }
  
  // 26 Jun 2005 : GWA : Yet another race condition.  If a new message comes
  //               in before we get the stamp the stamp could be attached to
  //               another message. 
  //
  //               I can think of two ways of rectifying this.  The first is
  //               more subtle and the one I'm going to try first.  We'll
  //               just write the stamp into the TOS_MsgPtr at the correct
  //               place and _rely_ on the fact that FTSP sends a few less
  //               bytes than it expects to receive.  Other components that
  //               use the radio will either a) not expect any valid data at
  //               this offset or b) just overwrite it out of the actually
  //               CC2420 received data anyways, so perhaps this is safe.
  //
  // 26 Jun 2005 : GWA : Well, that doesn't seem to work.  Let's try saving
  //               the TOS_MsgPtr alongside the timestamp and comparing them
  //               below.

  async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, 
                                                       uint8_t offset, 
                                                       TOS_MsgPtr msgBuff) {
    atomic { 
      rcv_time = call LocalTime.read();
      rcv_message = msgBuff;
    }
    return;
  }

  // 25 Jun 2005 : GWA : OK, fine, I'm not going to change the TimeStamping
  //               interface.  But we'll just make addStamp() a nop.
  //
  // 26 Jun 2005 : GWA : Took care of getting rid of it.

	command result_t TimeStamping.getStamp(TOS_MsgPtr ourMessage, 
                                         uint32_t * timeStamp) {
		atomic {
      if (ourMessage == rcv_message) {
        *timeStamp = rcv_time;
        return SUCCESS;
      } else {
        return FAIL;
      }
    }
	}

  // 24 Jun 2005 : GWA : Unused parts of various interfaces.

  async event result_t HPLCC2420RAM.readDone(uint16_t addr, 
                                             uint8_t length, 
                                             uint8_t* buffer) {
    return SUCCESS;
  }
  
  async event result_t HPLCC2420RAM.writeDone(uint16_t addr, 
                                              uint8_t length, 
                                              uint8_t* buffer) {
    return SUCCESS;
  }
  
  async event void RadioSendCoordinator.byte(TOS_MsgPtr msg, 
                                             uint8_t byteCount) { 
    return;
  }
  
  async event void RadioSendCoordinator.blockTimer() { 
    return;
  }

  async event void RadioReceiveCoordinator.byte(TOS_MsgPtr msg, 
                                                uint8_t byteCount) { 
    return;
  }
  
  async event void RadioReceiveCoordinator.blockTimer() { 
    return;
  }
}
