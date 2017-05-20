########################################################################
# bf2gr -- parse Bluefors logfiles, put data into graphene database.
# Only data newer then the last database record are read.
# Function can be run regularly to update the database.
#
# Parameters:
#   db          -- database device (see Device package)
#   dbprefix    -- database prefix; data goes into <dbprefix>/<channel> database
#   main_folder -- folder with data
#   channels    -- name of channels to process
#   verb        -- verbosity level: 0-1
#
# Supported channels:
#   flow  -- parse Flowmeter*.log files
#   CH<N>R -- parse CH<N> R*.log file
#   CH<N>T -- parse CH<N> R*.log file
#   chan  -- Channels*.log files (not supported yet!)
#   gauge -- parse Maxigauge*.log files (not supported yet!)


proc bf2gr {db dbprefix main_folder channels {verb 1}} {

########################################################################
## which files correspond to a database
proc get_glob {name} {
  if {$name == {flow}}  {return {Flowmeter*.log}}
  if {$name == {gauge}} {return {Maxigauge*.log}}
  if {$name == {chan}}  {return {Channels*.log}}
  if {[regexp {^CH(\d+)R} $name cc n]}  {return "CH$n R*.log"}
  if {[regexp {^CH(\d+)T} $name cc n]}  {return "CH$n T*.log"}
  error "get_glob: unknown name: $name"
}

## parse line and return list for graphene
proc parse_line {name ll} {
  ## Flowmeter*.log files, CH$n R*, CH$n T* files:
  ## file contains three comma-separated columns:
  ## date, time, value
  if {$name == {flow} || [regexp {^CH(\d+)} $name cc n]} {
    return [lindex $ll 2]
  }
}

########################################################################

set all_data_folders [glob -directory $main_folder ??-??-??]

foreach name $channels {
  set dbname "${dbprefix}/$name"
  if {$verb} {puts "updating: $dbname"}

  ## get max value
  set max [lindex [lindex [$db cmd get_prev $dbname] 0] 0]
  if {$verb} {puts " max: $max"}

  # choose only folders later or equal to maxdate
  if {$max!={}} {
    set maxdate [clock format [expr int($max)] -format "%y-%m-%d"]
    if {$verb} {puts " maxdate: $maxdate"}
    set data_folders {}
    foreach f $all_data_folders {
      if {[string compare "$f" "$main_folder/$maxdate"] >=0} {
        lappend data_folders $f
      }
    }
  } else {
    set data_folders $all_data_folders
  }

  foreach folder [lsort $data_folders] {
    if {$verb} {puts " folder: $folder"}

    foreach file [glob -nocomplain -directory $folder "[get_glob $name]"] {
      if {$verb} {puts " file: $file"}
      set ff [open $file]
      while {[gets $ff line]>-1} {
        # first two fields is a timestamp
        set ll [split $line {,}]
        set tstamp [clock scan "[lindex $ll 0] [lindex $ll 1]" -format "%d-%m-%y %H:%M:%S"]
        if {$tstamp <= $max} {continue}; #skip old data
        set data [parse_line $name $ll]
        # if {$verb} {puts "add $tstamp $data"}
        $db cmd put $dbname $tstamp {*}$data
      }
      close $ff
    }
    $db cmd sync $dbname
  }
}

}