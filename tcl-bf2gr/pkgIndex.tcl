# Tcl package index file
# This file is NOT generated by the "pkg_mkIndex" command 

set _name    bf2gr
set _version 1.0
set _files   {bluefors magnicon gr2gr cryomech fmi_weather rota lanc_press}

set _pcmd {}
foreach _f $_files { lappend _pcmd "source [file join $dir $_f.tcl]" }
lappend _pcmd "package provide $_name $_version"
package ifneeded $_name $_version [join $_pcmd \n]

