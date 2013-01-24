/*
 * Copyright (c) 2010, Vanderbilt University
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Janos Sallai, Miklos Maroti
 * Author: Thomas Schmid (adapted for CC2520)
 * Author: Brad Campbell (adapted for CC2520Rpi)
 */

#ifndef __RADIOCONFIG_H__
#define __RADIOCONFIG_H__

#include <Timer.h>
#include <message.h>

// This is the default value of the PA_POWER field of the TXCTL register.
#ifndef CC2520_DEF_RFPOWER
#define CC2520_DEF_RFPOWER	CC2520_TXPOWER_0DBM
#endif

// This is the default value of the CHANNEL field of the FSCTRL register.
#ifndef CC2520_DEF_CHANNEL
#define CC2520_DEF_CHANNEL	11
#endif

// The number of microseconds a sending mote will wait for an acknowledgement
#ifndef SOFTWAREACK_TIMEOUT
#define SOFTWAREACK_TIMEOUT	2500
#endif

#ifndef LPL_WINDOW
#define LPL_WINDOW 320
#endif

/**
 * Make PACKET_LINK automaticaly enabled for Ieee154MessageC
 */
#if !defined(TFRAMES_ENABLED) && !defined(PACKET_LINK)
#define PACKET_LINK
#endif

#endif

//__RADIOCONFIG_H__
