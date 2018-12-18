########################################################################
# weather -- parse weather data from FMI, put into graphene database.
#   V.Zavjalov, 12.2018

# fmisid according to https://en.ilmatieteenlaitos.fi/observation-stations
# par: http://opendata.fmi.fi/meta?observableProperty=observation&language=eng

package require http
proc weather {db dbprefix fmisid par {verb 1}} {

  set dbname "${dbprefix}_${par}"
  set dbtype "float"

  # create database if needed
  if [catch {$db cmd info $dbname}] { $db cmd create $dbname $dbtype }
  if {$verb} {puts "updating: $dbname"}

  ## get max value
  set prev [lindex [$db cmd get_prev $dbname] 0]
  set tmax  [lindex $prev 0]
  set tcur  [clock seconds]

  if {$verb} {puts " db_max_time: $tmax"}
  if {$tmax == ""} {set tmax [clock scan "2013-12-01"]}
  set tmax  [expr int($tmax)]

  ## update every 30 min
  #if {$tcur-$tmax < 600*3} return

  set base "http://opendata.fmi.fi/wfs?service=WFS&version=2.0.0&request=getFeature"
  set qu  "storedquery_id=fmi::observations::weather::timevaluepair"
  set st  "timestep=10"

  # update
  set maxstep [expr 3600*24*6]
  for {set t1s $tmax} {$t1s<$tcur} {set t1s [expr $t1s+$maxstep]} {
    set t2s [expr $t1s+$maxstep]

    set t1 [clock format $t1s -format "%Y-%m-%dT%H:%M:%SZ"]
    set t2 [clock format $t2s -format "%Y-%m-%dT%H:%M:%SZ"]
    set url "$base&$qu&fmisid=$fmisid&$st&starttime=$t1&endtime=$t2&parameters=$par"

    if {$verb} {puts "$par: $t1 -- $t2"}
    set token [::http::geturl $url]
    upvar #0 $token state

    if {[regexp "<wml2:MeasurementTimeseries gml:id=\"obs-obs-1-1-$par\">.*<\/wml2:MeasurementTimeseries>" $state(body) a]<1} {
      if {[regexp "ExceptionReport" $state(body)]} {
        puts "$state(body)"
        puts "ERROR: $par"
        puts "URL: $url"
        return
      }
      # skip empty data
      continue
    }

    set data [regexp -all -inline -- {<wml2:time>([0-9A-Z:-]+)<\/wml2:time>\s+<wml2:value>([0-9.-]+)<\/wml2:value>} $a]
      foreach {x t v} $data {
      set tim [clock scan $t -format "%Y-%m-%dT%H:%M:%SZ"]
      if {$verb > 1} {puts " process data: $tim $v"}
      $db cmd put $dbname $tim $v
    }
    $db cmd sync $dbname
  }
}
