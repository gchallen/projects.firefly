// $Id: TOSBaseM.nc,v 1.1 2004-12-09 02:52:04 werner Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/*
 * @author Gilman Tolle
 * Revision:	$Id: TOSBaseM.nc,v 1.1 2004-12-09 02:52:04 werner Exp $
 */
  
/* 
 * TOSBaseM bridges packets between a serial channel and the radio.
 * Messages moving from serial to radio will be tagged with the group
 * ID compiled into the TOSBase, and messages moving from radio to
 * serial will be filtered by that same group id.
 */

#ifndef TOSBASE_BLINK_ON_DROP
#define TOSBASE_BLINK_ON_DROP
#endif

includes FitsMsg;

module TOSBaseM {
  provides interface StdControl;
  uses {
    interface StdControl as UARTControl;
    interface BareSendMsg as UARTSend;
    interface ReceiveMsg as UARTReceive;
    interface TokenReceiveMsg as UARTTokenReceive;

    interface StdControl as RadioControl;
    interface BareSendMsg as RadioSend;
    interface ReceiveMsg as RadioReceive;

    interface Leds;
    
    // 08 Dec 2004 : GWA : New.

    interface SysTime;
    interface RadioCoordinator as RadioReceiveCoordinator;
    interface RadioCoordinator as RadioSendCoordinator;
  }
}

