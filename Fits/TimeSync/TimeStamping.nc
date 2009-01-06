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
 * Author: Miklos Maroti
 * Date last modified: 12/05/03
 */

interface TimeStamping
{
	/**
	 * Returns the time stamp of the last received message. This
	 * method should be called when the ReceiveMsg.receive() is fired.
	 * The returned value contains the 32-bit local time when the message
	 * was received.
	 */

  // 26 Jun 2005 : GWA : Changed this to be more exact.  A pointer to the
  //               message that you want to stamp is passed and the result
  //               indicates whether the stamp that we have matches this
  //               message.  If so, it's passed back through a pointer.

	command result_t getStamp(TOS_MsgPtr ourMessage, uint32_t * timeStamp);

  // 26 Jun 2005 : GWA : Throwing out addStamp().  This was a relatively
  //               nasty race and it's not really the right way to do things.
  //               For the purposes of FTSP we now do filtering on AM type
  //               and add the stamp regardless of whether or not anyone told
  //               us to ;-).
}
