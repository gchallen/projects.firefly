/*
* Copyright (c) 2006
*      The President and Fellows of Harvard College.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
* 1. Redistributions of source code must retain the above copyright
*    notice, this list of conditions and the following disclaimer.
* 2. Redistributions in binary form must reproduce the above copyright
*    notice, this list of conditions and the following disclaimer in the
*    documentation and/or other materials provided with the distribution.
* 3. Neither the name of the University nor the names of its contributors
*    may be used to endorse or promote products derived from this software
*    without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
* ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
* FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
* DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
* OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
* LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
* OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
* SUCH DAMAGE.
*/
module FITSTimerMSP430M {
  provides {
    interface MicroTimer;
    interface SysTime;
    interface StdControl;
  } uses {
    interface MSP430Timer;
    interface MSP430Compare;
    interface MSP430TimerControl;
    interface MSP430TimerControl as MSP430OverflowControl;
  }
} implementation {
  union time_u {
    struct {
      uint16_t low;
      uint16_t high;
    };
    uint32_t full;
  };

  bool timerActive;
  uint16_t bigTimer;
  uint16_t smallTimer;

  uint16_t currentTime;

  command result_t MicroTimer.start(uint32_t interval) {
    register union time_u timeNow;
    uint16_t currentTimeHigh;

    atomic {
      timeNow.full = call SysTime.getTime32();

      currentTimeHigh = timeNow.high;

      timeNow.full += interval;
      bigTimer = timeNow.high;
      smallTimer = timeNow.low;

      if (bigTimer == currentTimeHigh) {
          call MSP430Compare.setEvent(smallTimer);
          call MSP430TimerControl.clearPendingInterrupt();
          call MSP430TimerControl.enableEvents();
      }

      timerActive = TRUE;
    }

    return SUCCESS;
  }
  
  async command result_t MicroTimer.stop() {
    return SUCCESS;
  }

  async command uint16_t SysTime.getTime16() {
    return call MSP430Timer.read();
  }

  async command uint32_t SysTime.getTime32() {
    register union time_u time;

    atomic {
      time.low = call MSP430Timer.read();
      time.high = currentTime;

      if (call MSP430Timer.isOverflowPending() && 
         ((uint16_t) time.low >= 0)) {
        time.high++;
      }
    }
    return time.full;
  }

  async command uint32_t SysTime.castTime16(uint16_t inTime) {
    uint32_t time = call SysTime.getTime32();
    time += (uint16_t) inTime - (uint16_t) time;
    return time;
  }

  command result_t StdControl.init() {
    atomic {
      timerActive = FALSE;
      currentTime = 0;
    }
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call MSP430Timer.setMode(2);
    call MSP430OverflowControl.enableEvents();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call MSP430Timer.setMode(0);
    return SUCCESS;
  }

  async event void MSP430Timer.overflow() {
    atomic {
      currentTime++;
      
      if ((timerActive == TRUE) &&
          (currentTime == bigTimer)) {
        call MSP430Compare.setEvent(smallTimer);
        call MSP430TimerControl.clearPendingInterrupt();
        call MSP430TimerControl.enableEvents();
      }
    }
  }

  async event void MSP430Compare.fired() {
    atomic {
      call MSP430TimerControl.disableEvents();
      timerActive = FALSE;
      signal MicroTimer.fired();
    }
  }
  
  default event async result_t MicroTimer.fired() {
    return SUCCESS;
  }
}
