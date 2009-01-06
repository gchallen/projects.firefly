/*
 * Copyright (c) 2002-2004, Vanderbilt University
 * All rights reserved.
 *
 * Author: Brano Kusy (kusy@isis.vanderbilt.edu)
 *         Barbara Hohlt
 * Date last modified: Oct/04
 */

/**
  * time sync module (TimeSyncM) provides notification of arriving
  * and transmitted time-sync msgs through TimeSyncNotify interface:
  */
  
interface TimeSyncNotify
{
	/**
	 * fired when time-sync msg is received and accepted
	 */
	event void msg_received();

	/**
	 * fired when time-sync msg is sent by TimeSyncM or the sending did not
	 * succeed
	 */
	event void msg_sent();
	
 }


