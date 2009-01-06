enum {
  TESTSORT_QUEUE_SIZE = 32,
};

struct TestSortQueue {
  uint32_t data;
  bool valid;
} __attribute__ ((packed));

typedef struct TestSortQueue TestSortQueueT;
