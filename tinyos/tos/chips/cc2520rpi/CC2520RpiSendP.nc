#include <pthread.h>
#include <stdio.h>

#include "CC2520RpiDriver.h"

module CC2520RpiSendP {
  provides {
    interface Init as SoftwareInit @exactlyonce();
    interface BareSend;
  }
  uses {
    interface PacketMetadata;
  }
}

implementation {

  int cc2520_file;
  message_t* msg_pointer;

  task void sendDone_task() {
    signal BareSend.sendDone(msg_pointer, SUCCESS);
  }

#if CC2520RPI_DEBUG
  void print_message (uint8_t* buf, uint8_t len) {
    char pbuf[2048];
    char *buf_ptr = NULL;
    int i;

    buf_ptr = pbuf;
    for (i = 0; i < len; i++) {
      buf_ptr += sprintf(buf_ptr, " 0x%02X", buf[i]);
    }

    *(buf_ptr) = '\0';
    printf("write %i %s\n", len, pbuf);
  }
#endif

  command error_t SoftwareInit.init() {
    int ret;

    // Open the character device for the CC2520
    cc2520_file = open("/dev/radio", O_RDWR);
    if (cc2520_file < 0) {
      fprintf(stderr, "CC2520RpiSendP: Could not open radio\n");
      exit(1);
    }

    return SUCCESS;
  }

  command error_t BareSend.send (message_t* msg) {
    int ret;
    int len;

    len = ((cc2520packet_header_t*) msg->header)->cc2520.length;
    msg_pointer = msg;

#if CC2520RPI_DEBUG
    print_message((uint8_t*) msg, len-1);
#endif

    // call the driver to send the packet
    ret = write(cc2520_file, (uint8_t*) msg, len-1);
    switch (ret) {
      case CC2520_TX_BUSY:
      case CC2520_TX_ACK_TIMEOUT:
      case CC2520_TX_FAILED:
        call PacketMetadata.setWasAcked(msg, FALSE);
        break;
      case CC2520_TX_LENGTH:
#if CC2520RPI_DEBUG
        printf("CC2520RpiSendP: INCORRECT LENGTH\n");
#endif
        break;
      case CC2520_TX_SUCCESS:
        call PacketMetadata.setWasAcked(msg, TRUE);
        break;
      default:
        if (ret == len - 1) {
          call PacketMetadata.setWasAcked(msg, TRUE);
        } else {
#if CC2520RPI_DEBUG
          printf("CC2520RpiSendP: write() weird return code\n");
#endif
        }
        break;
    }

    post sendDone_task();

    return SUCCESS;
  }

  command error_t BareSend.cancel (message_t* msg) {
    return FAIL;
  }
}
