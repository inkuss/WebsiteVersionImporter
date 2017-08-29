#!/usr//bin/perl -w

#########################################################################
#
# Eine Sammlung von Subroutinen von Ingolf Kuss - allgemeiner Kram
#
# Copyright by hbz-NRW
# August 2017
# v. 1
#
#########################################################################

use strict;
use File::Path;
use File::Basename;
require Exporter;

#******************************************************************************
package ks_media_allg;
#******************************************************************************
use File::Basename;
use File::Find;
our @ISA = qw( Exporter );
our @EXPORT = qw( $FCT_RC_OK
  $FCT_RC_SUCCESS
  $FCT_RC_INFO
  $FCT_RC_WARN
  $FCT_RC_ERROR
  $FCT_RC_NOTOK
  anfweg
  anz_running_jobs
  cgianfang
  check_datei
  chgumlaute
  chgxmlentities
  chk_utf8
  clean_text
  clean_text_optionalencode
  csv_datei_einlesen
  csv_datei_neuanlage
  csv_datei_teilmenge_bilden
  dateianf
  dateiende
  dateiname
  decode2
  decode4
  dir_slash
  dprintfsu
  encode2
  encode4
  ersetze_verunstaltete_sonderz_datei
  ersetze_verunstaltete_sonderz_verzeichnis
  fuehrende_null
  get_env
  hbz_streamname
  hbz_streamname_pkn
  hbz_dateiname_pkn_safe
  hbz_parentname_pkn
  hbzMediaBasename
  hbzMediaPathname
  httrack_note
  isdefined
  isempty
  iso8601
  iconv
  iconv_datei
  load_file
  printfsu
  reconvert_xmlentities
  rmkdir
  sprintfsu
  terminate_on_err
  time_string
  umlaute_xmlentities
  undir_slash
  uri_escape_utf8
  urlencode_punycode
  verzeichnisse
  verzeichnispfad
  winbasename
  writehtml2ocr
  writehtml2ocr2
  xmlentities
  zeit
  );
my $script = basename( $0 );
our $VERSION = 1.1;
my $filecount = 0;

# Returncodes; zu verknuepfen mit BITWEISEM UND (= einfaches Kaufmannsund)
our $FCT_RC_OK = 255; # alles erfolgreich gelaufen; keine Meldungen
our $FCT_RC_SUCCESS = 127; # alles erfolgreich gelaufen; Erfolgsmeldungen
our $FCT_RC_INFO = 63; # alles nach Plan gelaufen; Meldungen
our $FCT_RC_WARN = 15; # Warnungen
our $FCT_RC_NOTOK = our $FCT_RC_ERROR = 0; # fehlgeschlagen

# Protokollierungsebenen fuer Messages
our %prot_levels = ( DEBUG   =>  0
                   , SUCCESS =>  1
                   , SUCC    =>  1
                   , INFO    =>  2
                   , WARN    =>  5
                   , WARNING =>  5
                   , ERROR   => 10
                   , ERR     => 10
                   , DEFAULT =>  5
                   );

# minimale Protokollierungsebene (globaler Parameter)
# alle Nachrichten mit einer hoeheren Ebene werden ausgegeben
#  0 = alle Nachrichten ausgeben
#  1 = Nachrichten mit Protokollierungsebene 1 oder hoeher ausgeben
# 10 = nur Nachrichten mit Protokollierungsebene 10 ausgeben
# our $prot_level_min = 5;
our $prot_level_min = 1;

# Subroutinen

sub anfweg {
	
# Diese Subroutine entfernt, wenn vorhanden, Anführungszeichen am Anfang
# und am Ende eines übergebenen Strings.
# Übergeben wird ein String.
# Zurückgegeben wird ein String, bei dem evtl. Anführungszeichen am Anfang
# und Ende entfernt wurden.
	
  my $string = shift;
  $string =~ s/^\"//;
  $string =~ s/\"$//;
  return $string;
  }

sub anz_running_jobs {
  # Ermittelt die Anzahl gerade laufender Jobs von csh-Skripts
  # anhand eines Suchmusters fuer den Jobnamen
  my $ps_searchpattern  = shift; # z.B. Scriptname, oder ein Teil davon
  my $logverz = shift;
#
  # print "ps_searchpattern=$ps_searchpattern\n";
  # my $patternbasename = hbzMediaBasename( $ps_searchpattern );
  my $patternbasename = $script;
  # print "basename(ps_searchpattern)=$patternbasename\n";
  my $processlist = "${logverz}${patternbasename}.run.$$";
  my $anz_jobs = 0;
  my $cmd = "ps -eaf | grep $ps_searchpattern >> $processlist";
  my $system_retval = system $cmd;
  # print "system retval = $system_retval\n";
  if( $system_retval >= 0 ) {
    if( ! open PROC, "<$processlist" ) {
      print "WARN: Kann nicht Prozessliste $processlist oeffnen!($!)";
      return $anz_jobs;
      }
    while (<PROC>) {
      if( $_ =~ /grep/ ) { next; }
      if( $_ =~ /vim / ) { next; }
      if( $_ =~ /vi / ) { next; }
      if( $_ =~ /tail / ) { next; }
      if( $_ =~ /more / ) { next; }
      if( $_ =~ /csh/ ) { next; }
      if( $_ =~ /perl/ ) { $anz_jobs++; }
      }
    close PROC;
    }
  if( ! unlink $processlist ) {
    print "WARN: Kann nicht Datei $processlist loeschen! ($!)";
    }
  # print "anz_jobs: $anz_jobs\n";
  return $anz_jobs;
  }

sub cgianfang {
	print "Content-type:text/html\n\n";
}

sub check_datei {

	# Diese Subroutine prüft, ob eine Datei existiert. 
	# Übergeben wird ein Dateipfad
	# Wenn die Datei existiert, wird eine 0 zurückgegeben
	# Wenn nicht, wird eine 1 zurückgegeben
	
		my $datei = shift;
		my $return = 0;
		unless( -e $datei ) {
			print "$datei existiert nicht. Bitte ueberpruefen!\n";
			$return = 1;
		}
		return $return;
}

sub dateianf {
	
	# Diese Subroutine ermittelt den Dateinamen vor der Dateiendung.
	# Ein Pfad mit einer Datei am Ende wird übergeben
	# Der Dateiname ohne Dateiendung wird zurückgegeben
	
		my $pfad = shift;
		my $datname = &dateiname( $pfad );
		$datname =~ s/^(.*)\.[^\.]*$/$1/;
		return $datname;
}

sub dateiende {
	
	# Diese Subroutine ermittelt die Dateiendung eines Dateinamens
	# Ein Pfad mit einer Datei am Ende wird übergeben
	# Die Dateiendung wird zurückgegeben.
	
		my $pfad = shift;
		my $datname = &dateiname( $pfad );
		$datname =~ s/^.*\.([^\.]*)$/$1/;
		return $datname;
}

sub dateiname {
	
	# Diese Subroutine ermittelt den Dateinamen am Ende eines Pfads
	# Ein Pfad wird übergeben
	# Der Dateiname plus Dateiendung wird zurückgegeben
	# funktioniert nur auf Unix-Pfaden
	
		my $pfad = shift;
		my @pfadteile = split /\//, $pfad;
		@pfadteile = reverse( @pfadteile );
		return $pfadteile[0];
}

sub decode2 {
  # kodierten Wert (1 Byte, 0...255) dekodieren => Wertebereich 0,...,68160
  # dekodierter Wert liegt zwischen 
  # decoded (Wert eingeschlossen) und decoded + genauigkeit (Wert ausgeschlossen)
  my $coded = shift;
  my $genauigkeit = shift; # passed by ref
#
  ${$genauigkeit} = 1;
  if( ! ( $coded & 240 ) ) { return $coded; }
  ${$genauigkeit} = 2;
  if( ! ( $coded & 1 ) ) { return $coded; }
  if( $coded == 255 ) {
    ${$genauigkeit} = -1;
    return 68160;
    }
  my $decoded = 0;
  my $actbitval = 256;
  my $highest = 69120;
  ${$genauigkeit} = 8640;
  for( my $n=7; $n>=4; $n-- ) {
    $actbitval /= 2;
    my $nexthighest = $highest;
    my $faktor = 2**($n-4)+1;
    $highest /= $faktor;
    my $secondary = $nexthighest - $highest;
    ${$genauigkeit} /= $faktor;
    if( $coded & $actbitval ) {
      # hoechstes Bit gefunden
      $decoded += $highest;
      # nachfolgende Bits auswerten
      for( my $m=$n-1; $m>=1; $m-- ) {
        $actbitval /= 2;
        $secondary /= 2;
        if( $coded & $actbitval ) {
          # nachfolgendes Bit ist gesetzt
          $decoded += $secondary;
          }
        } # next m
      last;
      }
    } # next n
  return $decoded;
}

sub decode4 {
  # im 4er-System kodierten Wert (0...255) dekodieren
  # dekodierter Wert liegt zw. decoded u. decoded + genauigkeit -1
  # maximaler Wert (fuer decoded + genauigkeit) = 4**8
  my $coded = shift;
  my $genauigkeit = shift; # passed by ref
#
  my $decoded = 0;
  ${$genauigkeit} = 1;
  my $actbitval = 256;
  my $highest = 65536;
  for( my $n=7; $n>=0; $n-- ) {
    $actbitval /= 2;
    $highest /= 4;
    if( $coded & $actbitval ) {
      # hoechstes Bit gefunden
      $decoded += $highest;
      ${$genauigkeit} = 3*$actbitval;
      # nachfolgende Bits auswerten
      my $secondary = 3*$highest;
      for( my $m=$n-1; $m>=0; $m-- ) {
        $actbitval /= 2;
        $secondary /= 2;
        if( $coded & $actbitval ) {
          # nachfolgendes Bit ist gesetzt
          $decoded += $secondary;
          }
        } # next m
      last;
      }
    } # next n
  return $decoded;
}

sub dir_slash {
	my $dir = shift;
	unless( $dir =~ /\/$/ ) {
		$dir = $dir . "/";
	}
	return $dir;
}

sub undir_slash {
	my $dir = shift;
	$dir =~ s/[\/\\]*$//;
	return $dir;
}

