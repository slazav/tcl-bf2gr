########################################################################
# gr2gr -- syncronize graphene databases
# Works only for new added values.
#   V.Zavjalov, 11.2017

package require Device

proc gr2gr {src dst db {verb 1}} {

  if {$verb} {puts "gr2gr: copy $db from $src to $dst"}

  # get src database info (error will be proccessed correctly)
  set ret [lindex [$src cmd info $db] 0]
  set src_type  [lindex $ret 0]
  set src_descr [lrange $ret 1 end]

  # try to get dst database info
  if {[catch {set ret [lindex [$dst cmd info $db] 0]}]} {
    # in case of error try to create database
    $dst cmd create $db $src_type $src_descr
  }

  set dst_type  [lindex $ret 0]
  set dst_descr [lrange $ret 1 end]

  # if types are different it is an error
  if {$src_type != $dst_type} {error "wrong DB type"}

  # if descriptions are different, just update dst description
  if {$src_descr != $dst_descr} {$dst cmd "set_descr $db $src_descr"}

  # get last timestamp in dst database:
  set t1 [lindex [lindex [$dst cmd get_prev $db] 0] 0]
  if {$t1=={}} {set t1 0}

  if {$verb} {puts " t1: $t1"}

  # transer values later then t1
  set i 0
  foreach line [$src cmd get_range $db $t1] { $dst cmd put $db $line; incr i}
  if {$verb} {puts " add $i records"}

}

