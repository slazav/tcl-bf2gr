## bf2gr -- parse Bluefors logfiles, put data into graphene database

#### Usage:
```tcl
  package require Device
  package require bf2gr

  # Open database device - it should be configured
  # in the Device library configuration file:
  Device db

  # Define some variables:
  # Location of the cryostat logfiles:
  set main_folder "/mnt/cryo_logs"

  # Database prefix:
  set dbprefix "cryo"

  # Channels we want to update.
  # Don't forget to create all needed databases (cryo/flow etc.) first
  set channels {flow  CH1R CH1T CH2R CH2T   CH5R CH5T CH6R CH6T CH7R CH7T }

  # verbosity level
  set verb 1

  # run th  update
  bf2gr db $dbprefix $main_folder $channels $verb
```

Only data newer then the last database record are read. Function can be
run regularly to update the database.

#### Parameters:
* db          -- database device (see Device package)
* dbprefix    -- database prefix; data goes into <dbprefix>/<channel> database
* main_folder -- folder with data
* channels    -- name of channels to process
* verb        -- verbosity level: 0-1

#### Supported channels:
* flow  -- parse Flowmeter*.log files
* CH<N>R -- parse CH<N> R*.log file
* CH<N>T -- parse CH<N> R*.log file

#### TODO:
* chan  -- Channels*.log files (not supported yet!)
* gauge -- parse Maxigauge*.log files (not supported yet!)
