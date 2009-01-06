/*
 * @author: Brano Kusy, kusy@isis.vanderbilt.edu
 * Date last modified: jan05
 *
 * provides timestamping on transmitting/receiving SFD interrupt in CC2420.
 * uses LocalTime interface provided by TimerC: 4 byte local time from TimerB.
 *
 */

configuration ClockTimeStampingC {
  provides {
    interface TimeStamping;
  }
} implementation {
  components ClockTimeStampingM, CC2420RadioM, TimerC, HPLCC2420M;

  TimeStamping = ClockTimeStampingM;
  
  ClockTimeStampingM.RadioSendCoordinator -> CC2420RadioM.RadioSendCoordinator;
  ClockTimeStampingM.RadioReceiveCoordinator -> CC2420RadioM.RadioReceiveCoordinator;
  ClockTimeStampingM.LocalTime -> TimerC;
  ClockTimeStampingM.HPLCC2420RAM -> HPLCC2420M;
}
