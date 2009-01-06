configuration TestMicroTimer {
} implementation {
  components Main, TestMicroTimerM, MicroTimerM, LedsC;

  Main.StdControl -> TestMicroTimerM;

  TestMicroTimerM.MicroTimer -> MicroTimerM;
  TestMicroTimerM.Leds -> LedsC;
}
