//#define USE_NODECON
#define NOIGNORE_PERIOD
enum {
  AM_FITSMSGT = 111,
  AM_DELAYMSGT = 112,
  AM_FITSDIAGMSGT = 113,
  AM_FITSINFOMSGT = 114,
  AM_FITSFIRINGMSGT = 115,
  FITS_QUEUE_SIZE = 64,

  // 15 Dec 2004 : GWA : Various time constants, different for different
  //               platforms.
  FITS_EPOCH_SCALER = 6,
#if defined(PLATFORM_MICAZ) || defined(PLATFORM_MICA2)

  // 13 Dec 2004 : GWA : These need to be changed together!  0x02 corresponds
  //               to 1/8 prescaling which corresponds to 921.6KHz.

  FITS_EPOCH_JIFFY_LENGTH = (921600 * FITS_EPOCH_SCALER),
  FITSTIMER_PRESCALER = 0x02,
  FITS_MS_TO_JIFFIES = 922,
  FITS_BASE_PERIOD = FITS_EPOCH_JIFFY_LENGTH,
#elif defined(PLATFORM_TELOS)
  FITS_EPOCH_JIFFY_LENGTH = 1048576,
  FITS_MS_TO_JIFFIES = 1048,
  FITS_BASE_PERIOD = 1048576,
#elif defined(PLATFORM_PC)
  FITS_EPOCH_JIFFY_LENGTH = 4000000,
  FITS_BINARY_MS = 1024,
  FITS_MS_TO_JIFFIES = 4000,
  FITS_BASE_PERIOD = 1024,
  FITS_IGNORE_PERIOD_SCALE = 4,

  // 11 Mar 2005 : GWA : The packet-level simulations introduce a 1/40 second
  //               delay corresponding to the mica radio stack (this should
  //               be fixed).  We need to account for this to work around the
  //               two packet problem.

  FITS_SEND_CORRECTION = 100000,
#endif

  // 15 Dec 2004 : GWA : Defines the period at the beginning of an interval
  //               when we do not accept packets.  In milliseconds.
  
  FITS_SKIP_TOO_EARLY = 2,
  FITS_SKIP_NO_DELAY = 3,
  FITS_SKIP_TOO_CLOSE = 4,
  FITS_SKIP_LAST_EPOCH = 5,
  FITS_IGNORE_PERIOD = (10 * FITS_EPOCH_SCALER),

  // 15 Dec 2004 : GWA : We're trying to reduce additivity by not processing
  //               all of a group of packets that arrive within a given
  //               interval.  These intervals are in JIFFIES and therefor
  //               must be platform-specefic, since I'm guessing that we want
  //               these intervals to be VERY short.

#ifdef PLATFORM_PC
#ifdef NOIGNORE_PERIOD
  FITS_PACKET_IGNORE_PERIOD = 0,
#else
  FITS_PACKET_IGNORE_PERIOD = 20000,
#endif
#else
#ifdef NOIGNORE_PERIOD
  FITS_PACKET_IGNORE_PERIOD = 0,
#else
  FITS_PACKET_IGNORE_PERIOD = 4000,
#endif
#endif
  // 13 Dec 2004 : GWA : Trying a bit of a longer interval for multihop.
  //               These are in milliseconds.

  FITS_PROCESS_DELAY = 250,
  FITS_SEND_DELAY = 25,
  FITS_SYNCED_THRESHOLD = 100,

  // 23 Feb 2005 : GWA : Offsets into the FitsMsgT struct to use while doing
  //               the RAM rewriting needed on the CC2420 platforms.  This
  //               needs to be kept in sync with FitsMsgT, obviously.

#if defined(PLATFORM_MICAZ) || defined(PLATFORM_TELOS) || defined(TOSSIMCC2420)
  FITS_TIME_OFFSET = 12,
  FITS_DELAY_OFFSET = 16,
  FITS_WROTESTAMP_OFFSET = 20,

  // 23 Feb 2005 : GWA : Taken from FTSP code.  Not sure how they figured
  //               this out; we'll see if it works.

  TX_FIFO_MSG_START = 10,
#endif
};

enum {
  FIRINGFUNCTIONLOG2M_CONSTANT = (100 * FITS_EPOCH_SCALER),
};

struct FitsMsgT {
  uint16_t sourceaddr;
  uint32_t receivedtime;
  uint16_t seqno;
  uint32_t myPeriod;

  // 21 Feb 2005 : GWA : We can do packet-level rewriting on the Mica2, so we
  //               don't need DelayMsgT and the fields there get moved here.
  //
  // 23 Feb 2005 : GWA : Experimenting with packet-level rewriting on Telos,
  //               MicaZ.
  //
  // 11 Mar 2005 : GWA : That works, now we're hacking up TOSSIM to use this
  //               as well.

  uint32_t senttime;
  uint32_t sentdelay;
  uint16_t wroteStamp;
} __attribute__ ((packed));
typedef struct FitsMsgT FitsMsgT;

struct FitsDiagMsgT {
  uint16_t sourceaddr;
  uint16_t rootID;
  uint32_t firetime;
  bool synced;
  uint32_t fireSeqNo;
} __attribute__ ((packed));
typedef struct FitsDiagMsgT FitsDiagMsgT;

struct FitsInfoMsgT {
  uint16_t myaddr;
  uint16_t sourceaddr;
  uint16_t myseqno;
  uint16_t seqno;
  uint16_t queueIndex;
  uint32_t arrivalTime;
  uint32_t FTSPStamp;
  uint32_t sentdelay;
  bool FTSPSynced;
  bool ignored;
} __attribute__ ((packed));
typedef struct FitsInfoMsgT FitsInfoMsgT;

struct FitsFiringMsgT {
  uint16_t sourceaddr;
  uint32_t nextInterval;
  uint16_t seqno;
  uint32_t myPeriod;
  uint16_t synced;
  uint32_t largestDifference;
} __attribute__ ((packed));
typedef struct FitsFiringMsgT FitsFiringMsgT;

// 11 Mar 2005 : GWA : DelayMsgT removed; shouldn't need it.

struct FitsQueue {
  uint16_t sourceaddr;
  uint16_t seqno;
  uint32_t arrivalTime;
  bool valid;
  bool sawDelay;
  bool pleaseLog;
  bool ignored;
  uint32_t FTSPStamp;
  uint32_t sentdelay;
  uint32_t period;
  bool FTSPSynced;
} __attribute__ ((packed));
typedef struct FitsQueue FitsQueueT;
