
module HalAlarmP {
 provides {
    interface Alarm<TMilli, uint32_t> as Alarm[uint8_t alarmid];
    interface TimerQuery;
    interface Init;
  }
  uses {
    interface TimerFired;
  }
}

implementation {

  #define MAX_ALARMS 10

  // A list of timers.
  // Each uint32_t is the absolute time in microseconds the timer should fire.
  uint32_t timers[MAX_ALARMS];

  // Keep track of the absolute time the most recent alarm was set at, in
  // milliseconds.
  // This is for the getAlarm() function.
  uint32_t last_alarm;

  // The ID of the alarm that is next up and will fire next
  uint8_t active_alarm_id;

  uint32_t get_now_micro () {
    struct timespec clock_val;
    int             ret;

    ret = clock_gettime(CLOCK_MONOTONIC, &clock_val);
    if (ret != 0) {
      return 0;
    }

    // return the time now in microseconds
    return (clock_val.tv_sec * 1000000) + (clock_val.tv_nsec / 1000);
  }

  command error_t Init.init() {
    memset(timers, 0, sizeof(uint32_t)*MAX_ALARMS);

    return SUCCESS;
  }

  async command void Alarm.start[uint8_t alarmid] (uint32_t dt) {
    call Alarm.startAt[alarmid](call Alarm.getNow[alarmid](), dt);
  }

  async command void Alarm.startAt[uint8_t alarmid] (uint32_t t0, uint32_t dt) {
    uint32_t now;
    uint32_t elapsed;

    atomic {

      now = get_now_micro();

      // save the alarm time
      last_alarm = t0 + dt;

      elapsed = now - (t0*1000);

      if (elapsed >= (dt*1000)) {
        // we requested an alarm for a time that already happened
        // trigger an alarm in 0.5 ms
        timers[alarmid] = now + 500;

      } else {
        // Set a new timer for the right time in the future
        timers[alarmid] = now + (dt*1000) - elapsed;

      }

    }
  }

  async command void Alarm.stop[uint8_t alarmid] () {
    atomic timers[alarmid] = 0;
  }

  async command bool Alarm.isRunning[uint8_t alarmid] () {
    return (timers[alarmid] > 0);
  }

  async command uint32_t Alarm.getNow[uint8_t alarmid] () {
    // return the time now in milliseconds
    return get_now_micro()/1000;
  }

  async command uint32_t Alarm.getAlarm[uint8_t alarmid] () {
    uint32_t la;
    atomic la = last_alarm;
    return la;
  }

  command uint32_t TimerQuery.nextTimerTime () {
    uint32_t now = get_now_micro();
    uint32_t closest = UINT32_MAX;
    uint8_t closest_id = 0;

    int i;

    for (i=0; i<MAX_ALARMS; i++) {
      if (timers[i] <= now) {
        // The timer should have fired in the past. I'm not quite sure when
        //  this should happen (if ever) but....
        return 1;
      }
      if (timers[i] - now < closest) {
        closest = timers[i] - now;
        closest_id = i;
      }
    }

    if (closest == UINT32_MAX) {
      // No timers set. Return 0 will make the select() call have a default
      //  timeout len.
      return 0;
    }

    active_alarm_id = closest_id;

    return closest - now;
  }

  event void TimerFired.fired () {
    signal Alarm.fired[active_alarm_id]();
  }

  default async event void Alarm.fired[uint8_t alarmid] () { }


}
