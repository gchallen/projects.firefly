/*
 * @author: Brano Kusy, kusy@isis.vanderbilt.edu
 * Date last modified: jan05
 *
 * provides timestamping on transmitting/receiving SFD interrupt,uses 
 * SysTime (Timer3) to get local time 
 *
 */

configuration SysTimeStampingC
{
	provides
	{
		interface TimeStamping;
	}
}

implementation
{
	components SysTimeStampingM, CC2420RadioM, NoLeds as LedsC,
#if (defined(PLATFORM_TELOS) || defined(PLATFORM_TELOSB) || defined(PLATFORM_MICAZ)) && defined(TIMESYNC_SYSTIME)
  FITSTimerC as SysTimeC,
#else
  SysTimeC,
#endif
  HPLCC2420M;

	TimeStamping = SysTimeStampingM;
	
	SysTimeStampingM.RadioSendCoordinator -> CC2420RadioM.RadioSendCoordinator;
	SysTimeStampingM.RadioReceiveCoordinator -> CC2420RadioM.RadioReceiveCoordinator;
	SysTimeStampingM.SysTime		 -> SysTimeC;
	SysTimeStampingM.Leds   -> LedsC;
	SysTimeStampingM.HPLCC2420RAM    -> HPLCC2420M;
}
