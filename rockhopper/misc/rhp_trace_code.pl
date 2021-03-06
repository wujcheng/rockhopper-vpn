
#
#  Copyright (C) 2009-2010 TETSUHARU HANADA <rhpenguine@gmail.com>
#  All rights reserved.
#
#  You can redistribute and/or modify this software under the
#  LESSER GPL version 2.1.
#  See also LICENSE.txt and LICENSE_LGPL2.1.txt.
#

#
#  Simple script to generate #include files and template files for translating
#  debug trace(from binary format to text format).
#
#  (usage)
#    $/usr/bin/perl rhp_trace_code.pl
#

# (Ubuntu 8.x--) Need to import libxml-libxml-perl by package manager.
use XML::LibXML;

use Switch;




$parser         = XML::LibXML->new;
$cfg_doc        = $parser->parse_file('../web_mng/pub/rhp_event_log.xml');
@event_log_elms = $cfg_doc->getElementsByTagName('event_log');
%oldlogids = ();
%oldlogids2 = ();
$oldlogmaxid = 0;
foreach $event_log_elm (@event_log_elms) {
  
  $tag = $event_log_elm->getAttribute("tag");
  $oldlogids{$tag} = 1;
  $oldlogids2{"RHP_LOG_ID_" . $tag} = 1;
  
  $logid = $event_log_elm->getAttribute("id");
  if( $oldlogmaxid < $logid ){
    $oldlogmaxid = $logid;
  }
}




opendir( SRC_DIR, "./src/" ) || "Can't open ./src/. \n";
@srcfiles = grep( /$\.c$/, readdir(SRC_DIR) );
close(SRC_DIR);

open( TRCID_H, "> ./rhp_main_traceid.h" )
  || "Can't open rhp_main_traceid.h \n";
open( TRCID_STR_H, "> ./rhp_main_traceid_str.h" )
  || "Can't open rhp_main_traceid_str.h. \n";
open( LOGID_H, "> ./logids.h" )
  || "Can't open logids.h \n";
open( LOGID_STR_H, "> ./logids_str.h" )
  || "Can't open logids_str.h \n";

print TRCID_H "/* Auto generated by rhp_trace_code.pl. */\n";
print TRCID_H "#ifndef _RHP_TRACEID_H_\n";
print TRCID_H "#define _RHP_TRACEID_H_\n\n";
print TRCID_H "#define RHPTRCID_BUG\t1\n";
print TRCID_H "#define RHPTRCID_TEXT\t2\n";
print TRCID_H "#define RHPTRCID_LINE\t3\n";
print TRCID_H "#define RHPTRCID_BINDUMP\t4\n";
print TRCID_H "#define RHPTRCID_MEM_DBG_LEAK_PRINT\t5\n";
print TRCID_H "#define RHPTRCID_MEM_DBG_NOT_FREED_ADDRESS\t6\n";
print TRCID_H "#define RHPTRCID_VPN_REF_DBG_PRINT\t7\n";
print TRCID_H "#define RHPTRCID_MEM_DBG_LEAK_PRINT_END\t8\n";

print TRCID_STR_H "/* Auto generated by rhp_trace_code.pl. */\n";
print TRCID_STR_H "#ifndef _RHP_TRACEID_STR_H_\n";
print TRCID_STR_H "#define _RHP_TRACEID_STR_H_\n\n";
print TRCID_STR_H "#define RHPTRCID_BUG" . "_S\t\"1\"\n";
print TRCID_STR_H "#define RHPTRCID_TEXT" . "_S\t\"2\"\n";
print TRCID_STR_H "#define RHPTRCID_LINE" . "_S\t\"3\"\n";
print TRCID_STR_H "#define RHPTRCID_BINDUMP" . "_S\t\"4\"\n";
print TRCID_STR_H "#define RHPTRCID_MEM_DBG_LEAK_PRINT" . "_S\t\"5\"\n";
print TRCID_STR_H "#define RHPTRCID_MEM_DBG_NOT_FREED_ADDRESS" . "_S\t\"6\"\n";
print TRCID_STR_H "#define RHPTRCID_VPN_REF_DBG_PRINT" . "_S\t\"7\"\n";
print TRCID_STR_H "#define RHPTRCID_MEM_DBG_LEAK_PRINT_END" . "_S\t\"8\"\n";



