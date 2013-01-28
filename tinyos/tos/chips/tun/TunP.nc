#include <stdio.h>
#include <stdlib.h>
#include <net/if.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <string.h>
#include <linux/if_tun.h>
#include <linux/ioctl.h>
#include <pthread.h>

#include <stdarg.h>

module TunP {
  provides {
    interface Init as SoftwareInit @exactlyonce();
    interface IPForward;
  }
  uses {
    interface IO;
  }
}

implementation {

  int tun_file;
  uint8_t in_buf[2048];
  uint8_t out_buf[2048];

  // todo: add timer and sendDone
  command error_t IPForward.send(struct in6_addr *next_hop,
                                 struct ip6_packet *msg,
                                 void *data) {
    size_t len;
    int ret;

    // skip the frame header
 //   uint8_t* out_buf_start = out_buf + sizeof(struct tun_pi);
    uint8_t* out_buf_start = out_buf;

    printf("TUNP: send\n");

    len = iov_len(msg->ip6_data) + sizeof(struct ip6_hdr);

    // copy the header and body into the frame
    memcpy(out_buf_start, &msg->ip6_hdr, sizeof(struct ip6_hdr));
    iov_read(msg->ip6_data, 0, len, out_buf_start + sizeof(struct ip6_hdr));

    ret = write(tun_file, out_buf, len + sizeof(struct tun_pi));
    if (ret < 0) {
      printf("TUNP: send failed\n");
    }


    return SUCCESS;
  }

  // Runs a command on the local system using
  // the kernel command interpreter.
  int ssystem(const char *fmt, ...) {
    char cmd[128];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(cmd, sizeof(cmd), fmt, ap);
    va_end(ap);
    printf("%s\n", cmd);
    fflush(stdout);
    return system(cmd);
  }

  event void IO.receiveReady () {
    struct ip6_hdr* iph;
    int len;
    uint8_t buf[2048];
    void *payload;

    len = read(tun_file, buf, 2048);
    printf("TunP: got packet\n");

    memcpy(in_buf, buf, len);

    // set up pointers and signal to the next layer
    iph = (struct ip6_hdr*) in_buf;
    payload = (iph + 1);
    signal IPForward.recv(iph, payload, NULL);
  }

  command error_t SoftwareInit.init() {
    struct ifreq ifr;
    int err;

    tun_file = open("/dev/net/tun", O_RDWR);
    if (tun_file < 0) {
      // error
      printf("no net/tun\n");
    }

    // Clear the ifr struct
    memset(&ifr, 0, sizeof(ifr));

    // Select a TUN device
    ifr.ifr_flags = IFF_TUN | IFF_NO_PI;

    // Setup the interface
    err = ioctl(tun_file, TUNSETIFF, (void *) &ifr);
    if (err < 0) {
      printf("bad ioctl\n");
      close(tun_file);
    }

    // Setup the IP Addresses
    // Todo: this should be made nicer somehow (not use ifconfig, be flexible)
    printf("\n");
    ssystem("ifconfig tun0 up");
    ssystem("ifconfig tun0 mtu 1280");
 //   ssystem("ip -6 addr add 2607:f018:800a:bcde:f012:3456:7890:1/112 dev tun0");
    ssystem("ip -6 route add 2607:f018:800a:bcde:f012:3456:7890::/112 dev tun0");
 //   ssystem("ifconfig tun0 inet6 add fe80::212:6d52:5000:1/64");
    // Dummy link local addr to make the dhcp server work
    ssystem("ifconfig tun0 inet6 add fe80::212:aaaa:bbbb:f/64");
    printf("\n");

    // Register the file descriptor with the IO manager that will call select()
    call IO.registerFD(tun_file);

    return SUCCESS;

  }

}

