/*
* Copyright (c) 2006
*      The President and Fellows of Harvard College.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
* 1. Redistributions of source code must retain the above copyright
*    notice, this list of conditions and the following disclaimer.
* 2. Redistributions in binary form must reproduce the above copyright
*    notice, this list of conditions and the following disclaimer in the
*    documentation and/or other materials provided with the distribution.
* 3. Neither the name of the University nor the names of its contributors
*    may be used to endorse or promote products derived from this software
*    without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
* ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
* FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
* DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
* OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
* LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
* OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
* SUCH DAMAGE.
*/
includes FitsMsg;
configuration Fits {
} implementation {
  components Main, FitsM, TimerC, GenericComm, LedsC;
  
  // 13 Dec 2004 : GWA : FITSTimer now does both MicroTimer and SysTime
  
  // 21 Feb 2005 : GWA : We need CC1000 radio for Mica2, CC2420 for
  //               MicaZ/Telos, plus FitsTimer for Mica2/Micaz/Telos.  Ugh.

#if defined(PLATFORM_MICAZ) || defined(PLATFORM_TELOS)
  components CC2420RadioM as Radio;
  components FITSTimerC;
  components HPLCC2420M;
#elif defined(PLATFORM_MICA2)
  components CC1000RadioIntM as Radio;
  components FITSTimerC;
#elif defined(PLATFORM_PC)
  #if defined(TOSSIMCC2420)
    components CC2420RadioM as Radio;
    components HPLCC2420M;
  #endif
    components SysTimeC as SysTime;
#endif

  components FiringFunctionLog2M as FiringFunctionC;
  components RandomLFSR;
#ifdef FTSPINSTRUMENT
  components TimeSyncC;
#ifdef TIMESYNC_SYSTIME
  components SysTimeStampingC as TimeStampingC;
#else
  components ClockTimeStampingC as TimeStampingC;
#endif
#endif

  // GT: topology conversion from .nss to motelab 
  // components NodeConnectivityM as NodeConnectivityC;

#ifdef USE_NODECON
  components NodeConnectivityM;
#endif

  Main.StdControl -> GenericComm;
#ifndef PLATFORM_PC
  Main.StdControl -> FITSTimerC;
#endif
  Main.StdControl -> FitsM;
#ifdef FTSPINSTRUMENT
  Main.StdControl -> TimeSyncC;
#endif

  FitsM.Leds -> LedsC;
  FitsM.SendFitsMsg -> GenericComm.SendMsg[AM_FITSMSGT];
  FitsM.ReceiveFitsMsg -> GenericComm.ReceiveMsg[AM_FITSMSGT];

#ifdef FTSPINSTRUMENT
  FitsM.SendFitsDiagMsg -> GenericComm.SendMsg[AM_FITSDIAGMSGT];
  FitsM.SendFitsInfoMsg -> GenericComm.SendMsg[AM_FITSINFOMSGT];
  FitsM.SendFitsFiringMsg -> GenericComm.SendMsg[AM_FITSFIRINGMSGT];
#endif

  // 11 Mar 2005 : GWA : Dumped delay packets.

#if !defined(PLATFORM_PC) || defined(TOSSIMCC2420)
  FitsM.RadioSendCoordinator -> Radio.RadioSendCoordinator;
  FitsM.RadioReceiveCoordinator -> Radio.RadioReceiveCoordinator;
#endif
#ifndef PLATFORM_PC
  FitsM.MicroTimer -> FITSTimerC;
  FitsM.SysTime -> FITSTimerC;
#else
  FitsM.SysTime -> SysTime;
  FitsM.FireTimer -> TimerC.Timer[unique("Timer")];
#endif
#if defined(PLATFORM_MICAZ) || defined(PLATFORM_TELOS) || defined(TOSSIMCC2420)
  FitsM.HPLCC2420RAM -> HPLCC2420M;
#endif
  FitsM.ProcessDelayTimer -> TimerC.Timer[unique("Timer")];
  FitsM.SendDelayTimer -> TimerC.Timer[unique("Timer")];
  FitsM.FiringFunction -> FiringFunctionC;
  // GT: topology conversion from .nss to motelab 	
#ifdef USE_NODECON
  FitsM.NodeConnectivity -> NodeConnectivityM;
#endif
  FitsM.Random -> RandomLFSR;
#ifdef FTSPINSTRUMENT
  FitsM.GlobalTime -> TimeSyncC;
  FitsM.TimeStamping -> TimeStampingC;
  FitsM.TimeSyncInfo -> TimeSyncC;
#endif
}
