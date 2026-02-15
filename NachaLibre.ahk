/*
	/=======================================================================\
	|NachaLibre
	|	A straightforward script for converting CSV payroll data into NACHA format for ACH transactions.
	|
	|	TODO:
	|		+Splitting the output into multiple files is lazy...
	|			+Instead, utilize the intended structure of the NACHA file, and just create multiple batches within the same file.
	|			+Yes, this would be a bit of a hassle to rewrite the NachaConstructor() function, but it would be worth it for the sake of better organization and cleaner output.
	|			+Then again, what if we were to just loop over each source CSV file in the intended input folder, and generate a separate NACHA file for each one?
	|			+That way we can keep the current structure of the NachaConstructor() function, and just have it generate multiple files based on the number of source CSV files.
	|			+Totally #TechnicalDebt, but it would be a quick and dirty way to implement the functionality without having to rewrite the entire NachaConstructor() function.
	|		+Implement optional Addenda Records for pay period info in employee bank statements.
	|		+Implement UX functionality like SFX/GUI elements.
	|		+Improve logging functionality for fiscal audit/analysis (i.e.: for 1099 reporting, or just general record-keeping).
	|
	|	Problems:
	|		+Nothing major yet. Just needs better functionality.
	|
	|	Ideas:
	|		+Use OutputDebug for logging to aid in debugging with tools like VS Code?
	|			+e.g.: OutputDebug A_Now ': Derp happened. Input file did not exist. Go Fish.'
	|			+But when script relaunches as admin, the new process' output wouldn't be visible in the original process' debug output, so maybe not worth it?
	|			+Maybe just use regular AHK logging for simplicity and reliability.
	|			+Then again, VS Code can just attach to the new process after the UAC relaunch, so maybe it would work after all? Worth testing.
	|		+Maybe some sort of employee lookup functionality, to catch errors in the CSV before generating the NACHA file.
	|			+i.e.: If an employee's name is misspelled, or if their routing number is wrong, it could cause the employee's transaction to be rejected by the bank. So maybe we could have some sort of reference file with correct employee info, and then cross-reference the CSV against that to catch any discrepancies before we generate the NACHA file.
	\=======================================================================/
*/

/*
	/=======================================================================\
	|Compiler Directives
	|	These commented lines are for the Ahk2Exe compiler. (They're ignored when running the script directly from source.)
	|	Windows Defender sometimes flags compiled AutoHotkey scripts as suspicious, so compiling can help with that.
	|	(I personally started using these directives after Windows Defender started nuking my scripts as false positives.)
	|	This especially comes in handy if you want to protect your source code from casual reverse-engineering.
	|	This entire section can be removed if you don't care about compilation. :)
	\=======================================================================/
*/

;@Ahk2Exe-Obey U_Bin,= "%A_BasePath~^.+\.%" = "bin" ? "Cont" : "Nop" ; .bin?
;@Ahk2Exe-Obey U_au, = "%A_IsUnicode%" ? 2 : 1 ; Base file ANSI or Unicode?
;@Ahk2Exe-PostExec "BinMod.exe" "%A_WorkFileName%"
;@Ahk2Exe-PostExec "MPRESS.exe" "%A_WorkFileName%" -q -x, 0,, 1
;@Ahk2Exe-%U_Bin%  "%U_au%2.>AUTOHOTKEY SCRIPT<. RANDOM"

/*
	/=======================================================================\
	|Script Settings
	|	These settings are for general environment parameters.
	\=======================================================================/
*/

;Ensure AHK is running on v2.0, as a 64-bit version.
#Requires AutoHotkey v2.0+ 64-bit
;Make sure only one running instance of the script exists at any given time.
#SingleInstance Force

;Ensure we have UAC permission to actually function.
;(Necessary for writing files to certain locations, and for other functions that require elevated permissions.)
#Include Libraries/UACCheck.ahk ;This library checks if the script is running with admin privileges, and if not, restarts the script with those privileges.

;Ensure the script has the ability to differentiate between virtual and physical input.
InstallKeybdHook true true

