########################################################################
# cm2gr -- parse CryoMech logfiles, put data into graphene database.
#   V.Zavjalov, 11.2018

# - read first timestamp from main_file (t0) and the last
#   timestamp in the database (t0db)
# - read the main file
# - if t0<t0db then read all other files in the folder
# While reading a file skip values older then t0db and values that
# are already in the database.


proc cm2gr {db dbprefix main_folder main_file {verb 1}} {



#set all_data_folders [glob -nocomplain -directory $main_folder ??-??-??]

set dbname "${dbprefix}compr"
set dbtype "FLOAT"

# create database if needed
if [catch {$db cmd info $dbname}] { $db cmd create $dbname $dbtype }

if {$verb} {puts "updating: $dbname"}

## get max value
set prev [lindex [$db cmd get_prev $dbname] 0]
set max  [lindex $prev 0]
if {$verb} {puts " db_max_time: $max"}


proc read_file {fname db dbname max verb} {
  ## open the main file
  if {$verb} {puts " file: $fname"}
  set ff [open $fname]
  set skipped 0
  while {[gets $ff line]>-1} {

    if {$line=={}} continue
    set ll [split $line "\t"]
    if {[llength $ll] <15} continue

    set tstamp [clock scan "[lindex $ll 0]" -format "%Y/%m/%d %H:%M:%S"]

    #skip old data
    if {$tstamp <= $max} {
      set skipped 1
      continue
    }

    # Parse line and put to DB
    # Use scan because numbers can have leading zeros,
    # it should be decimal, not octal
    set Pl [expr {[scan [lindex $ll  1] %d] + [lindex $ll  2]/10.0}]
    set Ph [expr {[scan [lindex $ll  3] %d] + [lindex $ll  4]/10.0}]
    set Twi [expr {[scan [lindex $ll  5] %d] + [lindex $ll  6]/10.0}]
    set Two [expr {[scan [lindex $ll  7] %d] + [lindex $ll  8]/10.0}]
    set Tg  [expr {[scan [lindex $ll  9] %d] + [lindex $ll 10]/10.0}]
    set To  [expr {[scan [lindex $ll 11] %d] + [lindex $ll 12]/10.0}]
    set MA  [expr {[scan [lindex $ll 13] %d] + [lindex $ll 14]/10.0}]

    # convert pressures psi->bar, temperatures F->C
    set Pl [expr {$Pl/14.504}]
    set Ph [expr {$Ph/14.504}]
    set Twi [expr {($Twi-32)*5.0/9.0}]
    set Two [expr {($Two-32)*5.0/9.0}]
    set Tg  [expr {($Tg-32)*5.0/9.0}]
    set To  [expr {($To-32)*5.0/9.0}]

    set data "$Pl $Ph $Twi $Two $Tg $To"
    if {$verb > 1} {puts " process data: $data"}
    $db cmd put $dbname $tstamp {*}$data
  }
  return $skipped
}


if {![read_file "$main_folder/$main_file" $db $dbname $max $verb]} {
  # if all the main_file is newer then DB, try to
  # find information in other files

  if {$verb} {puts " too old DB, try to find other files..."}
  foreach fname [glob -nocomplain -directory $main_folder "*"] {
    if {$fname == "$main_folder/$main_file"} continue
    read_file "$fname" $db $dbname $max $verb
  }

}
$db cmd sync $dbname

}
