
generic configuration AlarmMilli32C () {
  provides {
    interface Init;
    interface Alarm<TMilli, uint32_t> as Alarm;
  }
}

implementation {
  enum { ALARM_ID = unique("AlarmMilli") };

  components HalAlarmC;
  Alarm = HalAlarmC.Alarm[ALARM_ID];

  Init = HalAlarmC.Init;

}

