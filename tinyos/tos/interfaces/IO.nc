
interface IO {
  // Add a file descriptor to the select() call
  command error_t registerFD (int file_descriptor);
//  command void registerFD ();

  // Event that is triggered when data is ready on this io file
  event void receiveReady ();
}