sub encode2 {
  # Zahl zw. 0 und 68160 auf den Zielbereich 0,...,255 (1 Byte) kodieren "encode 2 Byte auf Eines".
  # Die relative Genauigkeit ist immer mindestens 12,5 % (=1/8).
  #
  # * Die Zahlen von 0 bis 15 werden wie sie sind abgespeichert, absolute Genauigkeit ist 1.
  # * Die Zahlen von 16 bis 255 werden wie sie sind, aber ohne Bit 0, gespeichert. Absolute
  #   Genauigkeit ist 2 (=Wert des niedrigesten, signifikanten Bits).
  # * Zahlen ab 256 werden in den Bits 7 bis 1 kodiert, wobei Bit 0 (als Flag) gesetzt ist.
  #   Der Werte des hoechsten gesetzten Bits sind
  #   n =    7    6    5    4
  #       7680 1536  512  256
  #   i.Abh. vom hoechsten gesetzten Bit haben die nachfolgenden Bits unterschiedliche Bedeutungen.
  #   Ihre Werte halbieren sich jedoch jeweils mit fallender Bitzahl.
  #   Die absolute Genauigkeit ist der Wert von Bit 1.
  #
  # Im Byte wird die untere Grenze abgespeichert
  # obere Grenze = untere Grenze + absolute Genauigkeit
  # Die untere Grenze ist ein-, die obere ausgeschlossen, also wird
  # ein nach unten geschlossenes, nach oben offenes Intervall [a,b[ o.ae., gespeichert
  # erdacht und geschrieben von Ingolf Kuss, 31.08.2012
  my $rest = shift;
#
  $rest = int($rest); # abrunden
  if( $rest < 16 ) { return $rest; }
  if( $rest < 256 ) { return $rest & 254 ; }
  my $retval = 1; # Bit 0 gesetzt als Flag
  my $actbitval = 16;
  my $highest = 256;
  for( my $n=4; $n<=7; $n++ ) {
    my $nexthighest = $highest*(2**($n-4)+1);
    if( $rest < $nexthighest ) {
      # hoechstes Bit setzen
      $retval |= $actbitval;
      $rest -= $highest;
      # nachfolgende Bits setzen
      my $secondary = $nexthighest - $highest;
      for( my $m=$n-1; $m>=1; $m-- ) {
        $actbitval /= 2;
        $secondary /= 2;
        if( $rest >= $secondary ) {
          $retval |= $actbitval;
          $rest -= $secondary;
        }
      } # next m
      return $retval;
    }
    $actbitval *= 2;
    $highest = $nexthighest;
  } # next n
  return 255;
} # end of sub encode2

sub encode4 {
  # Zahl im "4er-System" kodieren
  # Ausgangsbereich: 0,1,...,65152 ; Zielbereich: 0,...,255 (1 Byte)
  # Genauigkeit ist bei niedrigen Zahlen klein:
  #  die kleinsten moeglichen Werte (mit Genauigkeiten) sind:
  #  0, "zw. 1 u. 4 (d.h. >=1, aber < 4)", "zw. 4 u. 10", "zw. 10 u. 16", "zw. 16 u. 28", ...
  # Verbesserung: => encode2
  #
  # hoechstes Bit hat den Wert 4^n, n=0,...,7
  # sekundaere Bits (=Bits unterhalb des hoechsten Bits) haben die Werte 3*2^(n+m), m=n-1,n-2,...,0
  # => kann Zahlen von 0 bis 65152 in einem Byte abbilden, absolute Genauigkeit ist 3*2^n
  #    im Byte wird die untere Grenze abgespeichert
  #    obere Grenze = untere Grenze + absolute Genauigkeit
  # Die untere Grenze ist ein-, die obere ausgeschlossen, also
  # ein nach unten geschlossenes, nach oben offenes Intervall [a,b[ o.ae.
  my $rest = shift;
#
  my $retval = 0;
  my $actbitval = 256;
  my $highest = 65536;
  for( my $n=7; $n>=0; $n-- ) {
    $actbitval /= 2;
    $highest /= 4;
    if( $rest >= $highest ) {
      # hoechstes Bit setzen
      $retval |= $actbitval;
      $rest -= $highest;
      # nachfolgende Bits setzen
      my $secondary = 3*$highest;
      for( my $m=$n-1; $m>=0; $m-- ) {
        $actbitval /= 2;
        $secondary /= 2;
        if( $rest >= $secondary ) {
          $retval |= $actbitval;
          $rest -= $secondary;
        }
      }
      last;
    }
  }
  return $retval;
}

sub ersetze_verunstaltete_sonderz_datei {
  ###############################################################################
  # Verunstaltete Sonderzeichen nach UTF-8 umwandeln
  # siehe http://www.recherche-redaktion.de/tutorium/sonderz_kauderw.htm
  # Autor       | Datum      | Grund
  # Ingolf Kuss | 26.11.2011 | Neuanlage
  ###############################################################################
  use File::Copy;
  my $Textdatei = shift;
  my $overwrite = shift;
  my $log       = shift;
  my $msg_level = shift;

  my %rethash=();
  @{$rethash{"messages"}} = ();
  my $message = "";
  $rethash{"retcode"} = $FCT_RC_OK;

  my $fct_name = "ersetze_verunstaltete_sonderz_datei";

  if( ! -f $Textdatei ) {
    $message = message->new("WARN", __FILE__, __PACKAGE__, __LINE__,
        sprintf( "(%s) ist keine regulaere Datei! FCT_NAME=%s Sonderzeichen werden nicht ersetzt.", $Textdatei, $fct_name ) );
    $message->print( $log, $msg_level );
    $rethash{"retcode"} = $ks_media_allg::FCT_RC_NOTOK;
    return %rethash;
  }

  # $message = message->new("INFO", __FILE__, __PACKAGE__, __LINE__,
  #     sprintf( "Konv. %s", $Textdatei ) );
  # $message->print( $log, $msg_level );
  if( ! open DATEI, "<$Textdatei" ) {
    $message = message->new("FEHLER", __FILE__, __PACKAGE__, __LINE__,
        sprintfsu( "Kann Textdatei %s nicht zum Lesen &ouml;ffnen! Sonderzeichen in Textdatei werden nicht ersetzt.", $Textdatei ) );
    $message->print( $log, $msg_level );
    $rethash{"retcode"} = $ks_media_allg::FCT_RC_NOTOK;
    return %rethash;
  }
  my $tmpdatei = $Textdatei . "." . $$;
  if( ! open TMP, ">$tmpdatei" ) {
    $message = message->new("FEHLER", __FILE__, __PACKAGE__, __LINE__,
        sprintfsu( "Kann tempor&auml;re Datei %s nicht anlegen! Sonderzeichen in Textdatei %s werden nicht ersetzt.", $tmpdatei, $Textdatei ) );
    $message->print( $log, $msg_level );
    $rethash{"retcode"} = $ks_media_allg::FCT_RC_NOTOK;
    return %rethash;
  }
  my $lineno = 0;
  while( <DATEI> ) {
    my $zeile = $_;
    $lineno++;
    chomp( $zeile );
    if( length($zeile) > 8192 ) {
      # lange Zeile fuehren zu Abbruechen bei chk oder ersetze !
      # $message = message->new("INFO", __FILE__, __PACKAGE__, __LINE__,
      #     sprintf( "ZeileNr %d in Datei %s ist zu lang (%d Zeichen). CP1252-Sonderzeichen werden nicht ersetzt.", $lineno, $Textdatei, length($zeile) ) );
      # $message->print( $log, $msg_level );
      printf TMP "%s\n", $zeile;
      next;
      }
    if ( ! chk_utf8( $zeile, $log ) ) {
      # Zeile enthaelt nicht-UTF-8-Zeichen; Konversion nach UTF-8 nur dann
      printf TMP "%s\n", ersetze_verunstaltete_sonderzeichen_zeile( $zeile );
      }
    else {
      printf TMP "%s\n", $zeile;
      }
    }
  close TMP;
  close DATEI;
  if( ! $overwrite ) {
    move( $Textdatei, $Textdatei . ".orig" );
  } else {
    unlink( $Textdatei );
  }
  move( $tmpdatei, $Textdatei );

  push @{$rethash{"messages"}}, 
    new message("SUCCESS", __FILE__, __PACKAGE__, __LINE__,
      sprintf( "Verunstaltete Sonderzeichen in Datei $Textdatei wurden erfolgreich ersetzt." ) );
  return %rethash;

  # ********************* #
  # Lokales Unterprogramm #
  # ********************* #
  sub ersetze_verunstaltete_sonderzeichen_zeile {
    # CP1252 ("ANSI") => UTF-8
    my $chgstr = shift;

    # deutsche + franzoesische Diakritika + weiteres
    $chgstr =~ s/\xC3/\xC3\x83/g; # grosses A mit Tilde
    $chgstr =~ s/\xC2/\xC3\x82/g; # &Acirc;
    $chgstr =~ s/\xA0/\xC2\xA0/g; # no-break space
    $chgstr =~ s/\xA1/\xC2\xA1/g; # umgekehrtes Ausrufezeichen
    $chgstr =~ s/\xA2/\xC2\xA2/g; # Cent Zeichen
    $chgstr =~ s/\xA3/\xC2\xA3/g; # Pfund Zeichen
    $chgstr =~ s/\xA4/\xC2\xA4/g; # Waehrungssymbol
    $chgstr =~ s/\xA5/\xC2\xA5/g; # Yen Zeichen
    $chgstr =~ s/\xA6/\xC2\xA6/g; # durchbrochene Pipe
    $chgstr =~ s/\xA7/\xC2\xA7/g; # §
    $chgstr =~ s/\xA8/\xC2\xA8/g; # Diarese
    $chgstr =~ s/\xA9/\xC2\xA9/g; # Copyright Zeichen
    $chgstr =~ s/\xAA/\xC2\xAA/g; # hochgestelltes a
    $chgstr =~ s/\xAB/\xC2\xAB/g; # linke, doppelte Winkel
    $chgstr =~ s/\xAC/\xC2\xAC/g; # "nicht"-Zeichen
    $chgstr =~ s/\xAD/\xC2\xAD/g; # soft hyphen
    $chgstr =~ s/\xAE/\xC2\xAE/g; # "registered" Zeichen
    $chgstr =~ s/\xAF/\xC2\xAF/g; # Macron
    $chgstr =~ s/\xB0/\xC2\xB0/g; # Grad Zeichen
    $chgstr =~ s/\xB1/\xC2\xB1/g; # Plusminus
    $chgstr =~ s/\xB2/\xC2\xB2/g; # ²
    $chgstr =~ s/\xB3/\xC2\xB3/g; # ³
    $chgstr =~ s/\xB4/\xC2\xB4/g; # accent acute
    $chgstr =~ s/\xB5/\xC2\xB5/g; # µ
    $chgstr =~ s/\xB6/\xC2\xB6/g; # Pilcrow
    $chgstr =~ s/\xB7/\xC2\xB7/g; # mittiger Punkt
    $chgstr =~ s/\xB8/\xC2\xB8/g; # Cedille
    $chgstr =~ s/\xB9/\xC2\xB9/g; # hochgestellte 1
    $chgstr =~ s/\xBA/\xC2\xBA/g; # hochgestelltes o
    $chgstr =~ s/\xBB/\xC2\xBB/g; # rechte, doppelte Winkel
    $chgstr =~ s/\xBC/\xC2\xBC/g; # 1/4
    $chgstr =~ s/\xBD/\xC2\xBD/g; # 1/2
    $chgstr =~ s/\xBE/\xC2\xBE/g; # 3/4
    $chgstr =~ s/\xBF/\xC2\xBF/g; # umgedrehtes Fragezeichen
    $chgstr =~ s/\xC0/\xC3\x80/g; # grosses A grave
    $chgstr =~ s/\xC1/\xC3\x81/g;
    $chgstr =~ s/\xC4/\xC3\x84/g; # &Auml;
    $chgstr =~ s/\xC5/\xC3\x85/g;
    $chgstr =~ s/\xC6/\xC3\x86/g; # &AElig;
    $chgstr =~ s/\xC7/\xC3\x87/g; # &Ccedil;
    $chgstr =~ s/\xC8/\xC3\x88/g; # &Egrave;
    $chgstr =~ s/\xC9/\xC3\x89/g; # &Eacute;
    $chgstr =~ s/\xCA/\xC3\x8A/g; # &Ecirc;
    $chgstr =~ s/\xCB/\xC3\x8B/g; # &Euml;
    $chgstr =~ s/\xCC/\xC3\x8C/g;
    $chgstr =~ s/\xCD/\xC3\x8D/g;
    $chgstr =~ s/\xCE/\xC3\x8E/g; # &Icirc;
    $chgstr =~ s/\xCF/\xC3\x8F/g; # &Iuml;
    $chgstr =~ s/\xD0/\xC3\x90/g;
    $chgstr =~ s/\xD1/\xC3\x91/g;
    $chgstr =~ s/\xD2/\xC3\x92/g;
    $chgstr =~ s/\xD3/\xC3\x93/g;
    $chgstr =~ s/\xD4/\xC3\x94/g; # &Ocirc;
    $chgstr =~ s/\xD5/\xC3\x95/g;
    $chgstr =~ s/\xD6/\xC3\x96/g; # &Ouml;
    $chgstr =~ s/\xD7/\xC3\x97/g;
    $chgstr =~ s/\xD8/\xC3\x98/g;
    $chgstr =~ s/\xD9/\xC3\x99/g; # &Ugrave;
    $chgstr =~ s/\xDA/\xC3\x9A/g;
    $chgstr =~ s/\xDB/\xC3\x9B/g; # &Ucirc;
    $chgstr =~ s/\xDC/\xC3\x9C/g; # &Uuml;
    $chgstr =~ s/\xDD/\xC3\x9D/g;
    $chgstr =~ s/\xDE/\xC3\x9E/g;
    $chgstr =~ s/\xDF/\xC3\x9F/g; # &szlig;
    $chgstr =~ s/\xE0/\xC3\xA0/g; # &agrave;
    $chgstr =~ s/\xE1/\xC3\xA1/g;
    $chgstr =~ s/\xE2/\xC3\xA2/g; # &acirc;
    $chgstr =~ s/\xE3/\xC3\xA3/g;
    $chgstr =~ s/\xE4/\xC3\xA4/g; # &auml;
    $chgstr =~ s/\xE5/\xC3\xA5/g;
    $chgstr =~ s/\xE6/\xC3\xA6/g; # &aelig;
    $chgstr =~ s/\xE7/\xC3\xA7/g; # &ccedil;
    $chgstr =~ s/\xE8/\xC3\xA8/g; # &egrave;
    $chgstr =~ s/\xE9/\xC3\xA9/g; # &eacute;
    $chgstr =~ s/\xEA/\xC3\xAA/g; # &ecirc;
    $chgstr =~ s/\xEB/\xC3\xAB/g; # &euml;
    $chgstr =~ s/\xEC/\xC3\xAC/g;
    $chgstr =~ s/\xED/\xC3\xAD/g;
    $chgstr =~ s/\xEE/\xC3\xAE/g; # &icirc;
    $chgstr =~ s/\xEF/\xC3\xAF/g; # &iuml;
    $chgstr =~ s/\xF0/\xC3\xB0/g;
    $chgstr =~ s/\xF1/\xC3\xB1/g;
    $chgstr =~ s/\xF2/\xC3\xB2/g;
    $chgstr =~ s/\xF3/\xC3\xB3/g;
    $chgstr =~ s/\xF4/\xC3\xB4/g; # &ocirc;
    $chgstr =~ s/\xF5/\xC3\xB5/g;
    $chgstr =~ s/\xF6/\xC3\xB6/g; # &ouml;
    $chgstr =~ s/\xF7/\xC3\xB7/g;
    $chgstr =~ s/\xF8/\xC3\xB8/g;
    $chgstr =~ s/\xF9/\xC3\xB9/g; # &ugrave;
    $chgstr =~ s/\xFA/\xC3\xBA/g;
    $chgstr =~ s/\xFB/\xC3\xBB/g; # &ucirc;
    $chgstr =~ s/\xFC/\xC3\xBC/g; # &uuml;
    $chgstr =~ s/\xFD/\xC3\xBD/g;
    $chgstr =~ s/\xFE/\xC3\xBE/g;
    $chgstr =~ s/\xFF/\xC3\xBF/g;
    $chgstr =~ s/\x152&OElig;/OE/g; # &OElig;
    $chgstr =~ s/\x152&oelig;/oe/g; # &oelig;
  
    return $chgstr;
  }
} # end of sub "ersetze_verunstaltete_sonderz_datei"

