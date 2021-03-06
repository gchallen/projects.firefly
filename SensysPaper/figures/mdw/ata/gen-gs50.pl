#!/usr/bin/perl

#$TTSDIR="../../../../data/sensysData/7-Apr-ATA-TOTAL/gs50_results";
$TTSDIR="data-gs50/";
$OUTFILE="gs50.bars";
@FFLIST=(70,100,500,750,1000);

opendir(DIR, $TTSDIR) || die "can't opendir $TTSDIR: $!";
@files = grep { /^motes-\d+\.txt/ } readdir(DIR);
closedir DIR;

$maxy = 0;
foreach $file (@files) {
  if ($file =~ /motes-(\d+)/) {
    $nummotes = int($1);
  }
  open (FILE, "$TTSDIR/$file") || die "can't open $file\n";
  while (<FILE>) {
    if (/^(\d+)\s+(\S+)\s+(\S+)/) {
      $ff = $1;
      $gs50 = $2 * 1.0e6;
      $gs50_sd = $3 * 1.0e6;
      push @{$timetosync{$ff}}, "$nummotes $gs50";
      push @{$timetosync_stddev{$ff}}, "$nummotes $gs50_sd";

      $inlist = 0;
      foreach $fflist (@FFLIST) {
	if ($fflist == $ff) { $inlist = 1; }
      }
      if ($inlist) {
	if (($gs50+$gs50_sd) > $maxy) { $maxy = ($gs50+$gs50_sd); }
      }
      $nmlist[$nummotes] = $nummotes;
    }
  }
}

open (BARS, ">$OUTFILE") || die "can't open $OUTFILE\n";
print BARS "XAxis: Firing function constant: -labelalign center -labeldist 0.5\n";
print BARS "YAxis: 50th percentile group spread (usec): -labelalign center -labeldist 0.5 -grid -setmax $maxy\n";
print BARS "Key: right-(1.25*inch), top-(0.5*inch): : -keywidth 1 -keytitlealign right -textfont helvetica10 -fillcolor white -keyframe -elemwidth 0.1 -elemheight 0.1\n";
print BARS "Options: -size 8x5 -labeldist 1.0 -textfont helvetica12 -labelfont helvetica12 -ticfont helvetica10 -keyframe 0 -valueangle 90 -valuefont helvetica10 -valuealign left -interpolation line -topmargin 0.2 -bottommargin 1.0 -rightmargin 0.2 -leftmargin 1.0 -plotspacing 5\n";

$xoffset = 0.5;
$inkey = 1;
foreach $ff (sort { $a <=> $b } keys(%timetosync)) {

  $inlist = 0;
  foreach $fflist (@FFLIST) {
    if ($fflist == $ff) { $inlist = 1; }
  }

  if ($inlist) {
    $xoffset += 5;
    print BARS "BeginCluster: FF $ff: -xlabel 0.2\n";

    @set = @{$timetosync{$ff}};
    @curlist = ();
    foreach $val (sort { $a <=> $b } @set) {
      ($nummotes, $tts) = split(' ', $val);
      $curlist[$nummotes] = $tts;
    }

    @set = @{$timetosync_stddev{$ff}};
    @curlist_stddev = ();
    foreach $val (sort { $a <=> $b } @set) {
      ($nummotes, $stddev) = split(' ', $val);
      $curlist_stddev[$nummotes] = $stddev;
    }

    $n = 0;
    foreach $nm (sort { $a <=> $b } @nmlist) {
      if ($nm) {
	if (!$curlist[$nm]) {
	  $curlist[$nm] = 0.0;
	  $curlist_stddev[$nm] = 0.0;
	}
	if ($inkey) {
	  print BARS "  Bar: $curlist[$nm]: $nm nodes: -inkey\n";
	} else {
	  print BARS "  Bar: $curlist[$nm]: $nm nodes:\n";
	}

# Print errorbars. Kind of a hack but it works.
	$v1 = $curlist[$nm] - $curlist_stddev[$nm];
	$v2 = $curlist[$nm] + $curlist_stddev[$nm];
	# Begin GT changes here
	#print BARS "  Line: $xoffset, $v1, $xoffset, $v2:\n";
	$x1 = $xoffset - 0.4;
	$x2 = $xoffset + 0.4;
	#print BARS "  Line: $x1, $v1, $x2, $v1:\n";
	#print BARS "  Line: $x1, $v2, $x2, $v2:\n";

	$n++;
	$xoffset += 1;
      }
    }
    if ($inkey) { $inkey = 0; }
    print BARS "EndCluster\n";
  }
}
