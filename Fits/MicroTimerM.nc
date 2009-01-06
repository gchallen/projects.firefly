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
// $Id: MicroTimerM.nc,v 1.3 2006-05-12 17:55:45 werner Exp $

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
module MicroTimerM
{
  provides interface MicroTimer; 
}
implementation {
  enum { CYCLES_PER_MILLISECOND = 7373L };
  bool running;

  command result_t MicroTimer.start(uint32_t interval) {
    uint32_t overflow;
    uint8_t prescaler;
    bool wasRunning;

    // Avoid overflow in calculations below. When we have large values
    // of interval (close to a Hz), we drop the milliseconds to avoid
    // overflow
    if (interval > 0xffffffffUL / CYCLES_PER_MILLISECOND)
      overflow = (interval / 1000) * CYCLES_PER_MILLISECOND;
    else
      overflow = (interval * CYCLES_PER_MILLISECOND) / 1000;

    // Pick a prescaler
    if (overflow >= 65536 * 1024)
      return FAIL; // This is something like .1Hz on mica2s
    else if (overflow >= 65536UL * 256)
      {
	prescaler = 5;
	overflow /= 1024;
      }
    else if (overflow >= 65536UL * 64)
      {
	prescaler = 4;
	overflow /= 256;
      }
    else if (overflow >= 65536UL * 8)
      {
	prescaler = 3;
	overflow /= 64;
      }
    else if (overflow >= 65536UL)
      {
	overflow /= 8;
	prescaler = 2;
      }
    else
      prescaler = 1;

    atomic
      {
	wasRunning = running;
	running = TRUE;
      }
    if (wasRunning)
      return FAIL;

    outp(0, TCCR3A);
    //outp(prescaler | 1 << WGM32, TCCR3B); // set prescaler  and overflow value
    // 12 Dec 2004 : GWA : Trying no CTC
    outp(prescaler, TCCR3B);
    outp(overflow >> 8, OCR3AH);
    outp(overflow, OCR3AL);
    outp(0, TCNT3H);		// reset timer
    outp(0, TCNT3L);
    sbi(ETIFR, OCF3A);		// clear pending interrupt
    sbi(ETIMSK, OCIE3A);		// enable overflow A interrupt

    return SUCCESS;
  }

  async command result_t MicroTimer.stop() {
    result_t ok = FAIL;

    atomic
      if (running)
	{
	  cbi(ETIMSK, OCIE3A);	// disable overflow A interrupt
	  sbi(ETIFR, OCF3A);	// clear pending interrupt
	  running = FALSE;
	  ok = SUCCESS;
	}
    return ok;
  }

  TOSH_SIGNAL(SIG_OUTPUT_COMPARE3A) {
    running = FALSE;
    signal MicroTimer.fired();
  }
}