;Version & author of the script.
scriptVersion := "1.1.2"
scriptAuthor := "TrevorLaneRay"
;Create a little tray icon info.
A_IconTip := "NachaLibre v." . scriptVersion
A_ScriptName := "NachaLibre"
;Make a note of when the script was launched.
scriptLaunchTimestamp := A_Now

/*
	/=======================================================================\
	|Settings
	|	These settings are hard-coded parameters, replaced by any available in the .ini file.
	|	Adjust these to your specific use case.
	|	Most settings should be in the separate .ini file for customization after compilation.
	|	Keep in mind that if said .ini file does not yet exist, one will be created with these default values.
	\=======================================================================/
*/

;Ensure necessary folders exist for storing script files, icons, and logs.
DirCreate("ScriptFiles")
DirCreate("ScriptIcons")
DirCreate("ScriptLogs")

;This library autoexecutes, loading settings from the .ini file, or creating the .ini file with default settings if it doesn't already exist.
#Include Libraries/LoadSettingsFile.ahk

;Create folders for files based on the loaded settings from the .ini file (if not already created).
DirCreate(csvFileFolderName)
DirCreate(auditLogFileFolderName)
DirCreate(nachaFileFolderName)

;Make sure our icons are embedded in the compiled script.
;When the compiled version is run, it will deploy the icons to the ScriptIcons folder if they don't already exist.
;This can be ignored/removed if you're just running the script from source.
;It's necessary for the compiled version to redeploy the icons if missing.
FileInstall("ScriptIcons\ScriptIcon.ico", scriptIconFile, 1)
FileInstall("ScriptIcons\ActiveIcon.ico", scriptActiveIconFile, 1)
FileInstall("ScriptIcons\SuccessIcon.ico", scriptSuccessIconFile, 1)
FileInstall("ScriptIcons\ErrorIcon.ico", scriptErrorIconFile, 1)
FileInstall("ScriptIcons\WarningIcon.ico", scriptWarningIconFile, 1)
FileInstall("ScriptIcons\HungIcon.ico", scriptHungIconFile, 1)

;Make sure our tray icon is set to something appropriate, if the file exists. If not, log an error and continue without the icon.
if FileExist(scriptIconFile)
	TraySetIcon scriptIconFile
else if not FileExist(scriptIconFile)
	LogEvent("Error", "Couldn't load main script icon file.`nVerify that the icons are present for better indicators.")

LogEvent("Event", "Script launched. Version: " . scriptVersion . ". Author: " . scriptAuthor . ".`nSettings loaded from file: " . scriptSettingsFile)

/*
	/=======================================================================\
	|Hotkeys
	|	These hotkeys are for controlling the state of the script.
	|	These will work anywhere, not just in a specific window.
	|	Should be replaced later on by GUI buttons and such, but for now these are good for testing and basic functionality.
	\=======================================================================/
*/

#UseHook
Pause::Pause ;Panic button. Sometimes it's nice to just halt and catch fire.
+F12::Reload ;Restart the script, reloading settings from the .ini file.
^+F12::ExitApp ;Terminate the script immediately.
F10:: Run scriptSettingsFile ;Open the .ini file used for settings.

F11:: ;Main functionality.
{
	;Read the target CSV file into the script.
	inputFilePath := csvFileFolderName . "\" . csvFileName
	ReadCSVFile(inputFilePath)

	;Output the processed CSV data into Nacha format.
	NachaConstructor()
	return
}

/*
	/=======================================================================\
	|Library FunctionInclusions
	|	Modular functions that are more easily maintained in separate files, included here for calling in the main script.
	\=======================================================================/
*/

#Include Libraries/LogEvent.ahk ;LogEvent() is a simple function for appending diagnostic information to a log file, with timestamps and event types for easier debugging and analysis.
#Include Libraries/ReadCSVFile.ahk ;ReadCSVFile() parses the target CSV file, line by line, field by field, and stores the data in arrays for later use in constructing the Nacha file.
#Include Libraries/NachaConstructor.ahk ;NachaConstructor() takes the data parsed from the CSV file, and constructs a properly formatted Nacha file based on that data, as well as the settings specified in the .ini file.