implementation
{
  enum {
    UART_QUEUE_LEN = 12,
    RADIO_QUEUE_LEN = 12,
  };

  TOS_Msg    uartQueueBufs[UART_QUEUE_LEN];
  TOS_MsgPtr uartQueue[UART_QUEUE_LEN];
  uint8_t    uartIn, uartOut;
  bool       uartBusy, uartFull;

  TOS_Msg    radioQueueBufs[RADIO_QUEUE_LEN];
  TOS_MsgPtr radioQueue[RADIO_QUEUE_LEN];
  uint8_t    radioIn, radioOut;
  bool       radioBusy, radioFull;

  task void UARTSendTask();
  task void RadioSendTask();

  void failBlink();
  void dropBlink();
  
  // 08 Dec 2004 : GWA : Adding variable to store received time.

  bool receivedTimeInUse;
  uint32_t receivedTime;

  command result_t StdControl.init() {
    result_t ok1, ok2, ok3;
    uint8_t i;

    for (i = 0; i < UART_QUEUE_LEN; i++) {
      uartQueue[i] = &uartQueueBufs[i];
    }
    uartIn = uartOut = 0;
    uartBusy = FALSE;
    uartFull = FALSE;

    for (i = 0; i < RADIO_QUEUE_LEN; i++) {
      radioQueue[i] = &radioQueueBufs[i];
    }
    radioIn = radioOut = 0;
    radioBusy = FALSE;
    radioFull = FALSE;

    ok1 = call UARTControl.init();
    ok2 = call RadioControl.init();
    ok3 = call Leds.init();

    dbg(DBG_BOOT, "TOSBase initialized\n");
    
    // 08 Dec 2004 : GWA : Initializing our variables.

    receivedTimeInUse = FALSE;
    receivedTime = 0;

    return rcombine3(ok1, ok2, ok3);
  }

  command result_t StdControl.start() {
    result_t ok1, ok2;

    ok1 = call UARTControl.start();
    ok2 = call RadioControl.start();

    return rcombine(ok1, ok2);
  }

  command result_t StdControl.stop() {
    result_t ok1, ok2;
    
    ok1 = call UARTControl.stop();
    ok2 = call RadioControl.stop();

    return rcombine(ok1, ok2);
  }

  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr Msg) {
    TOS_MsgPtr pBuf = Msg;
 
    // 08 Dec 2004 : GWA : Hacking TOSBase to insert the received time.
    
    if (Msg->type == AM_FITSMSGT) {
      FitsMsgT * FitsFutz_Msg = (FitsMsgT *) Msg->data;
      FitsFutz_Msg->receivedtime = receivedTime;
      receivedTimeInUse = 0;
    }

    dbg(DBG_USR1, "TOSBase received radio packet.\n");

    if ((!Msg->crc) || (Msg->group != TOS_AM_GROUP))
      return Msg;

    atomic {
      if (!uartFull) {
	pBuf = uartQueue[uartIn];
	uartQueue[uartIn] = Msg;
	
	if( ++uartIn >= UART_QUEUE_LEN ) uartIn = 0;
	
	if (uartIn == uartOut) {
	  uartFull = TRUE;
	}

	if (!uartBusy) {
	  if (post UARTSendTask()) {
	    uartBusy = TRUE;
	  }
	}
      } else {
	dropBlink();
      }
    }

    return pBuf;
  }
  
  task void UARTSendTask() {
    bool noWork = FALSE;
    
    dbg (DBG_USR1, "TOSBase forwarding Radio packet to UART\n");

    atomic {
      if (uartIn == uartOut && uartFull == FALSE) {
	uartBusy = FALSE;
	noWork = TRUE;
      }
    }
    if (noWork) {
      return;
    }

    if (call UARTSend.send(uartQueue[uartOut]) == SUCCESS) {
      call Leds.greenToggle();
    } else {
      failBlink();
      post UARTSendTask();
    }
  }

  event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success) {

    if (!success) {
      failBlink();
    } else {

      atomic {
	if (msg == uartQueue[uartOut]) {
	  if( ++uartOut >= UART_QUEUE_LEN ) uartOut = 0;
	  if (uartFull) {
      	    uartFull = FALSE;
	  }
	}
      }
    }

    post UARTSendTask();

    return SUCCESS;
  }

  event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr Msg) {
    return Msg;
  }

  event TOS_MsgPtr UARTTokenReceive.receive(TOS_MsgPtr Msg, uint8_t Token) {
    TOS_MsgPtr  pBuf = Msg;
    bool reflectToken = FALSE;

    dbg(DBG_USR1, "TOSBase received UART token packet.\n");

    atomic {
      if (!radioFull) {
	reflectToken = TRUE;
	pBuf = radioQueue[radioIn];
	radioQueue[radioIn] = Msg;
	if( ++radioIn >= RADIO_QUEUE_LEN ) radioIn = 0;
	if (radioIn == radioOut)
	  radioFull = TRUE;

	if (!radioBusy) {
	  if (post RadioSendTask()) {
	    radioBusy = TRUE;
	  }
	}
      } else {
	dropBlink();
      }
    }

    if (reflectToken) {
      call UARTTokenReceive.ReflectToken(Token);
    }
    
    return pBuf;
  }

  task void RadioSendTask() {

    bool noWork = FALSE;

    dbg (DBG_USR1, "TOSBase forwarding UART packet to Radio\n");

    atomic {
      if (radioIn == radioOut && radioFull == FALSE) {
	radioBusy = FALSE;
	noWork = TRUE;
      }
    }
    if (noWork)
      return;

    radioQueue[radioOut]->group = TOS_AM_GROUP;
    
    if (call RadioSend.send(radioQueue[radioOut]) == SUCCESS) {
      call Leds.redToggle();
    } else {
      failBlink();
      post RadioSendTask();
    }
  }

  event result_t RadioSend.sendDone(TOS_MsgPtr msg, result_t success) {

    if (!success) {
      failBlink();
    } else {
      atomic {
	if (msg == radioQueue[radioOut]) {
	  if( ++radioOut >= RADIO_QUEUE_LEN ) radioOut = 0;
	  if (radioFull)
	    radioFull = FALSE;
	}
      }
    }
    
    post RadioSendTask();
    return SUCCESS;
  }

  void dropBlink() {
#ifdef TOSBASE_BLINK_ON_DROP
    call Leds.yellowToggle();
#endif
  }

  void failBlink() {
#ifdef TOSBASE_BLINK_ON_FAIL
    call Leds.yellowToggle();
#endif
  }
  
  async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, 
                                                    uint8_t offset, 
                                                    TOS_MsgPtr msgBuff) { }
                                                    
  async event void RadioSendCoordinator.byte(TOS_MsgPtr msg, 
                                             uint8_t byteCount) { }
  
  async event void RadioSendCoordinator.blockTimer() { }                                         
  async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, 
                                                       uint8_t offset, 
                                                       TOS_MsgPtr msgBuff) { 
    atomic {
      if (!receivedTimeInUse) {
        receivedTime = call SysTime.getTime32();
        receivedTimeInUse = 1;
      }
    }
  }

  async event void RadioReceiveCoordinator.byte(TOS_MsgPtr msg, 
                                                 uint8_t byteCount) { }
  
  async event void RadioReceiveCoordinator.blockTimer() { }

}  
