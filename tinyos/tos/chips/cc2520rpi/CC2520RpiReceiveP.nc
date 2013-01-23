#include <stdlib.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <stdio.h>

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

  int cc2520_file;

  message_t* rx_msg_ptr;
  message_t rx_msg_buf;

  void print_message (uint8_t *buf, uint8_t len) {
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
    cc2520_metadata_t* meta;

    printf("Receiving a test message...\n");
    ret = read(cc2520_file, rx_msg_ptr, 128);

    if (ret > 0) {
      print_message(buf, ret);

      // Save the meta information about the packet
      meta = (cc2520_metadata_t*) (uint8_t*) rx_msg_ptr + ret;
      call PacketMetadata.setLqi(rx_msg_ptr, meta->lqi);
      call PacketMetadata.setRssi(rx_msg_ptr, meta->rssi);

      // Signal the rest of the stack on the main thread
      rx_msg_ptr = signal BareReceive.receive(rx_msg_ptr);

    }
  }

  command error_t SoftwareInit.init () {
    // We pass a buffer back and forth between
    // the upper layers.
    rx_msg_ptr = &rx_msg_buf;

    cc2520_file = open("/dev/radio", O_RDWR);
    if (cc2520_file < 0) {
      printf("CC2520RpiReceiveP: Could not open radio.\n");
      exit(1);
    }

    call IO.register(cc2520_file);

    return SUCCESS;
  }
}
