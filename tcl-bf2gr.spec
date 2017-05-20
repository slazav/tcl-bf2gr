%define teaname bf2gr
%define major 1.0

Name: tcl-%teaname
Version: 1.0
Release: alt1
BuildArch: noarch

Summary: parse Bluefors logfiles, put data into graphene database
Group: System/Libraries
Source: %name-%version.tar
License: Unknown

Requires: tcl

%description
bf2gr -- parse Bluefors logfiles, put data into graphene database

%prep
%setup -q

%build
mkdir -p %buildroot/%_tcldatadir/%teaname%major
install *.tcl %buildroot/%_tcldatadir/%teaname%major

%files
%dir %_tcldatadir/%teaname%major
%_tcldatadir/%teaname%major/*.tcl

%changelog