$i = 1000;
$j = $oldlogmaxid + 1;
foreach $file (@srcfiles) {

  open( SRC_FILE,        "./src/$file" )          || "Can't open $file. \n";
  open( SRC_FILE_NO_TRC, "> ./src_no_trc/$file" ) || "Can't open $file. \n";

  while (<SRC_FILE>) {

    if ( /RHP_TRC\(/ || /RHP_TRC_FREQ\(/ ) {

      @elms = split( /,|\);$/, $_ );

      if ( $trcids{ $elms[1] } != 1 ) {
        print TRCID_H "#define $elms[1]\t$i\n";
        print TRCID_STR_H "#define $elms[1]" . "_S\t\"$i\"\n";
        $i++;
        $trcids{ $elms[1] } = 1;

      }

    } elsif ( /RHP_LOG_D\(/
      || /RHP_LOG_DE\(/
      || /RHP_LOG_E\(/
      || /RHP_LOG_I\(/
      || /RHP_LOG_W\(/
      || /RHP_LOG_N\(/ )
    {

      @elms2 = split( /,|\);$/, $_ );

      if( $oldlogids2{$elms2[2]} != 1 ){
  
        if ( $logids{ $elms2[2] } != 1 ) {
          print LOGID_H "#define $elms2[2]\t$j\n";
          print LOGID_STR_H "#define $elms2[2]" . "_S\t\"$j\"\n";
          $j++;
          $logids{ $elms2[2] } = 1;
         }
      }
      
    } else {
      print SRC_FILE_NO_TRC $_;
    }
  }

  close(SRC_FILE_NO_TRC);
  close(SRC_FILE);
}

print TRCID_H "\n#endif // _RHP_TRACEID_H_\n";
print TRCID_STR_H "\n#endif // _RHP_TRACEID_STR_H_\n";

close(TRCID_H);
close(TRCID_STR_H);

@users   = ( "comm", "syspxy", "main", "mainfreq", "syspxyfreq" );
@usersid = ( "1",    "2",      "3",    "6",        "7" );

for ( $hh = 0 ; $hh < @users ; $hh++ ) {

  %trcids = ();

  open( FMT_TMPL, "> ./format_template_$users[$hh].txt" )
    || "Can't open format_template_$users[$hh].txt. \n";

  print FMT_TMPL "#include \"rhp_main_traceid_str.h\"\n\n";
  print FMT_TMPL "<?xml version=\"1.0\"?>\n";
  print FMT_TMPL "<user id=\"$usersid[$hh]\" name=\"$users[$hh]\">\n\n";

  open( MSYM_FILE, "./msym.def" ) || "Can't open msym.def. \n";

  $msym_flag = 0;

  while (<MSYM_FILE>) {

    if ( $msym_flag == 0 && /##MSYM_START##/ ) {

      @elms      = split( /\s+/, $_ );
      $msym_name = $elms[1];
      $msym_flag = 1;

      print FMT_TMPL "<label name=\"" . "$msym_name" . "\">\n";

    } elsif ( $msym_flag && /#define/ ) {

      @elms       = split( /\s+/, $_ );
      $msym_label = $elms[2];
      $msym_ptrn  = $msym_name . "_";
      $msym_label =~ s/RHP_//g;
      $msym_label =~ s/$msym_ptrn//g;
      $msym_value = $elms[3];

      print FMT_TMPL "<label_item value=\""
        . "$msym_value"
        . "\" label=\""
        . $msym_label
        . "\"/>\n";

    } elsif ( $msym_flag && /##MSYM_END##/ ) {
      $msym_flag = 0;
      print FMT_TMPL "</label>\n";
    }
  }

  close(MSYM_FILE);

  open( BSYM_FILE, "./bsym.def" ) || "Can't open bsym.def. \n";

  $bsym_flag = 0;
  $bsym_cnt  = 1;
  while (<BSYM_FILE>) {

    if ( $bsym_flag == 0 && /##BSYM_START##/ ) {

      @elms      = split( /\s+/, $_ );
      $bsym_name = $elms[1];
      $bsym_flag = 1;

      print FMT_TMPL "<bit name=\"" . "$bsym_name" . "\">\n";

    } elsif ( $bsym_flag && /#define/ ) {

      @elms       = split( /\s+/, $_ );
      $bsym_label = $elms[2];
      $bsym_ptrn  = $bsym_name . "_";
      $bsym_label =~ s/RHP_//g;
      $bsym_label =~ s/$bsym_ptrn//g;
      $bsym_value = $elms[3];

      print FMT_TMPL "<bit_item value=\""
        . "$bsym_cnt"
        . "\" label=\""
        . $bsym_label
        . "\"/>\n";
      $bsym_cnt++;

    } elsif ( $bsym_flag && /##BSYM_END##/ ) {
      $bsym_flag = 0;
      print FMT_TMPL "</bit>\n";
    }
  }

  close(BSYM_FILE);

  print FMT_TMPL "<message id=RHPTRCID_BUG_S tag=\"[BUG?]\">\n";
  print FMT_TMPL " %s [%s:%di]\n";
  print FMT_TMPL "</message>\n\n";

  print FMT_TMPL "<message id=RHPTRCID_TEXT_S tag=\"\">\n";
  print FMT_TMPL " %s [%s:%di]\n";
  print FMT_TMPL "</message>\n\n";

  print FMT_TMPL "<message id=RHPTRCID_LINE_S tag=\"\">\n";
  print FMT_TMPL " %s [%s:%di]\n";
  print FMT_TMPL "</message>\n\n";

  print FMT_TMPL "<message id=RHPTRCID_BINDUMP_S tag=\"\">\n";
  print FMT_TMPL " [%s] %p\n";
  print FMT_TMPL "</message>\n\n";

  print FMT_TMPL "<message id=RHPTRCID_MEM_DBG_LEAK_PRINT_S tag=\"MEM_LEAK_PRINT_START\">\n";
  print FMT_TMPL "<![CDATA[";
  print FMT_TMPL "record_pool_num: %di\n";
  print FMT_TMPL "record_newly_alloc: %di\n";
  print FMT_TMPL "alloc_big_record: %di\n";
  print FMT_TMPL "start_time: %di\n";
  print FMT_TMPL "elapsing_time: %di\n";
  print FMT_TMPL "]]>\n";
  print FMT_TMPL "</message>\n\n";

  print FMT_TMPL "<message id=RHPTRCID_MEM_DBG_NOT_FREED_ADDRESS_S tag=\"MEM_NOT_FREED\">\n";
  print FMT_TMPL "<![CDATA[";
  print FMT_TMPL "ADDR:%x, BYTES:%di, FILE:%s:%di, TID:%li, ELAPSING:%di, TIME:%di\n\n";
  print FMT_TMPL "calls:\n"; 
  print FMT_TMPL "[0]: %Y\n";
  print FMT_TMPL "  [1]: %Y\n";
  print FMT_TMPL "    [2]: %Y\n";
  print FMT_TMPL "      [3]: %Y\n";
  print FMT_TMPL "        [4]: %Y\n";
  print FMT_TMPL "          [5]: %Y\n";
  print FMT_TMPL "            [6]: %Y\n";
  print FMT_TMPL "              [7]: %Y\n\n";
  print FMT_TMPL "old_calls(B4 freed):\n";
  print FMT_TMPL "[0]: %Y\n";
  print FMT_TMPL "  [1]: %Y\n";
  print FMT_TMPL "    [2]: %Y\n";
  print FMT_TMPL "      [3]: %Y\n";
  print FMT_TMPL "        [4]: %Y\n";
  print FMT_TMPL "          [5]: %Y\n";
  print FMT_TMPL "            [6]: %Y\n";
  print FMT_TMPL "              [7]: %Y\n\n";
  print FMT_TMPL "buffer:\n%p\n";
  print FMT_TMPL "]]>\n";
  print FMT_TMPL "</message>\n\n";

  print FMT_TMPL "<message id=RHPTRCID_VPN_REF_DBG_PRINT_S tag=\"OBJ_NOT_UNHELD\">\n";
  print FMT_TMPL "<![CDATA[";
  print FMT_TMPL "%s: ref:%x, obj:%x, tid:%li, file:%s:%di, refcnt:%di\n\n";
  print FMT_TMPL " Held in:\n"; 
  print FMT_TMPL " [0]: %Y\n";
  print FMT_TMPL "   [1]: %Y\n";
  print FMT_TMPL "     [2]: %Y\n";
  print FMT_TMPL "       [3]: %Y\n";
  print FMT_TMPL "         [4]: %Y\n";
  print FMT_TMPL "           [5]: %Y\n";
  print FMT_TMPL "             [6]: %Y\n";
  print FMT_TMPL "               [7]: %Y\n\n";
  print FMT_TMPL "]]>\n";
  print FMT_TMPL "</message>\n\n";

  print FMT_TMPL "<message id=RHPTRCID_MEM_DBG_LEAK_PRINT_END_S tag=\"MEM_LEAK_PRINT_END\">\n";
  print FMT_TMPL "<![CDATA[";
  print FMT_TMPL "not_freed_bytes: %qu\n";
  print FMT_TMPL "]]>\n";
  print FMT_TMPL "</message>\n\n";


  foreach $file (@srcfiles) {

    open( SRC_FILE, "./src/$file" ) || "Can't open $file. \n";

    $line_num = 0;
    while (<SRC_FILE>) {

      $line_num++;

      if ( /RHP_TRC\(/ || /RHP_TRC_FREQ\(/ ) {

        @elms = split( /,|\);$/, $_ );

        if ( $trcids{ $elms[1] } != 1 ) {

          $n = @elms;
          $n -= 3;

          $elmtag = $elms[1];
          $elmtag =~ s/RHPTRCID_//g;
          $elmtag =~ tr/[A-Z]/[a-z]/;

          print FMT_TMPL "<message id=$elms[1]_S tag=\"$elmtag\">\n";
          print FMT_TMPL '<![CDATA[';

          @fmt_work = split( /\"/, $elms[2] );
          $fmt      = $fmt_work[1];
          $j        = 1;

          $msym_flag = 0;
          $msym      = "";

          for ( $i = 0 ; $i < length($fmt) ; $i++ ) {

            $fc = substr( $fmt, $i, 1 );
            $ac = $elms[ ( $j + 2 ) ];
            $ac =~ s/\);\s*//g;

            if ( $fc eq 'b' ) {

              if ($msym_flag) {
                print FMT_TMPL "$ac: %bm[$msym]  ";
              } else {
                print FMT_TMPL "$ac: %bi  ";
              }

            } elsif ( $fc eq 'w' ) {

              if ($msym_flag) {
                print FMT_TMPL "$ac: %wm[$msym]  ";
              } else {
                print FMT_TMPL "$ac: %wi  ";
              }

            } elsif ( $fc eq 'd' ) {

              if ($msym_flag) {
                print FMT_TMPL "$ac: %dm[$msym]  ";
              } else {
                print FMT_TMPL "$ac: %di  ";
              }

            } elsif ( $fc eq 'j' ) {

              if ($msym_flag) {
                print FMT_TMPL "$ac: %dm[$msym]  ";
              } else {
                print FMT_TMPL "$ac: %du  ";
              }

            } elsif ( $fc eq 'f' ) {

              if ($msym_flag) {
                print FMT_TMPL "$ac: %lm[$msym]  ";
              } else {
                print FMT_TMPL "$ac: %li  ";
              }

            } elsif ( $fc eq 'F' ) {

              if ($msym_flag) {
                print FMT_TMPL "$ac: %lm[$msym]  ";
              } else {
                print FMT_TMPL "$ac: %lu  ";
              }

            } elsif ( $fc eq 'k' ) {

              print FMT_TMPL "$ac: %dx  ";

            } elsif ( $fc eq 'x' ) {

#              print FMT_TMPL "$ac: %dx  ";
              print FMT_TMPL "$ac: %x  ";

            } elsif ( $fc eq 'u' ) {

              if ($msym_flag) {
#                print FMT_TMPL "$ac: %dm[$msym]  ";
                print FMT_TMPL "$ac: %m[$msym]  ";
              } else {
#                print FMT_TMPL "$ac: %du  ";
                print FMT_TMPL "$ac: %u  ";
              }

            } elsif ( $fc eq 'q' ) {

              if ($msym_flag) {
                print FMT_TMPL "$ac: %qm[$msym]  ";
              } else {
                print FMT_TMPL "$ac: %qu  ";
              }

            } elsif ( $fc eq 'W' ) {

              if ($msym_flag) {
                print FMT_TMPL "$ac: %wm[$msym]  ";
              } else {
                print FMT_TMPL "$ac: %wu  ";
              }

            } elsif ( $fc eq 'D' ) {

              if ($msym_flag) {
                print FMT_TMPL "$ac: %dm[$msym]  ";
              } else {
                print FMT_TMPL "$ac: %di  ";
              }

            } elsif ( $fc eq 'J' ) {

              if ($msym_flag) {
                print FMT_TMPL "$ac: %dm[$msym]  ";
              } else {
                print FMT_TMPL "$ac: %du  ";
              }

            } elsif ( $fc eq 'K' ) {

              print FMT_TMPL "$ac: %dx  ";

            } elsif ( $fc eq 'X' ) {

#              print FMT_TMPL "$ac: %dx  ";
              print FMT_TMPL "$ac: %x  ";

            } elsif ( $fc eq 'U' ) {

              if ($msym_flag) {
#                print FMT_TMPL "$ac: %dm[$msym]  ";
                print FMT_TMPL "$ac: %m[$msym]  ";
              } else {
#                print FMT_TMPL "$ac: %du  ";
                print FMT_TMPL "$ac: %u  ";
              }

            } elsif ( $fc eq 'Q' ) {

              if ($msym_flag) {
                print FMT_TMPL "$ac: %qm[$msym]  ";
              } else {
                print FMT_TMPL "$ac: %qu  ";
              }

            } elsif ( $fc eq 'B' ) {

              $ac2 = $elms[ ( $j + 3 ) ];
              $ac2 =~ s/\);\s*//g;

              if ( $ac eq '1' ) {
                $bit_len_ac = "b";
              } elsif ( $ac eq '2' ) {
                $bit_len_ac = "w";
              } elsif ( $ac eq '3' ) {
                $bit_len_ac = "w";
              } elsif ( $ac eq '4' ) {
                $bit_len_ac = "d";
              } elsif ( $ac eq '5' ) {
                $bit_len_ac = "d";
              } elsif ( $ac eq '6' ) {
                $bit_len_ac = "d";
              } elsif ( $ac eq '7' ) {
                $bit_len_ac = "d";
              } elsif ( $ac eq '8' ) {
                $bit_len_ac = "q";
              } else {
                $bit_len_ac = "q";
              }

              if ($msym_flag) {
                print FMT_TMPL "$ac2: " . '%' . "$bit_len_ac" . "B[$msym]  ";
              } else {
                print FMT_TMPL "$ac2: " . '%' . "$bit_len_ac" . "B[UNKNOWN]  ";
              }

              $j++;
              $n--;

            } elsif ( $fc eq 'Y' ) {

              print FMT_TMPL "$ac: %Y  ";

            } elsif ( $fc eq '4' ) {

              print FMT_TMPL "$ac: %4  ";

            } elsif ( $fc eq '6' ) {

              print FMT_TMPL "$ac: %6  ";

            } elsif ( $fc eq 'M' ) {

              print FMT_TMPL "$ac: %M  ";

            } elsif ( $fc eq 'G' ) {

              print FMT_TMPL "$ac: %G  ";

            } elsif ( $fc eq 'H' ) {

              print FMT_TMPL "$ac: %H  ";

            } elsif ( $fc eq 'E' ) {

              print FMT_TMPL "$ac: %E  ";

            } elsif ( $fc eq 's' ) {

              print FMT_TMPL "$ac: %s  ";

            } elsif ( $fc eq 'L' ) {

              $msym_flag = 1;
              $msym      = $ac;
              $msym =~ s/^\"*//;
              $msym =~ s/\"*$//;

            } elsif ( $fc eq 'p' ) {

              $ac2 = $elms[ ( $j + 3 ) ];
              $ac2 =~ s/\);\s*//g;
              print FMT_TMPL "$ac2" . '[LEN: ' . "$ac]: %p  ";
              $j++;
              $n--;

            } elsif ( $fc eq 'a' ) {

              $ac2 = $elms[ ( $j + 3 ) ];
              $ac2 =~ s/\);\s*//g;
              $ac3 = $elms[ ( $j + 4 ) ];
              $ac3 =~ s/\);\s*//g;
              $ac4 = $elms[ ( $j + 5 ) ];
              $ac4 =~ s/\);\s*//g;
              $ac5 = $elms[ ( $j + 6 ) ];
              $ac5 =~ s/\);\s*//g;

              $ac2 =~ s/^RHP_TRC_FMT_A_*//;

              print FMT_TMPL "$ac5" 
                . '[LEN: '
                . "$ac ][PROTO: $ac2 ][IV_LEN: " . "$ac3"
                . '][ICV_LEN: ' . "$ac4"
                . "] %a  ";

              $j++;
              $n--;
              $j++;
              $n--;
              $j++;
              $n--;
              $j++;
              $n--;

            } elsif ( $fc eq 't' ) {

              print FMT_TMPL "$ac: %t  ";

            } elsif ( $fc eq 'T' ) {

              print FMT_TMPL "$ac: %T  ";

            } else {

              if ( $fc != '\0' ) {
                print "!!!!!!UNKNOWN FORMAT CHAR [$ac : $fc]!!!!!!\n";
              }
            }

            if ( $fc ne 'L' ) {
              $msym_flag = 0;
            }

            $j++;
            $n--;
          }

          print FMT_TMPL "\n[$file:$line_num]";
          print FMT_TMPL ']]>';
          print FMT_TMPL "\n</message>\n\n";

          $trcids{ $elms[1] } = 1;
        }
      }
    }

    close(SRC_FILE);
  }

  print FMT_TMPL "</user>\n";
  close(FMT_TMPL);
}




%logids = ();

open( FMT_TMPL, "> ./format_template_log.txt" )
  || "Can't open format_template_log.txt. \n";

print FMT_TMPL "#include \"logids_str.h\"\n\n";
print FMT_TMPL "<?xml version=\"1.0\"?>\n";
print FMT_TMPL "<log_template>\n\n";

open( MSYM_FILE, "./msym.def" ) || "Can't open msym.def. \n";

$msym_flag = 0;

while (<MSYM_FILE>) {

  if ( $msym_flag == 0 && /##MSYM_START##/ ) {

    @elms      = split( /\s+/, $_ );
    $msym_name = $elms[1];
    $msym_flag = 1;

    print FMT_TMPL "<label tag=\"" . "$msym_name" . "\">\n";

  } elsif ( $msym_flag && /#define/ ) {

    @elms       = split( /\s+/, $_ );
    $msym_label = $elms[2];
    $msym_ptrn  = $msym_name . "_";
    $msym_label =~ s/RHP_//g;
    $msym_label =~ s/$msym_ptrn//g;
    $msym_value = $elms[3];

    print FMT_TMPL "  <label_item value=\""
      . "$msym_value"
      . "\" label=\""
      . $msym_label
      . "\"/>\n";

  } elsif ( $msym_flag && /##MSYM_END##/ ) {
    $msym_flag = 0;
    print FMT_TMPL "</label>\n";
  }
}

close(MSYM_FILE);

foreach $file (@srcfiles) {

  open( SRC_FILE, "./src/$file" ) || "Can't open $file. \n";

  while (<SRC_FILE>) {

    if ( /RHP_LOG_D\(/
      || /RHP_LOG_DE\(/
      || /RHP_LOG_E\(/
      || /RHP_LOG_I\(/
      || /RHP_LOG_W\(/
      || /RHP_LOG_N\(/ )
    {

      @elms = split( /,|\);$/, $_ );

      if ( $logids{ $elms[2] } != 1 ) {

        $n = @elms;
        $n -= 3;

        $elmtag = $elms[2];
        $elmtag =~ s/RHP_LOG_ID_//g;
        
        if( $oldlogids{$elmtag} != 1 ){

          print FMT_TMPL "<event_log id=$elms[2]_S tag=\"$elmtag\">\n";
          print FMT_TMPL '  <![CDATA[<label style="font-weight:bold;"></label>';
  
          @fmt_work = split( /\"/, $elms[3] );
          $fmt      = $fmt_work[1];
          $j        = 1;
          $h        = 0;
  
          for ( $i = 0 ; $i < length($fmt) ; $i++ ) {
            
            $fc = substr( $fmt, $i, 1 );
            $ac = $elms[ ( $j + 3 ) ];
            $ac =~ s/\);\s*//g;
            
            if( $fc eq 'L' || $fc eq 'p' || $fc eq 'a' ){

              $j++;
              $n--;

              $ac = $elms[ ( $j + 3 ) ];
              $ac =~ s/\);\s*//g;
            }
                
            print FMT_TMPL "$ac: #ARG$h# ";
            $h++;
            $j++;
            $n--;
          }
  
          print FMT_TMPL ']]>';
          print FMT_TMPL "\n</event_log>\n\n";
        
          $logids{ $elms[2] } = 1;
         }
      }
    }
  }
  close(SRC_FILE);
}

print FMT_TMPL "</log_template>\n";
close(FMT_TMPL);

