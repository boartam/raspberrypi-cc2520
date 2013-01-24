#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#define MAX_NUM_FD 10

#define DEFUALT_WAIT_MICRO 10000

module IOManagerP {
  provides {
    interface IO[uint8_t io_id];
    interface BlockingIO;
    interface TimerFired;
    interface Init;
  }
  uses {
    interface TimerQuery;
  }
}

implementation {

  typedef struct {
    uint8_t id;
    uint8_t fd;
  } id_fd_map_t;

  id_fd_map_t map[MAX_NUM_FD];
  uint8_t num_fd = 0;
  uint8_t nfds = 0;

  fd_set rfds;

  command error_t Init.init () {
    FD_ZERO(&rfds);
    return SUCCESS;
  }

  command error_t IO.registerFD[uint8_t io_id] (int file_descriptor) {
    if (num_fd >= MAX_NUM_FD) {
      return FAIL;
    }

    map[num_fd].id = io_id;
    map[num_fd].fd = file_descriptor;
    num_fd++;

 //   FD_SET(file_descriptor, &rfds);

    if (file_descriptor >= nfds) {
      nfds = file_descriptor + 1;
    }
    return SUCCESS;
  }

  command void BlockingIO.waitForIO () {
    int ret;
    uint32_t timer_micro;
    struct timeval timeout;
    int i;

    // setup the timeout as the time until the next timer fires
    timer_micro = call TimerQuery.nextTimerTime();
    if (timer_micro == 0) {
      timer_micro = DEFUALT_WAIT_MICRO;
    }

    timeout.tv_sec = timer_micro / 1000000;
    timeout.tv_usec = timer_micro - (timeout.tv_sec*1000000);

    FD_ZERO(&rfds);
    for (i=0; i<num_fd; i++) {
      FD_SET(map[i].fd, &rfds);
    }

    ret = select(nfds, &rfds, NULL, NULL, &timeout);

    if (ret < 0) {
      // error
    } else if (ret == 0) {
      // timeout signal timer
      signal TimerFired.fired();
    } else {
      // some file is ready
      int j;
      for (j=0; j<num_fd; j++) {
        if (FD_ISSET(map[j].fd, &rfds)) {
          signal IO.receiveReady[map[j].id]();
        }
      }
    }
  }

  default event void IO.receiveReady[uint8_t io_id] () { }


}
