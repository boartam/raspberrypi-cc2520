
/**
 * HilTimerMilliC provides a parameterized interface to a virtualized
 * millisecond timer.  TimerMilliC in tos/system/ uses this component to
 * allocate new timers.
 */

configuration HilTimerMilliC {
  provides {
    interface Init;
    interface Timer<TMilli> as TimerMilli[ uint8_t num ];
    interface LocalTime<TMilli>;
  }
}

implementation {
  components new AlarmMilli32C();
  components new AlarmToTimerC(TMilli);
  components new VirtualizeTimerC(TMilli,uniqueCount(UQ_TIMER_MILLI));
  components new CounterToLocalTimeC(TMilli);
  components LocalTimeMilli32P;

  Init = AlarmMilli32C.Init;
  TimerMilli = VirtualizeTimerC;
  LocalTime = LocalTimeMilli32P;

  VirtualizeTimerC.TimerFrom -> AlarmToTimerC;
  AlarmToTimerC.Alarm -> AlarmMilli32C.Alarm;

}
