module TestMicroTimerM {
  provides {
    interface StdControl;
  }
  uses {
    interface MicroTimer;
    interface Leds;
  }
} implementation {
  uint8_t counter;
  command result_t StdControl.init() {
    counter = 0;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call MicroTimer.start(1000000);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  async event result_t MicroTimer.fired() {
    call Leds.redToggle();
    counter++;
    if (counter % 2) {
      call MicroTimer.start(500000);
    } else {
      call MicroTimer.start(1000000);
    }
    return SUCCESS;
  }
}
