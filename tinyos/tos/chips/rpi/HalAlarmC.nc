
configuration HalAlarmC {
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
  components HalAlarmP;

  HalAlarmP.TimerFired = TimerFired;

  Alarm = HalAlarmP.Alarm;
  TimerQuery = HalAlarmP.TimerQuery;
  Init = HalAlarmP.Init;
}
