%define teaname bf2gr
%define major 1.0

Name: tcl-%teaname
Version: 1.0
Release: alt1
BuildArch: noarch

Summary: parse Bluefors/Magnicon/CryoMech logfiles, put data into graphene database
Group: System/Libraries
Source: %name-%version.tar
License: Unknown

Requires: tcl

%description
Collect data drom different sources and put into graphene DB:
* BlueFors cryostat logfiles
* CryoMech compressor logfiles
* Magnicon TempViewer logfiles
* FMI weather data
* ROTA bindat/fork/log files

%prep
%setup -q

%install
mkdir -p %buildroot/%_tcldatadir/%teaname%major
install *.tcl %buildroot/%_tcldatadir/%teaname%major

%files
%dir %_tcldatadir/%teaname%major
%_tcldatadir/%teaname%major/*.tcl

%changelog
