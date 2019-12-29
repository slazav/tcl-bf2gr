########################################################################
# lanc_press -- parse Lancaster pressure logs, put data into graphene database.
#   V.Zavjalov, 12.2019

proc lanc_press {dbdev dbname data_folder {verb 1}} {

  ########################################################################
  ## extract time from filename
  ## plog2019Dec10_1352.dat
  proc fname2time {name} {
    set v {}
    regexp {plog\d{4}[A-Za-z]+\d{2}_\d{2}\d{2}} $name v
    if {$v=={}} { error "Unknown file name: $name" }
    return [clock scan $v -format "plog%Y%b%d_%H%M"]
  }

  ########################################################################

  # all files
  set all_data_files [glob -nocomplain -directory $data_folder {*.dat}]

  # create database if needed
  if [catch {$dbdev cmd info $dbname}] { $dbdev cmd create $dbname FLOAT }

  if {$verb} {puts "updating: $dbname"}

  ## get max value
  set max [lindex [lindex [$dbdev cmd get_prev $dbname] 0] 0]
  if {$verb} {puts " max: $max"}




  # choose one early file and all later files
  set oldfile {}
  set oldt {}
  if {$max!={}} {
    set data_files {}
    foreach f $all_data_files {
      set t1 [fname2time $f]


      if {$t1>$max } { lappend data_files $f }\
      elseif {$oldt=={} || $oldt < $t1 } {
         set oldfile $f; set oldt $t1
      }
    }
  } else {
    set data_files $all_data_files
  }

  # insert the latest old file in the beginning
  if {$oldfile!={}} {
    set data_files [linsert $data_files 0 $oldfile]
  }


  foreach file $data_files {
    if {$verb} {puts " file: $file"}

    # extract time from filename
    set t0 [fname2time $file]

    set ff [open $file]
    while {[gets $ff line]>-1} {

      # Line format: tab-separated values:
      # time (with second fraction), date, v1, v2, etc.
      #  10:58:02.20<--->18/12/2019<---->63.524458

      # data should contain at least 3 columns
      if {[llength $line] <3 } continue

      # extract timestamp
      if {![regexp {(\d+:\d+:\d+)(\.\d+)} [lindex $line 0] v v1 v2]} continue
      set tt [clock scan "[lindex $line 1] $v1" -format "%d/%m/%Y %H:%M:%S"]
      set tt [expr "$tt+$v2"]
 
      if {$tt > $max} {
        $dbdev cmd put $dbname $tt [lrange $line 2 end]
      }
    }
    close $ff
    $dbdev cmd sync $dbname
  }
}


