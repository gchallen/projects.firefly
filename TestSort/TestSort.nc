includes TestSortMsg;

configuration TestSort {
} implementation {
  components Main, TestSortM, TimerC, RandomLFSR;

  Main.StdControl -> TestSortM;
  
  TestSortM.Random -> RandomLFSR;
}
