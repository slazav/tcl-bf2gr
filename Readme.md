## bf2gr <db> <dbprefix> <main_folder> <channels> <verb>

Parse Bluefors logfiles, put data into graphene database.

Only data newer then the last database record are read. Function can be
run regularly to update the database.

#### Parameters:
* db          -- database device (see Device package)
* dbprefix    -- database prefix; data goes into <dbprefix>/<channel> database
* main_folder -- folder with data
* channels    -- name of channels to process
* verb        -- verbosity level: 0-1

#### Supported channels:
* flow   -- parse Flowmeter*.log files
* CH`<N>`R -- parse CH`<N>` R*.log file
* CH`<N>`T -- parse CH`<N>` R*.log file
* chan   -- Channels*.log files
* gauge  -- parse Maxigauge*.log files

## bf2gr_ev

Update event database from chan database

The `chan` database contains cryostat state, which is is recorded after
any change. It is a list of all valves and pumps followed by 0 or 1.
Function bf2gr_ev updates a new human-readable database `event`, where
messages look like "turbo on", "v14 off" etc.

---
## Usage:
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
  # Databases will be created if needed.
  set channels {chan flow  CH1R CH1T CH2R CH2T   CH5R CH5T CH6R CH6T CH7R CH7T }

  # verbosity level
  set verb 1

  # run the update of all databases
  bf2gr db $dbprefix $main_folder $channels $verb

  # Update event database (it will be created if needed)
  bf2gr_ev db $dbprefix

```