sub ersetze_verunstaltete_sonderz_verzeichnis {
  my $workverz  = shift;
  my $log       = shift;
  my $msg_level = shift;

  my %rethash=();
  @{$rethash{"messages"}} = ();
  my $message = "";
  $rethash{"retcode"} = $FCT_RC_OK;

  unless( chdir "$workverz" ) {
    $message = message->new( "ERROR", __FILE__, __PACKAGE__, __LINE__,
      sprintf( "Kann nicht nach Verzeichnis %s wechseln ($!)!", $workverz ) );
    $message->print( $log, $msg_level );
    $rethash{"retcode"} = $ks_media_allg::FCT_RC_NOTOK;
    return %rethash;
  }

  $filecount = 0;
  find(\&filecount, $workverz);
  $message = message->new( "INFO", __FILE__, __PACKAGE__, __LINE__,
    sprintf( "Dateien in und unterhalb %s wurden gezaehlt. Anzahl=%d", $workverz, $filecount ) );
  $message->print( $log, $msg_level );

  my @alle_dateien = glob "*";
  my $dateien_zaehler = 0;
  my $percentage = 0;
  foreach( @alle_dateien ) {
    my $datei = $workverz."/".$_;

    if( -d $datei ) {
      ersetze_verunstaltete_sonderz_unterverz( $datei, $filecount, \$dateien_zaehler, $log, $msg_level);
      } else {

      $dateien_zaehler++;
      if ( $dateien_zaehler % 100 == 0 ) {
        $percentage = $dateien_zaehler / $filecount * 100;
        $message = message->new( "INFO", __FILE__, __PACKAGE__, __LINE__,
          "($dateien_zaehler) Dateien bearbeitet; ($percentage ) % " );
        $message->print( $log, $msg_level );
        }

      if( $datei =~ m/\.html$/i or $datei =~ m/\.htm$/i or $datei =~ m/\.xhtml$/i or $datei =~ m/\.xhtm$/i or $datei =~ m/\.xml$/i ) {
        ersetze_verunstaltete_sonderz_datei( $datei, 1, $log, $msg_level );
        }

      }
    }

  $message = message->new("SUCCESS", __FILE__, __PACKAGE__, __LINE__,
      sprintf( "Verunstaltete Sonderzeichen in Verzeichnis $workverz wurden erfolgreich ersetzt." ) );
  $message->print( $log, $msg_level );
  return %rethash;

} # end of sub "ersetze_verunstaltete_sonderz_verzeichnis"
sub filecount {
  my $filename = $File::Find::name;
  if ( ! -f $filename ) { return; }
  $filecount++;
}

sub ersetze_verunstaltete_sonderz_unterverz {
  my $workverz  = shift;
  my $filecount = shift; # Anzahl insgesamt, nicht nur in diesem Verz.
  my $dateien_zaehler = shift; # passed by reference
  my $log       = shift;
  my $msg_level = shift;

  my %rethash=();
  @{$rethash{"messages"}} = ();
  my $message = "";
  $rethash{"retcode"} = $FCT_RC_OK;

  unless( chdir "$workverz" ) {
    $message = message->new( "ERROR", __FILE__, __PACKAGE__, __LINE__,
      sprintf( "Kann nicht nach Verzeichnis %s wechseln ($!)!", $workverz ) );
    $message->print( $log, $msg_level );
    $rethash{"retcode"} = $ks_media_allg::FCT_RC_NOTOK;
    return %rethash;
  }

  my @alle_dateien = glob "*";
  my $percentage = 0;
  foreach( @alle_dateien ) {
    my $datei = $workverz."/".$_;

    if( -d $datei ) {
      # rekursiver Aufruf
      ersetze_verunstaltete_sonderz_unterverz( $datei, $filecount, $dateien_zaehler, $log, $msg_level);
      } else {

      ${$dateien_zaehler}++;
      if ( ${$dateien_zaehler} % 100 == 0 ) {
        $percentage = ${$dateien_zaehler} / $filecount * 100;
        my $akt_dateien_zaehler = ${$dateien_zaehler};
        $message = message->new( "INFO", __FILE__, __PACKAGE__, __LINE__,
          "($akt_dateien_zaehler) Dateien bearbeitet; ($percentage ) % " );
        $message->print( $log, $msg_level );
        }

      if( $datei =~ m/\.html$/i or $datei =~ m/\.htm$/i or $datei =~ m/\.xhtml$/i or $datei =~ m/\.xhtm$/i or $datei =~ m/\.xml$/i ) {
        ersetze_verunstaltete_sonderz_datei( $datei, 1, $log, $msg_level );
        }

      }
    }

  return %rethash;

} # end of sub "ersetze_verunstaltete_sonderz_unterverz"

sub fuehrende_null {
	
	# Diese Subroutine hängt eine führende Null an eine übergebene Zahl an
		
		my $zahl = $_[0];
		if( $zahl =~ /^\d$/ ) { $zahl = 0 . $zahl; }
		return $zahl;
}

