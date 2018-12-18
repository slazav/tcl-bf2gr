########################################################################
# rota_fork -- parse ROTA fork files, put data into graphene database.
#   V.Zavjalov, 12.2018

proc rota_fork {db dbprefix main_folder fork_name {verb 1}} {

  set dbname "${dbprefix}_${fork_name}"
  set dbtype "float"

  # create database if needed
  if [catch {$db cmd info $dbname}] { $db cmd create $dbname $dbtype }
  if {$verb} {puts "updating: $dbname"}

  proc read_file {file db dbname tday tmax verb} {
    if {$verb} {puts "$file"}
    set fp [open $file r]

    while {1} {
      set str [gets $fp]
      if {[eof $fp]} break
      if {$str==""} continue

      set tim [lindex $str 9]
      set fre [lindex $str 11]
      set wid [lindex $str 12]
      set amp [lindex $str 13]

      if {$amp==""} continue
      if {$tim <= $tmax} { continue }
      if {$verb > 1} {puts " process data: $tim $fre $wid $amp"}
      $db cmd put $dbname $tim $fre $wid $amp
    }
    close $fp
  }

  ## get max value
  set prev [lindex [$db cmd get_prev $dbname] 0]
  set tmax  [lindex $prev 0]
  if {$verb} {puts " db_max_time: $tmax"}
  if {$tmax == ""} {set tmax [clock scan "1995-01-01"]}

  # go through all dates from tmax to current date
  set t [expr int($tmax)]
  set tC [clock seconds]
  while {$t<$tC} {
    set Y [clock format $t -format %Y]
    set m [clock format $t -format %m]
    set d [clock format $t -format %d]
    set tday [clock scan "$Y-$m-$d"]
    set file "$main_folder/$Y/$m/$d/$Y$m$d-${fork_name}.dat"
    if {[file exists $file]} {read_file $file $db $dbname $tday $tmax $verb}
    set t [expr $tday+25*3600]
  }

  $db cmd sync $dbname
}

########################################################################
# parse ROTA log files, put data into graphene database.

proc rota_log {db dbprefix main_folder {verb 1}} {

  set dbname "${dbprefix}_log"
  set dbtype "TEXT"

  # create database if needed
  if [catch {$db cmd info $dbname}] { $db cmd create $dbname $dbtype }
  if {$verb} {puts "updating: $dbname"}

  proc read_file {file db dbname tday tmax verb} {
    if {$verb} {puts "$file"}
    set fp [open $file r]

    while {1} {
      set str [gets $fp]
      if {[eof $fp]} break
      if {[regexp {^([0-9]+)\s+(.*)} $str v tim comm]==0} continue
      if {$tim==""} continue
      if {$comm==""} continue
      set tim [scan $tim %d]
      set tstamp [expr {$tday + $tim}]
      if {$tstamp <= $tmax} { continue }
      if {$verb > 1} {puts " process data: $tstamp $comm"}
      $db cmd put $dbname $tstamp $comm
    }
    close $fp
  }

  ## get max value
  set prev [lindex [$db cmd get_prev $dbname] 0]
  set tmax  [lindex $prev 0]
  if {$verb} {puts " db_max_time: $tmax"}
  if {$tmax == ""} {set tmax [clock scan "1995-01-01"]}

  # go through all dates from tmax to current date
  set t [expr int($tmax)]
  set tC [clock seconds]
  while {$t<$tC} {
    set Y [clock format $t -format %Y]
    set m [clock format $t -format %m]
    set d [clock format $t -format %d]
    set tday [clock scan "$Y-$m-$d"]
    set file "$main_folder/$Y/$m/$d/$Y$m$d.log"
    if {[file exists $file]} {read_file $file $db $dbname $tday $tmax $verb}
    set t [expr $tday+25*3600]
  }

  $db cmd sync $dbname
}

########################################################################
# parse ROTA bindat files, put data into graphene database.

proc rota_bindat {db dbprefix main_folder {verb 1}} {

  set dbname "${dbprefix}_bindat"
  set dbtype "FLOAT"

  # create database if needed
  if [catch {$db cmd info $dbname}] { $db cmd create $dbname $dbtype }
  if {$verb} {puts "updating: $dbname"}

  proc read_file {file db dbname tday tmax verb} {
    if {$verb} {puts "$file"}
    set fp [open $file r]
    fconfigure $fp -translation binary

    set N [expr 4*11]
    while {1} {
      set str [read $fp $N]
      if {[binary scan $str iffffffffff lastfileid tim\
         omega fsetA fmeasA absA dispA fsetB fmeasB absB dispB] != 11} break
      set tstamp [expr {$tday + $tim}]
      if {$tstamp <= $tmax} { continue }
      set data "$omega $fsetA $fmeasA $absA $dispA $fsetB $fmeasB $absB $dispB"
      if {$verb > 1} {puts " process data: $tstamp  $data"}
      $db cmd put $dbname $tstamp {*}$data
    }
    close $fp
  }

  ## get max value
  set prev [lindex [$db cmd get_prev $dbname] 0]
  set tmax  [lindex $prev 0]
  if {$verb} {puts " db_max_time: $tmax"}
  if {$tmax == ""} {set tmax [clock scan "1995-01-01"]}

  # go through all dates from tmax to current date
  set t [expr int($tmax)]
  set tC [clock seconds]
  while {$t<$tC} {
    set Y [clock format $t -format %Y]
    set m [clock format $t -format %m]
    set d [clock format $t -format %d]
    set tday [clock scan "$Y-$m-$d"]
    set file "$main_folder/$Y/$m/$d/$Y$m$d.bindat"
    if {[file exists $file]} {read_file $file $db $dbname $tday $tmax $verb}
    set t [expr $tday+25*3600]
  }

  $db cmd sync $dbname
}
