########################################################################
# magnicon2gr -- parse Magnicon logfiles, put data into graphene database.
#   V.Zavjalov, 08.2017

proc magnicon2gr {db dbprefix main_folder channels {verb 1}} {

########################################################################
## database types
proc get_dbtype {name} {
  if {$name == {temp}}  {return {FLOAT}}
  error "unknown channel name: $name"
}

## which files correspond to a database
proc get_glob {name} {
  if {$name == {temp}}  {return {*.tmf}}
  error "unknown channel name: $name"
}

## parse line and return list for graphene
proc parse_line {name ll} {
    return $ll
}

## extract time from filename
proc f2t {name} {
  set tt {}
  regexp {(\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2})} $name tt
  if {$tt=={}} {
    regexp {(\d{4}-\d{2}-\d{2})} $name tt
    return [clock scan $tt -format "%Y-%m-%d"]
  }
  if {$tt=={}} {
    error "Unknown file name: $name"
  }
  return [clock scan $tt -format "%Y-%m-%d_%H-%M-%S"]
}

########################################################################


foreach name $channels {

  set all_data_files [glob -nocomplain -directory $main_folder "[get_glob $name]"]
  set dbname "${dbprefix}_${name}"

  # check that we know this name, get db type
  set dbtype [get_dbtype $name]

  # create database if needed
  if [catch {$db cmd info $dbname}] { $db cmd create $dbname $dbtype }

  if {$verb} {puts "updating: $dbname"}

  ## get max value
  set max [lindex [lindex [$db cmd get_prev $dbname] 0] 0]
  if {$verb} {puts " max: $max"}

  # choose one early file and all later files
  set oldfile {}
  if {$max!={}} {
    set data_files {}
    foreach f $all_data_files {
      set t1 [f2t $f]

      if {$t1>$max } { lappend data_files $f }\
      else { set oldfile $f
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
    set t0 [f2t $file]
    set state "old"

    set ff [open $file]
    while {[gets $ff line]>-1} {
      set line [string map {"," "."} $line]
      set line [string map {"\0" ""} $line]
      set line [string map {"\"" ""} $line]

      # if there is a timestamp, extract time and change state
      if {[llength $line] ==1 } {
        set tst [clock scan $line -format "%Y-%m-%d_%H-%M-%S"]
        set state "tstamp"
      }

      # data lines contains 3 columns
      if {[llength $line] !=3 } continue
      if {$state == "old" } continue

      if {$state == "tstamp" } {
        set tsh [lindex $line 0]
        set state "new"
      }

      # first field is a timestamp
      set tt [expr $tst-$tsh+[lindex $line 0]]
      if {$tt > $max} {
        $db cmd put $dbname [expr $tst-$tsh+[lindex $line 0]] [lrange $line 1 end]
      }
    }
    close $ff
    $db cmd sync $dbname
  }
}

}

