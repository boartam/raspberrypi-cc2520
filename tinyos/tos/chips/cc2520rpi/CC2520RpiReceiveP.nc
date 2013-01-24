#include <stdlib.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <sys/types.h>

#define MAX_PACKET_LEN 128

/* This is the low level receive module that gets packets from the CC2520 kernel
 * module.
 */

module CC2520RpiReceiveP {
  provides {
    interface Init as SoftwareInit @exactlyonce();
    interface BareReceive;
  }
  uses {
    interface PacketMetadata;
    interface IO;
  }
}

implementation {

  int cc2520_pipe;

  message_t* rx_msg_ptr;
  message_t rx_msg_buf;

  int read_pipe[2];

  void print_message (uint8_t* buf, uint8_t len) {
    char pbuf[2048];
    char *buf_ptr = NULL;
    int i;

    buf_ptr = pbuf;
    for (i = 0; i < len; i++) {
      buf_ptr += sprintf(buf_ptr, " 0x%02X", buf[i]);
    }

    *(buf_ptr) = '\0';
    printf("read %i %s\n", len, pbuf);
  }

  event void IO.receiveReady () {
    int ret;
    cc2520_metadata_t* meta;
    ssize_t len;

    printf("Receiving a test message...\n");
    ret = read(cc2520_pipe, &len, sizeof(ssize_t));

    if (ret != sizeof(ssize_t)) {
      printf("CC2520RpiReceiveP: did not receive len from pipe\n");
      return;
    }

    ret = read(cc2520_pipe, rx_msg_ptr, len);

    if (ret > 0) {
      print_message((uint8_t*) rx_msg_ptr, ret);

      // Save the meta information about the packet
      meta = (cc2520_metadata_t*) (uint8_t*) rx_msg_ptr + ret;
      call PacketMetadata.setLqi(rx_msg_ptr, meta->lqi);
      call PacketMetadata.setRssi(rx_msg_ptr, meta->rssi);

      // Signal the rest of the stack on the main thread
      rx_msg_ptr = signal BareReceive.receive(rx_msg_ptr);

    } else {
      printf("CC2520RpiReceiveP: read from pipe failed.\n");
    }
  }

  command error_t SoftwareInit.init () {
    // We pass a buffer back and forth between
    // the upper layers.
    int cc2520_file;
    int ret;

    rx_msg_ptr = &rx_msg_buf;

    cc2520_file = open("/dev/radio", O_RDWR);
    if (cc2520_file < 0) {
      printf("CC2520RpiReceiveP: Could not open radio.\n");
      exit(1);
    }

    // create a pipe to buffer the input
    ret = pipe(read_pipe);
    if (ret == -1) {
      printf("CC2520RpiReceiveP: Could not create pipe.\n");
      exit(1);
    }

    // Create a very simple process that just reads in from the cc2520 driver
    //  and puts the data in the pipe.
    if (!fork()) {
      // CHILD
      char pkt_buf[MAX_PACKET_LEN];
      close(read_pipe[0]);

      while(1) {
        ssize_t len;
        len = read(cc2520_file, pkt_buf, MAX_PACKET_LEN);
        printf("got the d\n");
        if (len <= 0) {
          // Something has died
          printf("CC2520RpiReceiveP: Pipe died.\n");
          close(read_pipe[1]);
        }
        write(read_pipe[1], &len, sizeof(ssize_t));
        write(read_pipe[1], pkt_buf, len);
      }
    }

    // PARENT
    close(read_pipe[1]);
    close(cc2520_file);

    cc2520_pipe = read_pipe[0];

    // Add the cc2520 pipe end to the select call
    call IO.registerFD(cc2520_pipe);

    printf("CC2520RpiReceiveP: registered receiver.\n");

    return SUCCESS;
  }
}
