includes TestSortMsg;

module TestSortM {
  provides {
    interface StdControl;
  }
  uses {
    interface Random;
  }
} implementation {
  TestSortQueueT testSortQueue[TESTSORT_QUEUE_SIZE];
  uint8_t currentQueuePosition;
  uint8_t lastStoredIndex;
  
  command result_t StdControl.init() {
    uint8_t i;
    for (i = 0; i < TESTSORT_QUEUE_SIZE; i++) {
      testSortQueue[i].valid = 0;
      testSortQueue[i].data = 0;
    }
    currentQueuePosition = 0;
    lastStoredIndex = 0;
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  task void testSortTask() {
    // 06 Dec 2004 : GWA : Various variables used locally.  We need to store
    //               several different epoch times, etc, yeah, a disaster.

    uint8_t i;
    uint8_t sortIndex;
    uint8_t count = 0;
    uint8_t sortCount = 0;
    uint8_t sortElementCount = 0;
    uint8_t numSwaps = 0;
    uint32_t packetArrivalDifference = 0;
    uint32_t elapsedEpochTime = 0;
    uint32_t currentEpochTime = 0;
    uint32_t setTimerAmountMs = 0;
    uint32_t sortSaveBeginning;
    uint32_t sortSaveEnd;
    uint32_t sortTemp;
    uint8_t startFill = (uint8_t) (call Random.rand() % 32);
    uint8_t stopFill = (uint8_t) (call Random.rand() % 32);
    uint32_t startEpochJiffies = (call Random.rand() % 128);
    uint32_t endEpochJiffies = startEpochJiffies + (call Random.rand() % 128);
    for (i = startFill; (i % 32) != stopFill; i++) {
      testSortQueue[i].data = (call Random.rand() % 1024);
      testSortQueue[i].valid = 1;
    }
    
    dbg(DBG_TEMP, "BEFORE SORT : Printing Queue...\n");
    dbg(DBG_TEMP, "Sorting from %d to %d\n", startFill, stopFill);
    dbg(DBG_TEMP, "Epoch begins %d ends %d\n", startEpochJiffies,
    endEpochJiffies);
    dbg(DBG_TEMP, "LaststoredIndex %d\n", lastStoredIndex);
    for (i = 0; i < 32; i++) {
      dbg(DBG_TEMP, "\t%d\t%d\n", i, testSortQueue[i].data);
    }

    
    // 06 Dec 2004 : GWA : This queue sort is sort of dumb, and occurs in two
    //               phases: 1) walk the queue to figure out what to sort, 2)
    //               sort that portion of the queue.  The sorting itself is
    //               inefficient, but I don't really care at this point.
    
    sortIndex = startFill;
    sortSaveBeginning = startFill;
    sortSaveEnd = stopFill;

    // 06 Dec 2004 : GWA : First pass; figure out limits.
    
    while (sortCount < TESTSORT_QUEUE_SIZE) {
      
      if (testSortQueue[sortIndex].valid == 0) {
        break;
      }

      // 06 Dec 2004 : GWA : This should never happen, but we handle it.

      if (testSortQueue[sortIndex].data < startEpochJiffies) {
        testSortQueue[sortIndex].valid = 0;
        testSortQueue[sortIndex].data = 0;
        lastStoredIndex = (lastStoredIndex + 1) % TESTSORT_QUEUE_SIZE;
        sortSaveBeginning = (sortSaveBeginning + 1) % TESTSORT_QUEUE_SIZE;
      } else if (testSortQueue[lastStoredIndex].data < endEpochJiffies) {
        sortSaveEnd = lastStoredIndex;    
      }
      sortCount++;
      sortIndex = (sortIndex + 1) % TESTSORT_QUEUE_SIZE;
    }
   
    // 06 Dec 2004 : GWA : Now, second loop.  Sort within limits.

    if (sortSaveEnd >= sortSaveBeginning) {
      sortElementCount = sortSaveEnd - sortSaveBeginning;
    } else {
      sortElementCount = TESTSORT_QUEUE_SIZE - (sortSaveBeginning - sortSaveEnd);
    }
    dbg(DBG_TEMP, "Sortcount : %d, %d, %d\n", 
                  sortElementCount, sortSaveBeginning, sortSaveEnd);
    if (sortElementCount > 0) {
      do {
        numSwaps = 0;
        for (sortIndex = 0; 
             sortIndex < sortElementCount;
             sortIndex++) {
          uint8_t first = (sortSaveBeginning + sortIndex) % 32;
          uint8_t second = (sortSaveBeginning + sortIndex + 1) % 32;
          if (testSortQueue[first].data >
              testSortQueue[second].data) {
            sortTemp = testSortQueue[first].data;
            testSortQueue[first].data =
              testSortQueue[second].data;
            testSortQueue[second].data = 
              sortTemp;
            numSwaps++;
          }
        }
        if (numSwaps > 0) {
          dbg(DBG_TEMP, "Did %d swaps...\n", numSwaps);
        }
      } while (numSwaps > 0);
    }
    dbg(DBG_TEMP, "AFTER SORT : Printing Queue...\n");
    for (i = 0; i < 32; i++) {
      dbg(DBG_TEMP, "\t%d\t%d\n", i, testSortQueue[i].data);
    }
    post testSortTask();
  }
  
  command result_t StdControl.start() {
    dbg(DBG_TEMP, "Startup...\n");
    post testSortTask();
    return SUCCESS;
  }
}
