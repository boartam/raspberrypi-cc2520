
generic configuration IOFileC () {
  provides {
    interface IO;
  }
}

implementation {
  enum { FILE_ID = unique("FILEID") };

  components IOManagerC;

  IO = IOManagerC.IO[FILE_ID];
}
