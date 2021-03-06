########################################################################
# bf2gr -- parse Bluefors logfiles, put data into graphene database.
#   V.Zavjalov, 05.2017

proc bf2gr {db dbprefix main_folder channels {verb 1}} {

########################################################################
## database types
proc get_dbtype {name} {
  if {$name == {flow} || $name == {gauge} ||\
      [regexp {^CH(\d+)[RT]} $name]}  {return {FLOAT}}
  if {$name == {chan}}  {return {TEXT}}
  error "unknown channel name: $name"
}


## which files correspond to a database
proc get_glob {name} {
  if {$name == {flow}}  {return {Flowmeter*.log}}
  if {$name == {gauge}} {return {?axigauge*.log}}
  if {$name == {chan}}  {return {Channels*.log}}
  if {[regexp {^CH(\d+)R} $name cc n]}  {return "CH$n R*.log"}
  if {[regexp {^CH(\d+)T} $name cc n]}  {return "CH$n T*.log"}
  error "unknown channel name: $name"
}

## parse line and return list for graphene
proc parse_line {name ll} {
  ## Flowmeter*.log files, CH$n R*, CH$n T* files:
  ## file contains three comma-separated columns:
  ## date, time, value
  if {$name == {flow} || [regexp {^CH\d+[RT]} $name]} {
    return $ll
  }
  ## maxigauge*.log files
  ## contain date, time and channel records with 6 fields each:
  ##  channel name, var name, enable, val, ?, ?
  if {$name == {gauge}} {
    set ret {}
    foreach {n d e v x1 x2} $ll { lappend ret $v}
    return [join $ret " "]
  }
  ## Channels*.log files
  ## join the list back to csv
  if {$name == {chan}} {
    return [join $ll ","]
  }
  error "unknown channel name: $name"
}

########################################################################

set all_data_folders [glob -nocomplain -directory $main_folder ??-??-??]

foreach name $channels {
  set dbname "${dbprefix}${name}"

  # check that we know this name, get db type
  set dbtype [get_dbtype $name]

  # create database if needed
  if [catch {$db cmd info $dbname}] { $db cmd create $dbname $dbtype }

  if {$verb} {puts "updating: $dbname"}

  ## get max value
  set prev [lindex [$db cmd get_prev $dbname] 0]
  set max  [lindex $prev 0]
  set maxv [lreplace $prev 0 0]; # list of all values
  if {$verb} {puts " max: $max <$maxv>"}

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
        set line [string map {"\0" ""} $line]
        set line [string map {"\"" ""} $line]
        if {$line=={}} continue
        set ll [split $line {,}]
        set tstamp [clock scan "[lindex $ll 0] [lindex $ll 1]" -format "%d-%m-%y %H:%M:%S"]
        if {$tstamp <= $max} {continue}; #skip old data
        set ll [lreplace $ll 0 1]
        set data [parse_line $name $ll]

        # do not put repeated values
        # (BF program can log data faster then cryobridge measure it)
        set do_skip 1
        foreach A $data B $maxv {
          if {[catch {set diff [expr abs($A-$B)]}]} {
            # non-numerial
            if {$A!=$B} {set do_skip 0; break}
          } else {
            # numerical
            if {$diff > 1e-6*abs($A)} {set do_skip 0; break}
          }
        }
        if {$verb > 1} {puts " process data: <$line> skip: $do_skip"}
        if {$do_skip} { continue }

        # if {$verb} {puts "  add $tstamp $data"}
        $db cmd put $dbname $tstamp {*}$data
        set maxv $data
      }
      close $ff
    }
    $db cmd sync $dbname
  }
}

}

# update dbprefix/events database using dbprefix/chan
proc bf2gr_ev {db dbprefix {verb 1}} {


  set dbname_c "${dbprefix}chan"
  set dbname_e "${dbprefix}events"

  # create event database if needed
  if [catch {$db cmd info $dbname_e}] { $db cmd create $dbname_e TEXT }

  if {$verb} {puts "updating $dbname_e using $dbname_c"}

  ## find last timestamp in the event database
  ## increase it by 0.1s to skip existing record
  set max [lindex [lindex [$db cmd get_prev $dbname_e] 0] 0]
  if {$verb} {puts " max: $max"}
  set max [expr $max+0.1]

  ## get last state for this timestamp
  set state_pr [lreplace [lindex [$db cmd get_prev $dbname_c $max] 0] 0 0]

  ## read all newer states, calculate difference, put into event db
  foreach line [$db cmd get_range $dbname_c $max inf] {
    set tstamp [lindex $line 0]
    set state [lreplace $line 0 0]
    if {$state_pr != {}} {
      ## find difference between two states
      set l1 [lreplace [split $state_pr ","] 0 0]
      set l2 [lreplace [split $state ","] 0 0]
      foreach {n1 v1} $l1 {n2 v2} $l2 {
        if {$n1 != $n2} {puts "Error in chan file: $n1 != $n2!"}
        if {$v1 != $v2} {
           if     {$v1==1 && $v2==0} {set msg "$n1 off"}\
           elseif {$v1==0 && $v2==1} {set msg "$n1 on"}\
           else   {set msg "$n1 $v1->$v2"}
           if {$verb} {puts "  add $tstamp $msg"}
           $db cmd put $dbname_e $tstamp {*}$msg
        }
      }
    }
    set state_pr $state
  }

}
