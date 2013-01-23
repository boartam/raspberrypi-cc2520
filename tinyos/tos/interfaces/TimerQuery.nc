
interface TimerQuery {
  // Get the number of microseconds until the next timer should fire.
  command uint32_t nextTimerTime ();
}
