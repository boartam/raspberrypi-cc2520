#include "rpihardware.h"

module McuSleepP @safe() {
  provides {
    interface McuSleep;
    interface McuPowerState;
  }
  uses {
    interface McuPowerOverride;
    interface BlockingIO;
  }
}

implementation {

  mcu_power_t getPowerState() {
    return 0;
  }

  async command void McuSleep.sleep() {
    call BlockingIO.waitForIO();
  }

  async command void McuPowerState.update() {
  }

  default async command mcu_power_t McuPowerOverride.lowestState() {
    return 1;
  }

}
