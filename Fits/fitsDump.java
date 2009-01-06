/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

import java.util.*;
import java.io.*;
import java.text.*;
import net.tinyos.message.*;
import net.tinyos.packet.*;

public class fitsDump implements MessageListener {
  
  int[] packMasks;
  public static void main(String[] args) {
    new fitsDump().start(args);
  }
  fitsArray[] dataArray;

  public void start(String[] args) {
    for (int i = 0; i < args.length; i++) {
      PhoenixSource ourPhoenix = 
        BuildSource.makePhoenix(args[i], null);
      MoteIF currentSF = new MoteIF(ourPhoenix, -1);
      currentSF.registerListener(new FitsMsgT(), this);
      currentSF.registerListener(new FitsDiagMsgT(), this);
      currentSF.registerListener(new FitsInfoMsgT(), this);
      currentSF.registerListener(new FitsFiringMsgT(), this);
    }
    dataArray = new fitsArray[16];
    for (int i = 0; i < 16; i++) {
      dataArray[i] = new fitsArray();
      dataArray[i].seqno = 0;
      dataArray[i].receivedTime = 0;
    }
  }
  public void messageReceived(int to, Message m) {
    if (m instanceof FitsMsgT) {
      FitsMsgT currentMsg = (FitsMsgT)m;
      int sourceAddr = currentMsg.get_sourceaddr();
      long receivedTime = currentMsg.get_receivedtime();
      int seqno = currentMsg.get_seqno();
      long sentTime = currentMsg.get_senttime();
      long sentDelay = currentMsg.get_sentdelay();
      System.out.print(sourceAddr + "\t");
      System.out.print(seqno + "\t");
      System.out.print(receivedTime + "\t");
      System.out.print(sentTime + "\t");
      System.out.print(sentDelay + "\t");
      System.out.print("\n");
    } else if (m instanceof FitsDiagMsgT) {
      System.out.print("DIAG\t");
      FitsDiagMsgT currentMsg = (FitsDiagMsgT)m;
      long fireTime = currentMsg.get_firetime();
      int sourceAddr = currentMsg.get_sourceaddr();
      long fireSeqNo = currentMsg.get_fireSeqNo();
      short isSynced = currentMsg.get_synced();
      int rootID = currentMsg.get_rootID();
      System.out.print(sourceAddr + "\t");
      System.out.print(rootID + "\t");
      System.out.print(fireTime + "\t");
      System.out.print(fireSeqNo + "\t");
      System.out.print(isSynced + "\t");
      System.out.print("\n");
    } else if (m instanceof FitsInfoMsgT) {
      FitsInfoMsgT currentMsg = (FitsInfoMsgT)m;
      int myAddr = currentMsg.get_myaddr();
      int sourceAddr = currentMsg.get_sourceaddr();
      int mySeqno = currentMsg.get_myseqno();
      int seqno = currentMsg.get_seqno();
      int queueIndex  = currentMsg.get_queueIndex();
      long arrivalTime = currentMsg.get_arrivalTime();
      long FTSPStamp = currentMsg.get_FTSPStamp();
      short FTSPSynced  = currentMsg.get_FTSPSynced();
      short ignored  = currentMsg.get_ignored();
      //System.out.print("INFO\t");
      //System.out.print(myAddr + "\t");
      //System.out.print(sourceAddr + "\t");
      //System.out.print(mySeqno + "\t");
      //System.out.print(seqno + "\t");
      //System.out.print(queueIndex + "\t");
      //System.out.print(arrivalTime + "\t");
      //System.out.print(ignored + "\t");
      //System.out.print(FTSPStamp + "\t");
      //System.out.print(FTSPSynced + "\t");
      //System.out.print("\n");
    } else if (m instanceof FitsFiringMsgT) {
      FitsFiringMsgT currentMsg = (FitsFiringMsgT)m;
      int sourceAddr = currentMsg.get_sourceaddr();
      long nextInterval = currentMsg.get_nextInterval();
      int seqno = currentMsg.get_seqno();
      //System.out.print("FIRING\t");
      //System.out.print(sourceAddr + "\t");
      //System.out.print(nextInterval + "\t");
      //System.out.print(seqno + "\t");
      //System.out.print("\n");
    }
  }
  public class fitsArray {
    public int seqno;
    public long receivedTime;
  }
}  
