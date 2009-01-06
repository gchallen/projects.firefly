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
includes FitsMsg;

// 15 Dec 2004 : GT  : The two timers are needed for FITS, but there are issues
//               using them separately. Hence we try to multiplex the two
//               timers.
//
//
// 13 Dec 2004 : GWA : An attempt to multiplex SysTime and MicroTimer
//               functionality onto the same timer, Timer3 on the ATMega128.
//                
//               The main problem I can forsee is that, because we need to
//               let the counter roll, in some cases, irrespective of the
//               interval, we will have very small overflow values.
//               MicroTimer gets around this by requiring microsecond time
//               values.  We don't, rather using jiffies instead since this
//               is more suitable for our application.  I'm hoping that this
//               is handled correctly, but if we miss a few interrupts that
//               shouldn't be the end of the world.
//
//               Note that this timer is implicitly TIMER_ONE_SHOT.  Doing a
//               TIMER_REPEAT would not be much cleaner, and we don't happen
//               to need it.
//
// 21 Feb 2005 : GWA : I'm going to take a stab at porting this to Telos.
//               Shouldn't be too hard (not even sure it's necessary, really)
//               since Telos actually provides interfaces into these things
//               rather than making me touch processor instructions
//               directly.
//
// 21 Feb 2005 : GWA : Scratch the above.  Moved to FITSTimerATMega128M.
//               Beginning development on FITSTimerMSP430M.

module FITSTimerATMega128M {
  provides {
    interface MicroTimer;
    interface SysTime;
    interface StdControl;
  }
} implementation {
 
  // 13 Dec 2004 : GWA : Global globals.

  union time_u {
    struct {
      uint16_t low;
      uint16_t high;
    };
    uint32_t full;
  };

  // 13 Dec 2004 : GWA : Timer globals.
  
  bool timerActive;
  uint16_t bigTimer;
  uint16_t smallTimer;

  // 13 Dec 2004 : GWA : Clock globals.

  uint16_t currentTime;

  // 13 Dec 2004 : GWA : MicroTimer interface.  Note that interval is now in
  //               ticks, rather than microseconds.  This is both easier for
  //               me to implement and suits my purposes, so there you have
  //               it.
  
  command result_t MicroTimer.start(uint32_t interval) {
    register union time_u timeNow;
    uint16_t currentTimeHigh;

    atomic {

      // 13 Dec 2004 : GWA : Get current time, identical to getTime32().

      timeNow.low = __inw(TCNT3L);
      timeNow.high = currentTime;

      // 13 Dec 2004 : GWA : Handle pending interrupts.

      if (bit_is_set(ETIFR, TOV3) &&
         ((int16_t) timeNow.low >= 0)) {
        timeNow.high++;
      }
      currentTimeHigh = timeNow.high;

      // 13 Dec 2004 : GWA : Now add on our interval, figure out big and
      //               small portions.

      timeNow.full += interval;
      bigTimer = timeNow.high;
      smallTimer = timeNow.low;

      // 13 Dec 2004 : GWA : If it's within the interval we need to do this
      //               now!
      
      if (bigTimer == currentTimeHigh) {

        // 13 Dec 2004 : GWA : Set overflow value.
        
        outp(smallTimer >> 8, OCR3AH);
        outp(smallTimer, OCR3AL);
        
        // 13 Dec 2004 : GWA : Clear pending interrupt.
        
        sbi(ETIFR, OCF3A);
        
        // 13 Dec 2004 : GWA : Enable overflow A interrupt.

        sbi(ETIMSK, OCIE3A);
      }

      // 13 Dec 2004 : GWA : Otherwise we're OK.

      timerActive = TRUE;
    }
    
    return SUCCESS;
  }

  async command result_t MicroTimer.stop() {
    atomic {

      // 13 Dec 2004 : GWA : Disable overflow A interrupt.
      
      cbi(ETIMSK, OCIE3A);

      // 13 Dec 2004 : GWA : Clear pending interrupt.

      sbi(ETIFR, OCF3A);

      // 13 Dec 2004 : GWA : Mark timer off.

      timerActive = FALSE;
    }
    return SUCCESS;
  }
  
  // 13 Dec 2004 : GWA : SysTime interface.  Unmodified.

  async command uint16_t SysTime.getTime16() {
    return __inw_atomic(TCNT3L);
  }

  async command uint32_t SysTime.getTime32() {
    register union time_u time;

    atomic {
      time.low = __inw(TCNT3L);
      time.high = currentTime;

      // 13 Dec 2004 : GWA : Handle pending interrupts.

      if (bit_is_set(ETIFR, TOV3) &&
         ((int16_t) time.low >= 0)) {
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
  
  // 13 Dec 2004 : GWA : StdControl interface.

  command result_t StdControl.init() {
    uint8_t etimsk;

    // 13 Dec 2004 : GWA : Clear timer control registers.

    outp(0x00, TCCR3A);
    outp(0x00, TCCR3B);

    // 13 Dec 2004 : GWA : Set some flags.  Not sure what these do yet.

    atomic {
      etimsk = inp(ETIMSK);
      etimsk &= (1 << OCIE1C);
      etimsk |= (1 << TOIE3);
      outp(etimsk, ETIMSK);
      timerActive = FALSE;
      currentTime = 0;
    }

    return SUCCESS;
  }

  command result_t StdControl.start() {

    // 13 Dec 2004 : GWA : Start timer with appropriate prescaler.

    outp(FITSTIMER_PRESCALER, TCCR3B);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    
    // 13 Dec 2004 : GWA : Stop timer.
    
    outp(0x00, TCCR3B);
    return SUCCESS;
  }

  // 13 Dec 2004 : GWA : Signal handlers.

  TOSH_SIGNAL(SIG_OVERFLOW3) {
    
    // 13 Dec 2004 : GWA : Update our big time counter.

    currentTime++;
    
    // 13 Dec 2004 : GWA : If we have a running timer and it big time is upon
    //               us, set it up.
    
    if ((timerActive == TRUE) &&
        (currentTime == bigTimer)) {
     
      // 13 Dec 2004 : GWA : See comments on identical code above.
      
      outp(smallTimer >> 8, OCR3AH);
      outp(smallTimer, OCR3AL);
      sbi(ETIFR, OCF3A);
      sbi(ETIMSK, OCIE3A);
    }
  }

  TOSH_SIGNAL(SIG_OUTPUT_COMPARE3A) {
    
    // 13 Dec 2004 : GWA : Disable compare interrupt.
    
    cbi(ETIMSK, OCIE3A);
    
    // 13 Dec 2004 : GWA : Mark timer off.

    timerActive = FALSE;
    signal MicroTimer.fired();
  }
  
  default event async result_t MicroTimer.fired() {
    return SUCCESS;
  }
}
