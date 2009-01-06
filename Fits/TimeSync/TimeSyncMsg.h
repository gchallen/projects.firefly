/*
 * Copyright (c) 2002, 2003 Vanderbilt University
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
 * Author: Brano Kusy, Miklos Maroti
 * Date last modified: 05/20/03
 */

typedef struct TimeSyncMsg
{
	uint16_t	rootID;		// the node id of the synchronization root
	uint16_t	nodeID;		// the node if of the sender
	uint16_t	seqNum;		// sequence number for the root

	/* This field is initially set to the offset between global time and local 
	 * time. The TimeStamping component will add the current local time when the
	 * message is actually transmitted. Thus the receiver will receive the
	 * global time of the sender when the message is actually sent. */

  // 26 Jun 2005 : GWA : It appears as if there are races here that determine
  //               whether or not sendingTime gets corrected by the
  //               RadioReceive event handlers as it's flying out the door.
  //               I'm adding a stamp here that we'll write alongside the
  //               corrected time value, the idea being that if we don't get
  //               around to writing the wroteStamp field then the
  //               sendingTime is junk and the message should be discarded.
  //               This might lead to discarding a _few_ messages that
  //               contain valid sendingTime information but I can't imagine
  //               that that is going to really happen that often.

	uint32_t sendingTime;
  uint16_t wroteStamp;

	//just for convenience - not transmitted

  // 26 Jun 2005 : GWA : Trying overwriting this on receive.

	uint32_t 	arrivalTime;
} TimeSyncMsg;

enum {
	AM_TIMESYNCMSG = 0xAA,
	TIMESYNCMSG_LEN = sizeof(TimeSyncMsg) - sizeof(uint32_t),
  TS_TIMER_MODE = 0,    // see TimeSyncMode interface 
  TS_USER_MODE = 1,       // see TimeSyncMode interface

  // 26 Jun 2005 : GWA : We write 6 bytes in the outgoing message buffer: 4
  //               for the timestamp and 2 for the wroteStamp flag.

  TIMESYNC_LENGTH_SENDFIELDS = 6,
};
