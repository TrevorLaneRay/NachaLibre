# Changelog
## v1.0.3
### Added or Changed
- Started moving core functions to separate [libraries](Libraries) for better modularity/organization.
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
