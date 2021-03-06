/*
 * Copyright (c) 2002-2003, Vanderbilt University
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
 * Author: Miklos Maroti, Brano Kusy
 * Date last modified: Oct/04
 * - moved getOffset, getSkew, and getSyncPt to TimeSyncInfo interface
 *
 */

interface GlobalTime
{
	/**
	 * Returns the current local time of this mote. The local time can 
	 * either be the SysTime as returned by SysTimeC (if the 
	 * TIMESYNC_SYSTIME macro is defined) or the ClockTime as returned 
	 * by the LocalTime interface of the ClockC component (if the
	 * TIMESYNC_SYSTIME is not defined).
	 */
	async command uint32_t getLocalTime();

	/**
	 * Reads the current global time. This method is a combination
	 * of <code>getLocalTime</code> and <code>local2Global</code>.
	 * @return SUCCESS if this mote is synchronized, FAIL otherwise.
	 */
	async command result_t getGlobalTime(uint32_t *time);

	/**
	 * Converts the local time given in <code>time</code> into the 
	 * corresponding global time and stores this again in 
	 * <code>time</code>. The following equation is used to compute the 
	 * conversion:
	 * 
	 *	globalTime = localTime + offset + skew * (localTime - syncPoint)
	 *
	 * The skew is normalized to 0.0 (1.0 is subtracted) to increase the
	 * machine precision. The syncPoint value is periodically updated to 
	 * increase the machine precision of the floating point arithmetic and
	 * also to allow time wrap.
	 *
	 * @return SUCCESS if this mote is synchronized, FAIL otherwise.
	 */
	async command result_t local2Global(uint32_t *time);

	/**
	 * Converts the global time given in <code>time</code> into the 
	 * correspoding local time and stores this again in 
	 * <code>time</code>. This method performs the inverse of the 
	 * <code>local2Global</clode> transformation.
	 *
	 * @return SUCCESS if this mote is synchronized, FAIL otherwise.
	 */
	async command result_t global2Local(uint32_t *time);
}
