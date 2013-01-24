
configuration HalAlarmC {
  provides {
    interface Alarm<TMilli, uint32_t> as Alarm[uint8_t alarmid];
    interface TimerQuery;
    interface Init;
  }
}

implementation {
  components HalAlarmP;
  components IOManagerC;

  HalAlarmP.TimerFired -> IOManagerC.TimerFired;

  Alarm = HalAlarmP.Alarm;
  TimerQuery = HalAlarmP.TimerQuery;
  Init = HalAlarmP.Init;
}
