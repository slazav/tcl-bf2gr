########################################################################
# lanc_press -- parse Lancaster wire/fork logs, put data into graphene database.
#   V.Zavjalov, 04.2020
#
# data file assumptions:
#   There are a dumper of files scattered in the filesystem
#   Each file contains 17 tab-separated columns:
#     * date dd/mm/YYYY
#     * time HH:MM:SS
#
# 1. Scan all files and extract time of the firs record
# 2. Choose files with starting time larger then last DB
#    record + the most recent "old file"
#
# Arguments:
#  dbdev  - database device
#  dbname - database name
#  data_files - list of files. *, ? patterns are allowed
#  verb       - be verbose
#  overwrite  - read all files, overwrite values in the database

proc lanc_wire {dbdev dbname data_files {verb 1} {overwrite 0}} {

  ## extract time from data list
  proc line2time {ll} {
    set d [lindex $ll 0]
    set t [lindex $ll 1]
    return [clock scan "$d $t" -format "%d/%m/%Y %H:%M:%S"]
  }

  ########################################################################

  # create database if needed
  if [catch {$dbdev cmd info $dbname}] { $dbdev cmd create $dbname DOUBLE }

  if {$verb} {puts "updating: $dbname"}

  ## get tmax value
  if {$overwrite} {
    set tmax 0
  } else {
    set tmax [lindex [lindex [$dbdev cmd get_prev $dbname] 0] 0]
  }
  if {$verb} {puts " database last timestamp: $tmax"}

  # find all files
  set files []; # list of all data files contain sub-lists {name time}
  set tskip 0; # largest time from files smaller then tmax
  foreach g $data_files {
    foreach f [glob -nocomplain $g] {
      # open file, get time from the first line:
      set ff [open $f]
      while {[gets $ff l]>-1} {
        if {[catch {set ts [line2time $l]}]} {continue}
        break
      }
      close $ff
      if {$ts<$tmax && $ts > $tskip} {set tskip $ts}
      lappend files [list $f $ts]
    }
  }

  set files [lsort -integer -index 1 $files]

  if {$verb} {puts " skip files until: $tskip"}

  foreach f $files {
    if {!$overwrite && [lindex $f 1] < $tskip} {continue}
    if {$verb} {puts " file: [lindex $f 0]"}
    set ff [open [lindex $f 0]]
    while {[gets $ff l]>-1} {
      if {[catch {set ts [line2time $l]}]} {continue}

      if {$ts > $tmax} {
        $dbdev cmd put $dbname $ts [lrange $l 2 end]
      }
    }
    close $ff
    $dbdev cmd sync $dbname
  }
}


