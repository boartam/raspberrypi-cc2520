
configuration TunC {
  provides {
    interface IPForward;
  }
}

implementation {
  components TunP;
  components MainC;
  components IOManagerC;

  TunP.IO -> IOManagerC.IO[FD_IO_TUN];

  MainC.SoftwareInit -> TunP.SoftwareInit;

  IPForward = TunP.IPForward;
}
