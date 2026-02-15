# Changelog
## v1.1.2
### Added or Changed
- Changed NachaConstructor()'s output file name to be csvFileName - timeDateStamp format.
- Added input/output filenames to log entries for completed NachaConstructor() runs.

## v1.1.1
### Added or Changed
- Tweaked .gitignore to prevent accidental push of sensitive files.
- Adjusted LogEvent() to have a blank line in between each log entry for readability.
- Added compiler instruction to include icons in the compiled executable.
 - Executable is now fully capable of self-deploying all necessary files as a standalone program. 🥳  
 (This means you should probably put it somewhere production-ready, and not in your freakin' Downloads folder.)  
 (Make a folder on your Desktop, and stick it in there perhaps?)

## v1.1.0
### Added or Changed
- Finished refactoring script to offload most functions to libraries.
- Overhauled the loading of the settings file to be more... sane.
    - Now the script can cleanly create a default settings file from scratch.
    - If a new default settings file was created in its absence, it will now automatically open for quick, easy editing.
    - (Still deciding on a way to ensure all settings fields are present in the file, to handle if they're absent.)
- Simplified icon names.
- Fixed LogEvent() not checking to make sure a tray icon file exists before attempting to set it.
- Moved dates' calculations for pay periods, payday and transaction day to NachaConstructor(), instead of being in the main file. 

## v1.0.3
### Added or Changed
- Started sorting core functions into separate [libraries](Libraries) for better modularity/organization.
- Started working on [functions to encode icons](Libraries/IconEncoder.ahk) to Base64 for default icon deployment from executable. (Decoding will come later.)

## v1.0.2
### Added or Changed
- Added an error handler to panic if a routing number isn't 9 digits long. (Fixed in commit 3e11354)
    - This can happen if Excel removes a leading 0 or the account/routing number columns get transposed, or a typo.
    - Recompiled [executable](NachaLibre.exe) to reflect this version.
- Corrected [SampleCSV.csv](SourceCSVs/SampleCSV.csv); the account/routing number columns were switched.
- Added an [Excel spreadsheet version](SourceCSVs/SampleCSV.xlsx) of the sample CSV for ease of use.
### Removed
- Removed broken version of example CSV.

## v1.0.1
### Added or Changed
- New icons.
- Added ReadMe mention of F10 hotkey for quick opening of script's settings.
### Removed
- Old version's icons didn't feel right, so replaced.
- Duplicate keyboard hook on line 63 removed. (Unsure how I duplicated that.)

## v1.0.0
### Added or Changed
- Initial commit of first working version.
- Added this changelog.
- Added ReadMe.
- Decided on using CC0 1.0 Universal for licensing.
- Started using VSCode for development, instead of SciTE4AHK.
- Added placeholder icons for display in tray. (Will change later.)
- Split most hard-coded settings to separate .ini file (useful for compiled versions).
### Removed
- Destroyed old repo with 0.x alpha.
- Original prototype and ancillary files.
