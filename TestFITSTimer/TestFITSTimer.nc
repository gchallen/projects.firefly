configuration TestFITSTimer {
} implementation {
  components Main, TestFITSTimerM, LedsC, FITSTimerC;

  Main.StdControl -> FITSTimerC;
  Main.StdControl -> TestFITSTimerM;

  TestFITSTimerM.Leds -> LedsC;
  TestFITSTimerM.MicroTimer -> FITSTimerC;
  TestFITSTimerM.SysTime -> FITSTimerC;
}