sub get_env {
  # Holt eine Variable aus den Umgebungsvariablen oder als Konstante (oder beides gemischt)
  my $name = shift;
  my $log  = shift;
  my $msg_level = shift;
  my $msg_style = shift;
#
  my $message;
  my $stdausgabe = "";
  my $ausgabe = "";
  if( isempty($log) ) { $log = *STDOUT; }
  
  if( $name eq "edoweb_version" ) { $ausgabe = "edoweb"; }
  elsif( $name eq "logverz" ) { $ausgabe = "/hbz/log/"; }
  elsif( $name eq "tmpverz" ) {
    $ausgabe = $ENV{"TMPDIR"};
    if( $ausgabe !~ /\/$/ ) { $ausgabe .= "/"; }
    }
  elsif( $name eq "machine_ip" ) {
    $ausgabe = $ENV{"DELIV_SYS_HOST"};
    if( ks_media_allg::isempty($ausgabe) ) {
      $ausgabe = $ENV{"dam_delivery_system"};
      my $startpos = index($ausgabe,"http://");
      if( $startpos < 0 ) {
        $message = message->new( "ERROR", __FILE__, __PACKAGE__, __LINE__,
          "Umgebungsvariable \"dam_delivery_system\" beginnt nicht mit \"http://\" ! ",
          procedere => "Programmvariable \"\$$name\" wird nicht belegt !" );
        $message->print( $log, $msg_level, $msg_style );
        return $stdausgabe;
        }
      $ausgabe = substr($ausgabe,7);
      if( ($startpos = index($ausgabe,":")) > 0 ) { $ausgabe=substr($ausgabe,0,$startpos); }
      if( ($startpos = index($ausgabe,"/")) > 0 ) { $ausgabe=substr($ausgabe,0,$startpos); }
      }
    }
  elsif( $name eq "machine_name" ) {
    $ausgabe = get_env("machine_ip", $log, $msg_level, $msg_style);
    my $startpos = index($ausgabe,"\.");
    if( $startpos > 0 ) { $ausgabe = substr($ausgabe,0,$startpos); }
    }
  elsif( $name eq "machine_port" ) {
    $ausgabe = $ENV{"HTTPD_PORT"};
    if( ks_media_allg::isempty($ausgabe) ) {
      $ausgabe = "8881";
      }
    }
  elsif( $name eq "admin_unit_edoweb" ) { $ausgabe = "RLB01"; }
  elsif( $name eq "admin_unit_zbmed" )  { $ausgabe = "DZM01"; }
  elsif( $name eq "admin_unit_verlagsdaten" ) { $ausgabe = "SCA01"; }
  elsif( $name eq "htdocs" ) { $ausgabe = sprintf("%s/htdocs/%s/", $ENV{"httpd_root"}, get_env( "edoweb_version", $log, $msg_level, $msg_style ) ); }
  elsif( $name eq "listnew" ) { $ausgabe = $ENV{"httpd_root"} . "/htdocs/edoweb/urllistendir/listsnew/list"; }
  elsif( $name eq "cgi_verzeichnis" ) { $ausgabe = sprintf("%s/cgi-bin/%s", $ENV{"httpd_root"}, get_env( "edoweb_version", $log, $msg_level, $msg_style ) ); }
  elsif( $name eq "exl_jbin_verz" ) {
    $ausgabe = $ENV{"jdtlh_bin"};
    if( $ausgabe !~ /\/$/ ) { $ausgabe .= "/"; }
    }
  elsif( $name eq "ora_aleph" ) {
    $ausgabe = $ENV{"ALEPH_HOST"};
    $ausgabe .= ".aleph0.dedicated";
    if( $ENV{"ALEPH_HOST"} eq "vc2-t1" ) { $ausgabe = "vc2-t1.aleph3.dedicated"; }
    if( $ENV{"ALEPH_HOST"} eq "triton" ) { $ausgabe = "vc2-t1.aleph3.dedicated"; }
    if( $ENV{"ALEPH_HOST"} eq "pelops" ) { $ausgabe = "vc2-t1.aleph3.dedicated"; } # wieso steht noch pelops drin ?
    }
  elsif( $name eq "accessmid_alle" ) { $ausgabe = "2276897"; }
  elsif( $name eq "accessmid_Bearbeiter" ) { $ausgabe = "2220856"; }
  elsif( $name eq "accessmid_Campus" ) { $ausgabe = "2276896"; }
  elsif( $name eq "accessmid_eingeschraenkt" ) { $ausgabe = "2276896"; }
  elsif( $name eq "accessmid_offen" ) { $ausgabe = "2276897"; }
  elsif( $name eq "accessmid_2276896" ) { $ausgabe = "Campus"; }
  elsif( $name eq "accessmid_2276897" ) { $ausgabe = "alle"; }
  elsif( $name eq "accessmid_2220856" ) { $ausgabe = "Bearbeiter"; }
  elsif( $name eq "loadverz_verlagsdaten" ) {
    $ausgabe = $ENV{"jdtlh_profile"};
    $ausgabe .= "/units/SCA01/load/";
    }
  elsif( $name eq "Iconverz" ) { $ausgabe = "/edoweb/Icons/"; }
  elsif( $name eq "adminunit_edoweb" ) { $ausgabe = "rlb01_"; }
  elsif( $name eq "rep_user" ) { $ausgabe = "creator:creator"; }
  elsif( $name eq "pdftotext_pfad" ) {
    $ausgabe = $ENV{"dtl_product"};
    $ausgabe .= "/bin/pdftotext";
    }
  elsif( $name eq "iconv_pfad" ) { $ausgabe = "/bin/iconv"; }
  elsif( $name eq "imgheight" ) { $ausgabe = "16px"; }
  elsif( $name eq "data_pkn_verz" ) {
    my $produktivsystem = $ENV{"PROD_SYSTEM"};
    if( $produktivsystem eq "Y" ) { $ausgabe = "/data/pkn/"; }
    else { $ausgabe = "/data/pkn_test/"; }
    }
  elsif( $name eq "url_konkordanz" ) { $ausgabe = "/hbz/proc/kuss/edoweb/urlkonkordanz.csv"; }
  elsif( $name eq "url_hist" ) { $ausgabe = "/hbz/proc/kuss/edoweb/url_hist.csv"; }
  elsif( $name eq "ejournals_status" ) { $ausgabe = "/hbz/proc/kuss/edoweb/ejournals_status.csv"; }
  elsif( $name eq "doigenerator_home" ) { $ausgabe = "/hbz/proc/kuss/ellinet/"; }
  elsif( $name eq "urngenerator_home" ) { $ausgabe = "/hbz/proc/kuss/urngenerator/"; }
  elsif( $name eq "gathererlog" ) { $ausgabe = "/hbz/log/ks.media_edoweb_gatherer.log"; }
  else {
    # Einlesen aus Konfigurationsdatei
    my $environment = "/hbz/proc/environment.csv";
    if( ! open ENVIR, "<$environment" ) {
      $message = message->new( "WARN", __FILE__, __PACKAGE__, __LINE__,
        "Kann Umgebungsvariablen, Datei $environment, nicht einlesen ($!)!" );
      $message->print( $log, $msg_level, $msg_style );
    }
    else {
      while(<ENVIR>) {
        if( $_ =~ m/^#/ ) { next; }
        chomp $_;
        my @zeilenteile = split /\=/, $_;
        if( $name eq $zeilenteile[0] ) {
          $ausgabe = $zeilenteile[1];
          last;
        }
      }
      close ENVIR;
    }
  }

  if ( $ausgabe ) { return $ausgabe; }
  else {
    $message = message->new( "WARN", __FILE__, __PACKAGE__, __LINE__,
     "Programmvariable \"\$$name\" wird nicht belegt (kein Wert/Regel hinterlegt in get_env()) !" );
    $message->print( $log, $msg_level, $msg_style );
    return $stdausgabe;
    }

  } # End of Sub "get_env"

sub isdefined {
  # prüft, ob eine Variable nicht leer ist
  my $var = shift;
#
  if( isempty( $var ) ) { return undef; }
  return 1;
  }

sub isempty {
  # prüft, ob eine Variable undefiniert oder leer ist
  # (= Definition einer leeren Variablen !)
  my $var = shift;
#
  if( ! $var ) { return 1; }
  if( $var eq " " ) { return 1; }
  return undef;
  }

sub iso8601 {
	
	# nimmt einen Zeitstempel und wandelt ihn in ein ISO-Datum (YYYY-MM-DD) um
	# Siehe auch: time_string und zeit
	# gibt ISO-Datum zurück
	
	my $date = $_[0];
	
	my ($sek, $min, $stu, $tag, $mon, $jahr, $wt, $tij, $is ) = localtime $date;
	$jahr += 1900;
	$mon ++;
	$mon = fuehrende_null( $mon );
	$tag = fuehrende_null( $tag );
	
	my $isodate = "$jahr-$mon-$tag";
	#print "++++isodate ist $isodate\n";
	return $isodate;
}

sub iconv {
  # ---------------------------------------------------------------------------
  # führt die Konvertierung von CodePage 1252 nach UTF-8 durch
  # ---------------------------------------------------------------------------
  # 27.09.2007 Neuerstellung
  # 16.11.2007 erster poduktiver Lauf auf klio
  # 29.07.2008 Skript von Helmut ersetzt durch Perl-Routine
  # ---------------------------------------------------------------------------
  my $lieferverz = shift;
  my $log = shift;
  my $msg_level = shift;
#
  my $message;
  # Annahme: alle Dateien wurden in dasselbe Verzeichnis heruntergeladen
  if( ! -d $lieferverz ) {
    $message = message->new( "ERROR", __FILE__, __PACKAGE__, __LINE__
      , "Lieferverzeichnis $lieferverz existiert nicht !!!" );
    $message->print( $log, $msg_level );
    exit 0;
    }
  if( ! chdir( $lieferverz ) ) {
    $message = message->new( "ERROR", __FILE__, __PACKAGE__, __LINE__
      , "Kann nicht ins Verzeichnis $lieferverz wechseln ($!)!" );
    $message->print( $log, $msg_level );
    exit 0;
    }

  $message = message->new( "INFO", __FILE__, __PACKAGE__, __LINE__
    , "Executing ICONV on *.ocr files in $lieferverz" );
  $message->print( $log, $msg_level );

  my @textdateien = glob "*.ocr";
  foreach my $datei ( @textdateien ) {
    iconv_datei( $datei, $log, $msg_level);
    } # naechste Datei

  $message = message->new( "SUCCESS", __FILE__, __PACKAGE__, __LINE__
    , "Subroutine iconv regulaer beendet." );
  $message->print( $log, $msg_level );
  } # ENDE der Subroutine "iconv"

sub iconv_datei {
  # Konvertierung einer einzelnen .ocr-Datei von CP1252 nach UTF-8
  # NEU KS20151102
  my $datei = shift;
  my $modus = shift; # 1 = do conversion; 0 = do nothing
  my $log = shift;
  my $msg_level = shift;
#
  use File::Copy;
  my $message;
  my $txtdatei = $datei;
  if( $txtdatei !~ m/\.ocr$/ ) {
    $message = new message("WARN", __FILE__, __PACKAGE__, __LINE__,
      sprintfsu("iconv_datei: zu konvertierende Datei (%s) endet nicht auf .ocr !",$txtdatei) );
    $message->print( $log, $msg_level );
    }
  $txtdatei =~ s/\.ocr$/.txt/;
  if( ! $modus ) {
    # keine Umwandlung, aber kopieren
    # $message = message->new( "INFO", __FILE__, __PACKAGE__, __LINE__
    #   , "Keine Umwandlung der Zeichensatzkodierung, Kopiere Datei $datei nach $txtdatei." );
    # $message->print( $log, $msg_level );
    copy( $datei, $txtdatei ) or die "Kann nicht kopieren $datei nach $txtdatei !($!)";
    return;
    }
  # Ersetze 0d->0a (Loesche entstehende 0a0a...) und konvertiere cp1252 -> utf-8
  my $iconvbefehl = "tr -s '\r' '\n' < \"$datei\" | iconv -f CP1252 -t utf-8 > \"$txtdatei\"";
  my $system_retval = system $iconvbefehl;
  if ( $system_retval != 0 ) {
    $message = new message("WARN", __FILE__, __PACKAGE__, __LINE__,
      "Fehler beim ICONV der OCR-Datei $datei !" );
    $message->print( $log, $msg_level );
    }
  if( ! open TMPICONV, ">>/hbz/tmp/heh.iconv.out" ) {
    $message = message->new( "WARN", __FILE__, __PACKAGE__, __LINE__
      , "Kann nicht an  Datei /hbz/tmp/heh.iconv.out anhaengen ($!)!" );
    $message->print( $log, $msg_level );
    return;
    }
  print TMPICONV "$datei\n";
  close TMPICONV;
  }

sub load_file {
        use File::Copy; # fuer move-Funktion
	my $file = shift;
        if( -f "$file" ) {
          my $fname = shift;
          move( $file, $fname );
        }
}

sub dprintfsu {
  # printf for string, allowing for undefined strings
  # erwartet Dateihandle als erstes Argument
  my $dateihandle = shift;
  my $formatstr = shift;
  my @args      = @_;
#
  print $dateihandle sprintfsu( $formatstr, @args );
  }

sub printfsu {
  # printf for string, allowing for undefined strings
  my $formatstr = shift;
  my @args      = @_;
#
  return dprintfsu( *STDOUT, $formatstr, @args );
  }

sub sprintfsu {
  # sprintf for string, allowing for undefined strings
  my $formatstr = shift;
  my @args      = @_;
#
  my $arg;
  while( index($formatstr, "%s") > -1 ) {
    $arg = shift @args;
    if( $arg ) { $formatstr =~ s/%s/$arg/; }
    else { $formatstr =~ s/%s//; }
    }
  return $formatstr;
  }

sub time_string {

	# Diese Subroutine übernimmt einen Zeitstempel und gibt einen String wie folgt zurück:
	# YYYY-MM-DDTHH:MM:SS
	# Siehe auch sub zeit, iso8601
	
	my $zeitstempel = shift;
	my @time = localtime $zeitstempel;
	my $jahr = $time[5] + 1900;
	my $monat = &fuehrende_null( $time[4] + 1 );
	my $tag = &fuehrende_null( $time[3] );
	my $stunde = &fuehrende_null( $time[2] );
	my $min = &fuehrende_null( $time[1] );
	my $sek = &fuehrende_null( $time[0] );
	my $timestring = "$jahr-$monat-${tag}T$stunde:$min:$sek";
	return $timestring;
	print "<p>Timestring ist $timestring</p>";
}

sub xmlentities {
	
	# Diese Subroutine ändert die Zeichen ", ', &, <, > in die entsprechenden xml-entities
	# Übergeben wird ein String
	# der geänderte String wird zurückgegeben
	my $string = shift;
        if( isempty($string) ) { return " "; }
	$string =~ s/\&/&amp;/g;
	$string =~ s/\"/&quot;/g;
	$string =~ s/\</&lt;/g;
	$string =~ s/\>/&gt;/g;
	$string =~ s/\'/&apos;/g;
	return $string;
}

sub chgxmlentities {
	
	# Diese Subroutine ändert die Zeichen ", ', &, <, > in neutrale Texte
        # zur Verwendung z.B. in Dateinamen
	# Übergeben wird ein String
	# der geänderte String wird zurückgegeben
	my $string = shift;
        if( isempty($string) ) { return " "; }
	$string =~ s/\&/und/g;
	$string =~ s/\"/zitat/g;
	$string =~ s/\</kleiner_als/g;
	$string =~ s/\>/groesser_als/g;
	$string =~ s/\'/Apostroph/g;
	return $string;
}


sub reconvert_xmlentities {
  # Diese Subroutine konvertiert die XML-Entitaeten 
  # &amp; &quot; &lt; &gt; &apos;
  # wieder zurück.
  # Übergeben wird eine Zeichenkette,
  # die geänderte Zeichenkette wird zurückgegeben.
  # Modi:
  #   0 (default) : das Kaufmannsund &amp; wird als erstes konvertiert;
  #                 dadurch wird z.B. &amp;lt; vollstaendig ersetzt:
  #                 &amp;lt; -> &lt; -> <
  #   1           : das Kaufmannsund &amp; wird als letztes konvertiert
  #                 und nur als Bestandteil von zusammengesetzten Entitaeten.
  #                 Dadurch werden digitale Entitaeten, bei denen
  #                 das Kaufmannsund durch &amp; ersetzt wurde, 
  #                 nicht vollstaendig ersetzt, z.B.:
  #                 &amp;lt; -> &lt;
  #                 Das kann sinnvoll sein, wenn der String z.B. anschlie�end
  #                 mit einem DOM-Parser geparst werden soll.
  #                 Der Parser interpretiert dann solche digitalen Entitaeten
  #                 nicht als Beginn eines XML-Elements. Auf diese Weise
  #                 koennen solche Entitaeten als Sonderzeichen in einer 
  #                 Textpassage verwendet werden:
  #                 Z.B. "<<Die>> Emil Helfferich-Sammlung",
  #                 kodiert als "&amp;lt;&amp;lt;Die>> Emil Helfferich-Sammlung" .
  my $string = shift;
  my $modus  = shift;
#
  if( isempty($string) ) { return " "; }
  if( ! $modus ) { $modus = 0; }
  if( $modus == 0 ) { $string =~ s/\&amp;/\&/g; }
  $string =~ s/\&quot;/\"/g;
  $string =~ s/\&lt;/\</g;
  $string =~ s/\&gt;/\>/g;
  $string =~ s/\&apos;/\'/g;
  if( $modus == 1 ) {
   $string =~ s/\&amp;quot;/\&quot;/g;
   $string =~ s/\&amp;lt;/\&lt;/g;
   $string =~ s/\&amp;gt;/\&gt;/g;
   $string =~ s/\&amp;apos;/\&apos;/g;
   }
  return $string;
  }

sub chgumlaute {
  # Diese Subroutine ersetzt Umlaute in einem String
  # der geänderte String wird zurückgegeben
  my $string = shift;
  if( isempty($string) ) { return " "; }
  $string =~ s/�/ae/g;
  $string =~ s/�/oe/g;
  $string =~ s/�/ue/g;
  $string =~ s/�/Ae/g;
  $string =~ s/�/Oe/g;
  $string =~ s/�/Ue/g;
  $string =~ s/�/ss/g;
  $string =~ s/ä/ae/g;
  $string =~ s/ö/oe/g;
  $string =~ s/ü/ue/g;
  $string =~ s/Ä/Ae/g;
  $string =~ s/Ö/Oe/g;
  $string =~ s/Ü/Ue/g;
  $string =~ s/ß/ss/g;
  return $string;
  }

sub umlaute_xmlentities {
  # Diese Subroutine ersetzt Umlaute in einem String in XML-Entitaeten
  # der geänderte String wird zurückgegeben
  my $string = shift;
  if( isempty($string) ) { return " "; }
  $string =~ s/�/&auml;/g;
  $string =~ s/�/&ouml;/g;
  $string =~ s/�/&uuml;/g;
  $string =~ s/�/&Auml;/g;
  $string =~ s/�/&Ouml;/g;
  $string =~ s/�/&Uuml;/g;
  $string =~ s/�/&szlig;/g;
  $string =~ s/ä/&auml;/g;
  $string =~ s/ö/&ouml;/g;
  $string =~ s/ü/&uuml;/g;
  $string =~ s/Ä/&Auml;/g;
  $string =~ s/Ö/&Ouml;/g;
  $string =~ s/Ü/&Uuml;/g;
  $string =~ s/ß/&szlig;/g;
  return $string;
  }

sub uri_escape_utf8 {
  use URI::Escape;
  use Encode;
  my $string = shift;
#
  return uri_escape( encode("UTF-8", $string ));
  }

sub urlencode_punycode {
  use IDNA::Punycode;
  idn_prefix('xn--');
# codiert eine URL nach Punycode
# s. http://dcomnet.de/cgi-bin/punycode/punycode.cgi
  my $url = shift;
#
  $url =~ s/^http:\/\///;
  my @urlteile = split /\./, $url;
  for( my $i = 0; $i < $#urlteile ; $i++ ) {
    my $urlteil = $urlteile[$i];
    $urlteile[$i] = encode_punycode( $urlteil );
    }
  $url = $urlteile[0];
  for( my $i = 1; $i <= $#urlteile ; $i++ ) {
    $url .= ".".$urlteile[$i];
    }
  return $url;
  }

sub verzeichnisse {
	my $name = shift;
	unless( -e $name ) { 
		mkdir "$name", 0755 or die "Kann nicht Verzeichnis $name anlegen ($!)\n"; 
	}
}

sub verzeichnispfad {
	use File::Path;
	my $name = shift;
	unless( -e $name ) { 
		eval { mkpath($name) };
		if ($@) {
			print "Couldn't create $name: $@";
		}
	}
}

sub zeit {
	
	# Diese Subroutine übernimmt einen Zeitstempel und gibt einen String wie folgt zurück
	# YYYYMMDD_HHMM
	# Siehe auch sub timestring, iso8601
	
		my $zeitstempel = shift;
		my @time = localtime $zeitstempel;
		my $jahr = $time[5] + 1900;
		my $monat = &fuehrende_null( $time[4] + 1 );
		my $tag = &fuehrende_null( $time[3] );
		my $stunde = &fuehrende_null( $time[2] );
		my $min = &fuehrende_null( $time[1] );
		my $timestring = "$jahr$monat${tag}_$stunde$min";
		return $timestring;
}

sub winbasename {
	my $path = shift;
	my @teile = split /\\/, $path;
	@teile = reverse @teile;
	return $teile[0];
}

sub httrack_note {
	my $tidy_version_note = ks_media_allg::get_env( "tidy_version_note" );
	my $endverz = shift;
	my $notedatei = $endverz ."httrack2";
	my $downloadverz = shift;
	my $indexdatei = $downloadverz."/index.html";
	if( -e $indexdatei ) {
		my @facts = stat( $indexdatei );
		my $timestring = ks_media_allg::time_string( $facts[9] );
		if( ! open IN, ">$notedatei" ) {
                  my $errmsg = $!;
                  my $message = message->new( "WARN", __FILE__, __PACKAGE__, __LINE__,
                    "Kann Notizdatei $notedatei nicht anlegen! ($errmsg)" );
                  $message->print( *STDOUT, " ", "h" );
                 }
                else {
		  print IN "$timestring --- $tidy_version_note";
		  close IN;
                }
	} else {
		if( ! open IN, ">$notedatei" ) {
                  my $errmsg = $!;
                  my $message = message->new( "WARN", __FILE__, __PACKAGE__, __LINE__,
                    "Kann Notizdatei $notedatei nicht anlegen! ($errmsg)" );
                  $message->print( *STDOUT, " ", "h" );
                 }
                else {
		  print IN "--- $tidy_version_note";
		  close IN;
                }
	}
	return $notedatei;
}

sub writehtml2ocr {
# schreibt Text von allen HTML- und TXT-Dateien im Verzeichnis 
# und allen Unterverzeichnissem (Rekursion!) in EINE OCR-Datei.
# Text wird "gereinigt" (clean_text)
  use HTML::Entities;
  use Encode;
  use utf8;

  my $website_path = shift;
  my $ocr_datei = shift;
  my $batchmode = shift;
  my $log_dateihandle = shift;
  my $ocr_dateihandle = shift;
#
  # print $log_dateihandle "Website-Path=($website_path)<br/>\n";
  if ( ! $ocr_dateihandle ) {
    if ( $batchmode eq "nein" ) {
      print "<p><b>FEHLER:</b> writehtml2ocr: Kein OCR-Dateihandle uebergeben !! No OCR-Text written.<p>\n";
      }
    print $log_dateihandle "FEHLER: writehtml2ocr: Kein OCR-Dateihandle uebergeben !! Return.\n";
    return 1;
    }

  unless( chdir $website_path ) {
    print $log_dateihandle "FEHLER: Kann nicht in website_path $website_path wechseln! ($!). OCR-Text fuer OCR-Datei $ocr_datei wird nicht geschrieben.\n";
    return 1;
    }
  my @alle_dateien = glob "*";
  # printf $log_dateihandle "Anzahl Dateien in Website-Path: (%d)\n", $#alle_dateien +1;
  #  my $max_dateien = 1000;
  #  if ( $#alle_dateien > $max_dateien ) {
  #    print "<p>Mehr als $max_dateien Dateien !! Nur $max_dateien werden gefeedet !!!</p>\n";
  #    }

  my $dateien_zaehler = 0;
DATEI: foreach( @alle_dateien ) {
    my $datei = $website_path."/".$_;
    if( -s $ocr_datei > 450000 ) { last DATEI; }
    if( -d $datei ) {
      writehtml2ocr( $datei, $ocr_datei, $batchmode, $log_dateihandle, $ocr_dateihandle );
      next DATEI;
      }
    if( $datei && -f $datei && -s $datei > 50000 ) { next DATEI; }
    if( $datei !~ /\.htm$/ and $datei !~ /\.html$/ and $datei !~ /\.txt$/ ) {
      next DATEI;
      }
    if( $datei =~ /\/index.html$/ ) {
      # print $log_dateihandle "writehtml2ocr: Datei $datei skipped !\n";
      next DATEI; # index.html ist ein von HTTrack generierter "Local Index" !
      # die wirkliche "index"-Datei heisst meist index-2.html
      }
    if( $datei =~ /\/hts-log.txt$/ ) {
      # print $log_dateihandle "writehtml2ocr: Datei $datei skipped !\n";
      next DATEI; # httrack-Logdatei
      }
    if( ($datei =~ /\/new.txt$/) || ($datei =~ /\/old.txt$/) ) {
      # print $log_dateihandle "writehtml2ocr: Datei $datei skipped !\n";
      next DATEI; # Dateien in hts-cache/
      }
    # printf $log_dateihandle "writehtml2ocr: clean_text auf $datei\n";
    my $clean_text = clean_text( $datei, $log_dateihandle );
    if ( $clean_text ) {
      # print $log_dateihandle "writehtml2ocr: Datei $datei ,clean_text $clean_text\n";
      $dateien_zaehler++;
      #  print "Dateienzaehler:($dateien_zaehler)<br/>\n";
      #  if ( $dateien_zaehler > $max_dateien ) {
      #    print "$max_dateien bearbeitet. Abbruch !!<br/>\n";
      #    last DATEI;
      #    }
      #  print "Datei ist $datei<br/>\n";
      print $ocr_dateihandle "$clean_text ";
      }
    } # next DATEI
  } # ENDE Subroutine "writehtml2ocr"

sub writehtml2ocr2 { 
# wie oben, aber extrahiert ocr nur von html-Dateien, nicht von txt-Dateien
  use HTML::Entities;
  use Encode;
  use utf8;

  my $website_path = shift;
  my $ocr_datei = shift;
  my $titelstring = shift;
#
  unless( chdir $website_path ) {
    print "FEHLER: Kann nicht in website_path $website_path wechseln! ($!). OCR-Text fuer OCR-Datei $ocr_datei wird nicht geschrieben.\n";
    return 1;
    }
  my @alle_dateien = glob "*";
  if( ! open OCR, ">$ocr_datei" ) {
    print "FEHLER: Kann OCR-Datei $ocr_datei nicht anlegen!\n";
    return 1;
  }
  print OCR "$titelstring\n";
DATEI:	foreach( @alle_dateien ) {
    my $datei = $website_path.$_;
#    print "<p>Datei ist $datei</p>";
    if( -s $ocr_datei > 450000 ) { last DATEI; }
    if( -s $datei > 50000 ) { next DATEI; }
    if( -d $datei ) {
      writehtml2ocr( $datei, $ocr_datei, "nein", 0, *OCR);
      next DATEI;
      }
    if( $datei !~ /\.htm$/ and $datei !~ /\.html$/ ) { next DATEI; }
    if( $datei !~ /[0-9]+?-t[0-9]\.htm/ ) { next DATEI; }
    print "Datei ist $datei\n";
    my $clean_text = clean_text( $datei, *STDOUT );
    if( $clean_text ) {
      print OCR "$clean_text ";
      }
    } # next DATEI
  close OCR;
  print "OCR-Datei $ocr_datei wurde geschrieben\n";
  }

sub chk_utf8 {
  my $chkstr = shift;
  my $dateihandle = shift;
  # print $dateihandle "Chkstr=($chkstr) ";

  if ( $chkstr =~
    m/^(
       [\x00-\x7F]                        # ASCII
     | [\xC2-\xDF][\x80-\xBF]             # non-overlong 2-byte
     |  \xE0[\xA0-\xBF][\x80-\xBF]        # excluding overlongs
     | [\xE1-\xEC\xEE\xEF][\x80-\xBF]{2}  # straight 3-byte
     |  \xED[\x80-\x9F][\x80-\xBF]        # excluding surrogates
     |  \xF0[\x90-\xBF][\x80-\xBF]{2}     # planes 1-3
     | [\xF1-\xF3][\x80-\xBF]{3}          # planes 4-15
     |  \xF4[\x80-\x8F][\x80-\xBF]{2}     # plane 16
    )*$/x )
    {
# print $dateihandle "retval=1\n";
    return 1;
    }
  
# print $dateihandle "retval=0\n";
return 0;
}

sub hbz_streamname {
  # liefert den Dateinamen fuer einen Stream zurueck, so wie er im hbz
  # verwendet werden soll.
  # Stream = vom Kunden gelieferte Datei fuer das Catalogue Enrichment
  my $lieferant          = shift; # z.B. "imw", "spr", "cas", ...
  my $lieferanten_id     = shift; # z.B. HT-Nr, Casalini-ID, ...
  my $lieferanten_suffix = shift; # z.B. "t1" (toc), "c2" (Probekapitel 2), ...
  my $dateityp           = shift; # Dateiendung; z.B. tiff, pdf, jpg, txt, ...
#
  my $lief_lc = $lieferant; $lief_lc =~ s/($lief_lc)/\L$1/;
  my $lief_id_lc = $lieferanten_id; $lief_id_lc =~ s/($lief_id_lc)/\L$1/;
  my $suffix_lc = $lieferanten_suffix; $suffix_lc =~ s/($suffix_lc)/\L$1/;
  $dateityp =~ s/^\.//; # remove leading dot
  my $dateityp_lc = $dateityp; $dateityp_lc =~ s/($dateityp_lc)/\L$1/;
  return "${lief_lc}_${lief_id_lc}_${suffix_lc}.${dateityp_lc}";
  }

sub hbz_streamname_pkn {
  # liefert den Dateinamen fuer Objekte eines Streams (der Stream selber oder Metadaten) zurueck,
  # so wie er im hbz im Projekt PKN verwendet werden soll.
  # Stream = vom Kunden gelieferte Datei fuer das Catalogue Enrichment
  my $lieferant          = shift; # sollte hier "pkn" sein
  my $lief_id            = shift; # z.B. Aleph-IDN
  my $inhalt_id          = shift; # "md" fuer Metadaten, "de" fuer den Stream
  my $owner              = shift; # aus Unterfeld m
  my $catenrtype         = shift; # aus Unterfeld 3
  my $mime_type          = shift; # aus Unterfeld q
  my $lfdnr_objekt       = shift; # durchnummerieren, falls bis hierhin alles gleich war
  my $dateiendung        = shift; # z.B. tiff, pdf, jpg, txt, html, xml, ...
#
  my $lieferant_lc = $lieferant; $lieferant_lc =~ s/($lieferant_lc)/\L$1/;
  my $lief_id_lc = $lief_id; $lief_id_lc =~ s/($lief_id_lc)/\L$1/;
  my $inhalt_id_lc = $inhalt_id; $inhalt_id_lc =~ s/($inhalt_id_lc)/\L$1/;
  $dateiendung =~ s/^\.//; # remove leading dot
  my $dateiendung_lc = $dateiendung;
  if( $dateiendung_lc ne "*" ) { $dateiendung_lc =~ s/($dateiendung_lc)/\L$1/; }
  if( isempty($lfdnr_objekt) ) { $lfdnr_objekt = "*"; }
  my $lfdnr_str = "";
  if( $lfdnr_objekt !~ /^[0-9][0-9]*$/ ) {
    # lfd.Nr. ist nicht numerisch
    $lfdnr_str = $lfdnr_objekt;
    }
  else {
    $lfdnr_str = sprintf("%06d", $lfdnr_objekt);
    }

  return sprintf("%s_%s_%s_%s_%s_%s_%s.%s"
    , hbz_dateiname_pkn_safe( $lieferant_lc )
    , hbz_dateiname_pkn_safe( $lief_id_lc )
    , hbz_dateiname_pkn_safe( $inhalt_id_lc )
    , hbz_dateiname_pkn_safe( $owner )
    , hbz_dateiname_pkn_safe( $catenrtype )
    , hbz_dateiname_pkn_safe( $mime_type )
    , $lfdnr_str
    , hbz_dateiname_pkn_safe( $dateiendung_lc )
    );
  }

sub hbz_parentname_pkn {
  # liefert den Dateinamen fuer Objekte des Parents (Streams oder Metadaten) zurueck,
  # so wie er im hbz im Projekt PKN verwendet werden soll.
  my $lieferant          = shift; # sollte hier "pkn" sein
  my $lief_id            = shift; # z.B. Aleph-IDN
  my $inhalt_id          = shift; # "md" fuer Metadaten, "de" fuer den Stream
  my $dateiendung        = shift; # z.B. tiff, pdf, jpg, txt, html, xml, ...
#
  my $lieferant_lc = $lieferant; $lieferant_lc =~ s/($lieferant_lc)/\L$1/;
  my $lief_id_lc = $lief_id; $lief_id_lc =~ s/($lief_id_lc)/\L$1/;
  my $inhalt_id_lc = $inhalt_id; $inhalt_id_lc =~ s/($inhalt_id_lc)/\L$1/;
  $dateiendung =~ s/^\.//; # remove leading dot
  my $dateiendung_lc = $dateiendung; $dateiendung_lc =~ s/($dateiendung_lc)/\L$1/;

  return sprintf("%s_%s_%s.%s"
    , hbz_dateiname_pkn_safe( $lieferant_lc )
    , hbz_dateiname_pkn_safe( $lief_id_lc )
    , hbz_dateiname_pkn_safe( $inhalt_id_lc )
    , hbz_dateiname_pkn_safe( $dateiendung_lc )
    );
  }

sub hbz_dateiname_pkn_safe {
  # Ersetzt z.B. Leerzeichen oder Slashes,
  # aber auch vorbelegte hbz-interne Feldtrennzeichen (.,_)
  # in Verzeichnis- oder Dateinamen
  my $rawname = shift;
#
  $rawname =~ s/[ ]+/~/g;
  $rawname =~ s/\//#/g;
  $rawname =~ s/\./-/g;
  $rawname =~ s/_/-/g;
  $rawname =~ s/ä/ae/g;
  $rawname =~ s/ö/oe/g;
  $rawname =~ s/ü/ue/g;
  $rawname =~ s/Ä/ae/g;
  $rawname =~ s/Ö/oe/g;
  $rawname =~ s/Ü/ue/g;
  $rawname =~ s/ß/ss/g;
  return $rawname;
  }

sub hbzMediaBasename {
##############################################################################
# Basename - sowohl fuer Windows als auch Unix/Linux
#          - fuer alle Browsertypen
# IK20070209
##############################################################################
  my $dateiname = shift;
  if ( $dateiname ) {
    $dateiname =~ s/.*[\/\\](.*)/$1/;
    }
  return $dateiname;
  }

sub hbzMediaPathname {
##############################################################################
# Pfadname - sowohl fuer Windows als auch Unix/Linux
#          - fuer alle Browsertypen
# IK20120720
##############################################################################
  my $dateiname = shift;
  if ( $dateiname ) {
    if ( $dateiname =~ m/^(.*[\/\\])[^\/\\]*$/ ) {
      $dateiname = $1;
      }
    else { $dateiname = ""; }
    }
  return $dateiname;
  }

sub clean_text {
  my $datei = shift;
  my $log = shift;
#
  return clean_text_optionalencode( $datei, "utf-8", $log );
  }

sub clean_text_optionalencode {
###############################################################################
# Bereinigt Dateien (HTML oder TXT)
# Autor :  Kuss
# Version: 10.April 2007
###############################################################################

  use Encode;
  use HTML::Entities;

  my $datei = shift;
  my $optional_encoding = shift;
  my $log = shift;
#
  if( ! open(IN, "$datei") ) {
    dprintfsu($log,"WARNUNG! Kann nicht Text- oder html-Datei (%s) oeffnen ($!)\n", $datei);
    printf   $log  "         clean_text fuer Datei nicht moeglich, nehme leeren Inhalt an.\n";
    return "";
    } 
  my $clean_text = "";
ZEILE: while( <IN> ) {
    my $zeile = $_; 
    $zeile =~ s/\n/ /g;
    $zeile =~ s/\r/ /g;
    $zeile = decode_entities( $zeile );
    $zeile =~ s/\t/ /g;
    $zeile =~ s/<!--.*?-->/ /gi; # einzeilige Kommentare entfernen
    $zeile =~ s/<![^<]*?>/ /gi; # einzeilige Meta-Tags entfernen
    # <style- und <script -Tags markieren (werden zunaechst nicht entfernt)
    $zeile =~ s/<style.*?>/{BEGIN_STYLE}/gi;
    $zeile =~ s/<\/style.*?>/{END_STYLE}/gi;
    $zeile =~ s/<script.*?>/{BEGIN_SCRIPT}/gi;
    $zeile =~ s/<\/script.*?>/{END_SCRIPT}/gi;
    # <noframes -Tags markieren (werden spaeter entfernt)
    $zeile =~ s/<noframes.*?>/{BEGIN_NOFRAMES}/gi;
    $zeile =~ s/<\/noframes.*?>/{END_NOFRAMES}/gi;
    $zeile =~ s/<[^!>][^<]*?>/ /gi; # einzeilige HTML-Elemente entfernen
    $zeile =~ s/[ \t�|]+/ /g; # aufeinanderfolgende Zwischenraeume entfernen
    if( isdefined( $optional_encoding ) ) {
      $zeile = encode( $optional_encoding, $zeile );
      }
    if ( $zeile =~ /^[ \t]*$/ ) { next ZEILE; }
    # print "Zeile: $zeile\n";
    $clean_text = $clean_text . " " . $zeile;
    }
    close IN;
  $clean_text =~ s/<!--.*?-->//gi; # mehrzeilige Kommentare entfernen
  $clean_text =~ s/<![^<]*?>//gi; # mehrzeilige Meta-Tags entfernen
  # style- ,script- und noframes- Elemente entfernen
  $clean_text =~ s/{BEGIN_STYLE}.*?{END_STYLE}//g;
  $clean_text =~ s/{BEGIN_STYLE}//g; # sich selbst schliessende style-Elemente
  $clean_text =~ s/{BEGIN_SCRIPT}.*?{END_SCRIPT}//g;
  $clean_text =~ s/{BEGIN_SCRIPT}//g; # sich selbst schliessende script-Elemente
  $clean_text =~ s/{BEGIN_NOFRAMES}.*?{END_NOFRAMES}//g;
  $clean_text =~ s/{BEGIN_NOFRAMES}//g; # sich selbst schliessendes <noframes/>
  $clean_text =~ s/<[^!>][^<]*?>//gi; # mehrzeilige HTML-Elemente entfernen
  $clean_text =~ s/[ \t�|]+/ /g; # aufeinanderfolgende Zwischenraeume entfernen

  return $clean_text;
  }

sub csv_datei_einlesen {
  my $dateiname = shift;
  my $headline  = shift; # ref of array
  my $lines     = shift; # ref of array
  my $sortby    = shift;
  my $sortdir   = shift;
#
  @{$headline} = ();
  @{$lines} = ();
  my %rethash=();
  $rethash{retcode} = $FCT_RC_OK;

  if( ! open CSV, $dateiname ) {
    my $errmsg = $!;
    push @{$rethash{messages}}, 
      new message("ERROR", __FILE__, __PACKAGE__, __LINE__,
      sprintfsu( "CSV-Datei %s kann nicht eingelesen werden!(%s)" ,$dateiname, $errmsg ) );
    $rethash{retcode} = $FCT_RC_NOTOK;
    return %rethash;
  }
  my @lines_unsorted = ();
CSV_LINE:  while (<CSV>) {
    chomp $_;
    my @feldliste=split(";",$_);
    if( $feldliste[0] =~ m/^\^(.*)$/ ) {
      # Ueberschriftszeile auswerten
      $feldliste[0] = $1;
      for( my $jog = 0; $jog <= $#feldliste ; $jog++ ) {
        ${$headline}[$jog] = $feldliste[$jog];
        }
      next;
    }
    my $line = { }; # leeres Hashref
    for( my $jogHead = 0; $jogHead <= $#{$headline} ; $jogHead++ ) {
      if( $jogHead > $#feldliste ) { last; }
      $line->{${$headline}[$jogHead]} = $feldliste[$jogHead];
    }
    push @lines_unsorted, $line;
  }
  close CSV;
  
  # Zeilen sortieren
  if( $sortby ) {
    if( $sortdir && $sortdir eq "DESC" ) {
      @{$lines} = reverse sort { $a->{$sortby} cmp $b->{$sortby} } @lines_unsorted;
    }
    else {
      @{$lines} = sort { $a->{$sortby} cmp $b->{$sortby} } @lines_unsorted;
    }
  } else {
    @{$lines} = @lines_unsorted;
  }
  return %rethash;
} # end of sub "csv_datei_einlesen"

sub csv_datei_neuanlage {
  # die gesamte CSV-Datei wird aufgrund der uebergebenen Liste neu angelegt
  my $dateiname = shift;
  my $headline  = shift; # ref of array; muss aktuell sein
  my $lines_all = shift; # ref of array; Liste muss vollstaendig
                         #               und, falls gewuenscht, geordnet sein!
#
  my %rethash=();
  $rethash{retcode} = $FCT_RC_OK;

  if( ! open CSV, ">$dateiname" ) {
    my $errmsg = $!;
    push @{$rethash{messages}}, 
      new message("ERROR", __FILE__, __PACKAGE__, __LINE__,
      sprintfsu( "CSV-Datei %s kann nicht neu angelegt werden!(%s)" ,$dateiname, $errmsg ) );
    $rethash{retcode} = $FCT_RC_NOTOK;
    return %rethash;
  }

  # Neuanlage der Ueberschriftszeile
  print CSV "^";
  for( my $jogHead = 0; $jogHead <= $#{$headline} ; $jogHead++ ) {
    print CSV ${$headline}[$jogHead] . ";";
  }
  print CSV "\n";

  # Neuanlage der Inhaltszeilen
  for( my $jog = 0; $jog <= $#{$lines_all} ; $jog++ ) {
    for( my $jogHead = 0; $jogHead <= $#{$headline} ; $jogHead++ ) {
      print CSV ${$lines_all}[$jog]->{${$headline}[$jogHead]} . ";";
    }
    print CSV "\n";
  }
  close CSV;
  return %rethash;
} # end of sub "csv_datei_neuanlage"

sub csv_datei_teilmenge_bilden {
  # ermittelt eine Teilmenge (per Filter) aus einer bereits eingelesenen
  # Liste von Eintraegen einer CSV-Datei
  my $lines_all  = shift; # ref of array (unchanged)
  my $filter_nam = shift; # z.B. "url_id"
  my $filter_val = shift; # z.B. 1182 (=url_id)
  my $sortby     = shift; # z.B. "anl_dat"
  my $sortdir    = shift; # "DESC", "ASC"
  my $sortop     = shift; # "num", "alph"
  my $lines_teil = shift; # ref of array
#
  my @lines_unsorted = ();
  foreach my $line ( @{$lines_all} ) {
    if( $line->{$filter_nam} eq $filter_val ) {
      push @lines_unsorted, $line;
    }
  }

  @{$lines_teil} = ();
  # Zeilen sortieren
  if( $sortby ) {
    if( $sortop eq "num" ) {
      # numerische Sortierung
      if( $sortdir && $sortdir eq "DESC" ) {
        @{$lines_teil} = reverse sort { $a->{$sortby} <=> $b->{$sortby} } @lines_unsorted;
      }
      else {
        @{$lines_teil} = sort { $a->{$sortby} <=> $b->{$sortby} } @lines_unsorted;
      }
    }
    else {
      # alphanumerische Sortierung
      if( $sortdir && $sortdir eq "DESC" ) {
        @{$lines_teil} = reverse sort { $a->{$sortby} cmp $b->{$sortby} } @lines_unsorted;
      }
      else {
        @{$lines_teil} = sort { $a->{$sortby} cmp $b->{$sortby} } @lines_unsorted;
      }
    }
  } else {
    @{$lines_teil} = @lines_unsorted;
  }

} # end of sub "csv_datei_teilmenge_bilden"

sub rmkdir {
###############################################################################
# rekursives mkdir
# legt Verzeichnisse unterhalb von Basedir an, falls nötig
###############################################################################
  my $basedir = shift;
  my $reldir  = shift;
#
  my %rethash=();
  $reldir =~ s/^[\/\\]*//; # remove leading dir-slashes (i.e. ignore them)

  if ( -d $basedir."/$reldir" ) {
    # ...nichts zu tun ...
    $rethash{"retcode"} = $FCT_RC_OK;
    return %rethash;
    }

  if ( ! -d $basedir ) {
    push @{$rethash{"messages"}}, 
      new message("ERROR", __FILE__, __PACKAGE__, __LINE__,
      sprintf( "%s is not a directory! Subdirectories cannot be created."
             , $basedir ) );
    $rethash{"retcode"} = $ks_media_allg::FCT_RC_NOTOK;
    return %rethash;
    }

  my $actdir_sav = `pwd`;
  chdir $basedir;
  my $startpos = 0;
  my $nextpos = nextpos($reldir, $startpos);
  my $act_subdir;
POS:  while( $nextpos >= $startpos ) {
    if( $nextpos == $startpos ) {
      # consecutive dir-separators: ignore all but one
      $startpos++;
      $nextpos = nextpos($reldir, $startpos);
      next POS;
      }
    $act_subdir = substr( $reldir, $startpos, $nextpos - $startpos );
    # print "act_subdir $act_subdir\n";
    if ( ! -d $act_subdir ) { mkdir( $act_subdir, 0775 ); }
    chdir $act_subdir;
    $startpos = $nextpos + 1;
    $nextpos = nextpos($reldir, $startpos);
    }
  if ( $startpos < length($reldir) ) {
    $act_subdir = substr( $reldir, $startpos );
    # print "act_subdir $act_subdir\n";
    if ( ! -d $act_subdir ) { mkdir( $act_subdir, 0775 ); }
    }
  chdir $actdir_sav;
  $rethash{"retcode"} = $ks_media_allg::FCT_RC_OK;
  return %rethash;

  sub nextpos {
# find next dir-separator
    my $reldir = shift;
    my $startpos = shift;
#
    my $nextpos_linux = index( $reldir, "/", $startpos ); 
    my $nextpos_win = index( $reldir, "\\", $startpos ); 
    if( ($nextpos_linux < 0) && ($nextpos_win < 0) ) { return -1; }
    if( $nextpos_win < 0 ) { return $nextpos_linux; }
    if( $nextpos_linux < 0) { return $nextpos_win; }
    my $nextpos = $nextpos_linux;
    if ( $nextpos_win < $nextpos_linux ) { $nextpos = $nextpos_win; }
    return $nextpos; 
    }
  } # END of SUB "rmkdir"

sub terminate_on_err {
  my $errstr         = shift;
  my $logdateihandle = shift;
#
  my $message = message->new( "ERROR", __FILE__, __PACKAGE__, __LINE__
    , $errstr );
  $message->print( $logdateihandle, "f" );
  $message = message->new( "INFO", __FILE__, __PACKAGE__, __LINE__
    , "Exiting Perl." );
  $message->print( $logdateihandle, "f" );
  exit 0;
  }

#******************************************************************************
package message;
#******************************************************************************
sub new {
  my $invocant = shift; # aufrufende Klasse
  my $msgClass = shift; # Nachrichtenklasse (z.B. ERROR)
  my $datei    = shift; # Datei, in der die Nachricht aufgetreten ist
  my $package  = shift; # Paket, in dem die Nachricht aufgetreten ist
  my $lineno   = shift; # Zeile, in der die Nachricht aufgetreten ist
  my $text     = shift; # der Nachrichtentext (erste Zeile)
#
  my $class = ref($invocant) || $invocant;
  my ($sek, $min, $std, $mtag, $mon, $jahr, $wtag, $ytag, $isdst)
      = localtime;
  my $zeitstempel = sprintf( "%02d.%02d.%4d %02d:%02d:%02d", $mtag, $mon+1, 1900+$jahr, $std, $min, $sek);
  my $prot_level = $prot_levels{$msgClass};
  if( ! $prot_level ) { $prot_level = $prot_levels{DEFAULT}; }
  my @msglines = ( messageline->new( $text, prot_level => $prot_level, @_ ) );
  my $self = {
      msgClass => $msgClass
     ,time     => $zeitstempel
     ,datei    => $datei
     ,package  => $package
     ,lineno   => $lineno
     ,msglines => \@msglines
     ,procedere   => undef
     ,prot_level  => $prot_level
     , @_      # weitere oder zu ueberschreibende Attribute
    };
  return bless($self, $class);
  }

sub addline {
  my $self = shift;
  my $text = shift;
#
  my $msgline = messageline->new( $text, prot_level => $self->{prot_level}, @_ );
  push @{$self->{msglines}}, $msgline;
  }

sub last_msgline {
  my $self = shift;
#
  my $anz_msglines = $#{$self->{msglines}};
  return ${$self->{msglines}}[$anz_msglines];
  }

sub print {
# Ausgabe einer Nachricht
  my $self = shift;
  my $log = shift;
  my $ausg_level = shift;
  my $ausg_style = shift;
#
  if ( ! $log ) { return; }
  if ( ! $ausg_level ) { $ausg_level = " "; }
  if ( ! $ausg_style ) { $ausg_style = " "; }
  # Zeile fuer Zeile ausgeben
  my $msgline;
  foreach $msgline (@{$self->{msglines}}) {
    if ( $msgline->{prot_level} < $prot_level_min ) { next; }
    if ( $ausg_style =~ /[h]/ ) { print $log "<p>"; } # Start HTML
    elsif ( $ausg_style =~ /[f]/ ) { print $log "<div class=\"fortschrittszeile\">"; }
    if ( $ausg_level =~ /[tzf]/ ) { print $log  "$self->{time} "; }
    if ( $ausg_style =~ /[hf]/ ) {
      # farbige Ausgabe der Nachrichtenklasse, falls Ausgabe als HTML
      if(   $self->{msgClass} =~ /^ERR/
         || $self->{msgClass} =~ /^FEHLER/ ) { print $log "<font color=\"red\">"; }
      elsif( $self->{msgClass} =~ /^WARN/ ) { print $log "<font color=maroon>"; }
      elsif(  $self->{msgClass} =~ /^SUCCESS/
           || $self->{msgClass} =~ /^ERFOLG/ ) { print $log "<font color=green>"; }
      else { print $log "<font>"; }
      }
    print $log "$self->{msgClass}:";
    if ( $ausg_style =~ /[hf]/ ) { print "</font>"; }
    if ( $ausg_level =~ /[lof]/ ) { 
      print $log " in Datei " . ks_media_allg::hbzMediaBasename($self->{datei}) . " Paket $self->{package} Zeile $self->{lineno}";
      }
    print $log " $msgline->{text}";
    if( $msgline->{procedere} ) { print $log " $msgline->{procedere}"; }
    if ( $ausg_style =~ /[h]/ ) { print $log "</p>"; } # Ende HTML
    elsif ( $ausg_style =~ /[f]/ ) { print $log "</div>"; }
    print $log "\n";
    }
  }

#******************************************************************************
package messageline;
#******************************************************************************
# Klasse fuer eine einzelne Zeile einer Nachricht (fuer mehrzeilige Nachr.)
#******************************************************************************
sub new {
  my $invocant = shift; # aufrufende Klasse
  my $text     = shift; # der Nachrichtentext
#
  my $class = ref($invocant) || $invocant;
  my $self = {
      text     => $text
     ,procedere   => undef
     ,prot_level  => $prot_levels{DEFAULT}
     , @_      # weitere oder zu ueberschreibende Attribute
    };
  return bless($self, $class);
  }

sub concat {
  my $self = shift;
  my $text = shift;
#
  $self->{text} .= "$text";
  }

1;
