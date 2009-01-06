module TestFITSTimerM {
  provides {
    interface StdControl;
  } uses {
    interface Leds;
    interface MicroTimer;
    interface SysTime;
  }
} implementation {
  
  command result_t StdControl.init() {

// 21 Feb 2005 : GWA : Stupid Mica2s.

#if defined(PLATFORM_MICA2)
    call Leds.init();
#endif
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Leds.greenToggle();
    call MicroTimer.start(1000);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  async event result_t MicroTimer.fired() {
    
    uint32_t test = call SysTime.getTime32();

    call Leds.redToggle();
    call MicroTimer.start(100000);
    return SUCCESS;
  }
}
