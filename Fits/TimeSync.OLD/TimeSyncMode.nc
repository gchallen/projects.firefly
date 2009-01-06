/*
 * Copyright (c) 2002-2004, Vanderbilt University
 * All rights reserved.
 *
 * Author: Brano Kusy (kusy@isis.vanderbilt.edu)
           Barbara Hohlt
 * Date last modified: Oct/04
 */

/**
  * the time sync module can work in two modes:
  *            - TS_TIMER_MODE (default): TS msgs sent period. from the timer
  *            - TS_USER_MODE: TS msgs sent only when explic. asked by user 
  *                            via TimeSyncMode.send() command, TimeSync.Timer 
  *                            is stopped in this mode
  */
  
interface TimeSyncMode
{
	/**
	 * Sets the current mode of the TimeSync module.
	 * returns FAIL if didn't succeed
	 */
	command result_t setMode(uint8_t mode);

	/**
	 * Gets the current mode of the TimeSync module.
	 */
	command uint8_t getMode();
	
	/**
	 * command to send out time synchronization message.
	 * returns FAIL if TimeSync not in TS_USER_MODE
	 */
	command result_t send();
	
 }


