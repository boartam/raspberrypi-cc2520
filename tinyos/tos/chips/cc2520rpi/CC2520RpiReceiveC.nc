
configuration CC2520RpiReceiveC {
  provides {
    interface BareReceive;
  }
}

implementation {

  components CC2520RpiReceiveP as ReceiveP;
  components CC2520RpiRadioP as RadioP;
  components MainC;
  components IOManagerC;

  MainC.SoftwareInit -> ReceiveP.SoftwareInit;

  ReceiveP.PacketMetadata -> RadioP.PacketMetadata;
  ReceiveP.IO -> IOManagerC[FD_IO_CC2520RECEIVE];

  BareReceive = ReceiveP.BareReceive;

}
