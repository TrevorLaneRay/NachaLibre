/*
	/=======================================================================\
	|NachaLibre
	|	A straightforward script for converting CSV payroll data into NACHA format for ACH transactions.
	|	TODO:
	|		+Break out individual functions into separate .ahk files for organization, and to allow users to more easily edit specific functionality.
	|		+Auto-split nacha output file into two parts if exceeds max amount.
	|			+Should set the "Part2" to be transacted on transactionDayOffset+1.
	|			+Recursively loop into additional parts for amounts exceeding double max amount.
	|			+Also, maybe a "headroom" amount can be set in the .ini file, so that there is wiggle room for unexpected transactions that might cause the total to exceed the max amount after the file is generated, but before it's sent to the bank.
	|		+Implement Addenda Records for pay period info in employee bank statements.
	|		+Implement UX improvements like SFX/GUI elements.
	|		+Improve logging functionality for audit/analysis.
	|		+Brainstorm any other useful ideas.
	|		+Use OutputDebug for logging to aid in debugging with tools like VS Code?
	|			+e.g.: OutputDebug A_Now ': Derp happened. Input file did not exist. Go Fish.'
	|	Problems:
	|		+Nothing major yet. Just needs better functionality.
	|	Ideas:
	|		+Some way to encode/decode icons as Base64, so that the script can generate its own icons if they're missing, rather than just logging an error and leaving the user without any visual indicators.
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
scriptVersion := "1.0.3"
scriptAuthor := "TrevorLaneRay"
;Create a little tray icon info.
A_IconTip := "NachaLibre v." . scriptVersion
A_ScriptName := "NachaLibre"
;Make a note of when the script was launched.
scriptLaunchTimestamp := A_Now

/*
	/=======================================================================\
	|File Settings
	|	These settings are hard-coded parameters, replaced by any available in the .ini file.
	|	Adjust these to your specific use case.
	|	Most settings should be in the separate .ini file for customization after compilation.
	|	Keep in mind that if said .ini file does not yet exist, one should be created with these default values.
	\=======================================================================/
*/

;File/Folder Settings
DirCreate("ScriptFiles")
DirCreate("ScriptIcons") ;In the future, we should probably have some way to download default icons if they're missing.
DirCreate("ScriptLogs")

scriptSettingsFile := "ScriptFiles\OriginalSettingsFile.ini" ;Initial loading of the original settings file. (A different file can be specified in this .ini)
scriptLogFile := "ScriptLogs\ScriptLog.log" ;Make sure we have somewhere to dump diagnostic info to.

scriptIconFile := "ScriptIcons\ScriptIcon.ico"
if FileExist(scriptIconFile)
	TraySetIcon scriptIconFile
else if not FileExist(scriptIconFile)
	LogEvent("Error", "Couldn't load main script icon file.`nVerify that the icons are present for better indicators.")
scriptActiveIconFile := "ScriptIcons\ScriptActiveIcon.ico"
if not FileExist(scriptActiveIconFile)
	LogEvent("Error", "Couldn't load active script icon file.`nVerify that the icons are present for better indicators.")
scriptSuccessIconFile := "ScriptIcons\ScriptSuccessIcon.ico"
if not FileExist(scriptSuccessIconFile)
	LogEvent("Error", "Couldn't load script success icon file.`nVerify that the icons are present for better indicators.")
scriptErrorIconFile := "ScriptIcons\ScriptErrorIcon.ico"
if not FileExist(scriptErrorIconFile)
	LogEvent("Error", "Couldn't load script error icon file.`nVerify that the icons are present for better indicators.")
scriptHungIconFile := "ScriptIcons\ScriptHungIcon.ico"
if not FileExist(scriptHungIconFile)
	LogEvent("Error", "Couldn't load hung script icon file.`nVerify that the icons are present for better indicators.")


	;Loading logic to read the .ini file if it already exists.
	;We'll start loading settings from .ini file, using a default value if it's missing from the file.)
	;Note that the script will create its OriginalSettingsFile.ini if not present, but if that file exists and specifies a different file, we'll proceed with that instead.
	scriptSettingsFile := IniRead(scriptSettingsFile, "ScriptSettings", "SettingsFileLocation", "ScriptFiles\OriginalSettingsFile.ini") ;Where this .ini file should be stored.

	scriptSettingsTimestamp := IniRead(scriptSettingsFile, "SettingsInfo", "SettingsFileCreationTimestamp", A_Now) ;When this settings file was created.
	scriptSettingsVersion := IniRead(scriptSettingsFile, "SettingsInfo", "SettingsFileCreationVersion", scriptVersion) ;What version of the script was used to generate the settings file.
	scriptSettingsAuthor := IniRead(scriptSettingsFile, "SettingsInfo", "SettingsFileCreationAuthor", scriptAuthor) ;Who created/modified the settings file.
	scriptLogFile := IniRead(scriptSettingsFile, "ScriptSettings", "ScriptLogFileLocation", "ScriptLogs\ScriptLog.log") ;Where the script should append diagnostic log entries to.
	scriptIconFile := IniRead(scriptSettingsFile , "ScriptSettings", "ScriptIconFile", "ScriptIcons\ScriptIcon.ico") ;Icon indicating that the script is idle, and ready.
	scriptActiveIconFile := IniRead(scriptSettingsFile, "ScriptSettings", "ScriptActiveIconFile", "ScriptIcons\ScriptActiveIcon.ico") ;Icon indicating that the script is performing functions.
	scriptSuccessIconFile := IniRead(scriptSettingsFile, "ScriptSettings", "ScriptSuccessIconFile", "ScriptIcons\ScriptSuccessIcon.ico") ;Icon indicating that a task has completed successfully.
	scriptErrorIconFile := IniRead(scriptSettingsFile, "ScriptSettings", "ScriptErrorIconFile", "ScriptIcons\ScriptErrorIcon.ico") ;Icon indicating that an error has occurred.
	scriptHungIconFile := IniRead(scriptSettingsFile, "ScriptSettings", "ScriptHungIconFile", "ScriptIcons\ScriptHungIcon.ico") ;Icon indicating that something is in progress, but is waiting on something.

if not FileExist(scriptSettingsFile)
{
	;Creation logic to write a default .ini file if it does not already exist.
	;If the file does not exist, these hard-coded values will be used to construct it.

	;Script Variables Initialization (For putting hard-coded values into the .ini file.)
	IniWrite(scriptSettingsFile, scriptSettingsFile, "ScriptSettings", "SettingsFileLocation") ;Where this .ini file should be stored.
	IniWrite(A_Now, scriptSettingsFile, "SettingsInfo", "SettingsFileCreationTimestamp") ;When this settings file was created.
	IniWrite(scriptVersion, scriptSettingsFile, "SettingsInfo", "SettingsFileCreationVersion") ;What version of the script was used to generate the settings file.
	IniWrite(scriptAuthor, scriptSettingsFile, "SettingsInfo", "SettingsFileCreationAuthor") ;Who created the settings file.
	IniWrite(scriptLogFile, scriptSettingsFile, "ScriptSettings", "ScriptLogFileLocation") ;Where the script should append diagnostic log entries to.
	IniWrite(scriptIconFile, scriptSettingsFile , "ScriptSettings" , "ScriptIconFile") ;Icon indicating that the script is idle, and ready.
	IniWrite(scriptActiveIconFile, scriptSettingsFile, "ScriptSettings", "ScriptActiveIconFile") ;Icon indicating that the script is performing functions.
	IniWrite(scriptSuccessIconFile, scriptSettingsFile, "ScriptSettings", "ScriptSuccessIconFile") ;Icon indicating that a task has completed successfully.
	IniWrite(scriptErrorIconFile, scriptSettingsFile, "ScriptSettings", "ScriptErrorIconFile") ;Icon indicating that an error has occurred.
	IniWrite(scriptHungIconFile, scriptSettingsFile, "ScriptSettings", "ScriptHungIconFile") ;Icon indicating that something is in progress, but is waiting on something.
	LogEvent("Notice", "An original .ini settings file was not found.`nA new one has been made, and saved here:`n" . scriptSettingsFile . "`n`nNote: If you want to use a different settings file, edit the original settings file to point to it.")
}

/*
	/=======================================================================\
	|NACHA Settings
	|	These settings are specific to NACHA functionality.
	|		This reads/writes these files from the .ini, or writes defaults to the .ini if not already present.
	\=======================================================================/
*/

;File/Folder Settings
csvFileFolderName := IniRead(scriptSettingsFile, "FileAndFolderSettings", "CSVFileFolderName", "SourceCSVs") ;The default name of the CSV file to import.
csvFileName := IniRead(scriptSettingsFile, "FileAndFolderSettings", "CSVFileName", "Part01.csv") ;The default name of the CSV file to import.
nachaFileFolderName := IniRead(scriptSettingsFile, "FileAndFolderSettings", "NachaOutputFolderName", "NachaOutput") ;Name for the folder in which to place finalized, validated Nacha files.
nachaFileName := IniRead(scriptSettingsFile, "FileAndFolderSettings", "NachaOutputFileName", "NachaFile") ;Name of the Nacha file to save.
auditLogFileFolderName := IniRead(scriptSettingsFile, "FileAndFolderSettings", "AuditLogFolderName", "AuditLogs") ;Name for the folder in which to store streamlined logs for fiscal audits.
auditLogFileName := IniRead(scriptSettingsFile, "FileAndFolderSettings", "AuditLogFileName", "AuditLog") ;Name of the file in which streamlined transaction logs are stored.

;Write File/Folder Settings back to .ini file, ensuring all are accounted for.
IniWrite(csvFileFolderName, scriptSettingsFile, "FileAndFolderSettings", "CSVFileFolderName") ;The default name of the CSV file to import.
IniWrite(csvFileName, scriptSettingsFile, "FileAndFolderSettings", "CSVFileName") ;The default name of the CSV file to import.
IniWrite(nachaFileFolderName, scriptSettingsFile, "FileAndFolderSettings", "NachaOutputFolderName") ;Name for the folder in which to place finalized, validated Nacha files.
IniWrite(nachaFileName, scriptSettingsFile, "FileAndFolderSettings", "NachaOutputFileName") ;Name of the Nacha file to save.
IniWrite(auditLogFileFolderName, scriptSettingsFile, "FileAndFolderSettings", "AuditLogFolderName") ;Name for the folder in which to store streamlined logs for fiscal audits.
IniWrite(auditLogFileName, scriptSettingsFile, "FileAndFolderSettings", "AuditLogFileName") ;Name of the file in which streamlined transaction logs are stored.

;Create folders for files based on the above specified settings in the .ini file (if not already created).
DirCreate(csvFileFolderName)
DirCreate(auditLogFileFolderName)
DirCreate(nachaFileFolderName)

;Payroll Settings (Static, shouldn't change often, best saved to/retrieved from .ini file.)
maxPayrollAmount := IniRead(scriptSettingsFile, "PayrollSettings", "MaximumPayrollAmount", 500000) ;Upper limit of dollars at which to split Nacha submissions (dependent on bank).
payrollBankName := IniRead(scriptSettingsFile, "PayrollSettings", "BankName", "JPMORGAN CHASE") ;Name of the bank the payroll will be sent from.
payrollCompanyName := IniRead(scriptSettingsFile, "PayrollSettings", "CompanyName", "ABC CARE LLC") ;Name of your company. Needs to be upper case. A-Z, space, and periods, max 23 chars.
payrollRecipientCompanyName := IniRead(scriptSettingsFile, "PayrollSettings", "CompanyNameOnStatements", "ABC Care LLC") ;Name of your company. (Same as above, but will be what appears in an employee's bank statement. Max 16 chars.)
payrollRoutingNumber := IniRead(scriptSettingsFile, "PayrollSettings", "PayrollRoutingNumber", "000000000") ;9-digit routing number of bank from which the payroll will be withdrawn. (Lead with zeros if less than 9 chars.)
payrollAccountNumber := IniRead(scriptSettingsFile, "PayrollSettings", "PayrollAccountNumber", "000000000") ;Account number from which the payroll will be withdrawn.
payrollEIN := IniRead(scriptSettingsFile, "PayrollSettings", "CompanyTaxEIN", "0000000000") ;String to identify the business entity for tax purposes. (Chase specifications say to put zeros??)

;Write static Payroll Settings back to .ini file, ensuring all are accounted for.
IniWrite(maxPayrollAmount, scriptSettingsFile, "PayrollSettings", "MaximumPayrollAmount") ;Upper limit of dollars at which to split Nacha submissions (dependent on bank).
IniWrite(payrollBankName, scriptSettingsFile, "PayrollSettings", "BankName") ;Name of the bank the payroll will be sent from.
IniWrite(payrollCompanyName, scriptSettingsFile, "PayrollSettings", "CompanyName") ;Name of your company. Needs to be upper case. A-Z, space, and periods, max 23 chars.
IniWrite(payrollRecipientCompanyName, scriptSettingsFile, "PayrollSettings", "CompanyNameOnStatements") ;Name of your company. (Same as above, but will be what appears in an employee's bank statement. Max 16 chars.)
IniWrite(payrollRoutingNumber, scriptSettingsFile, "PayrollSettings", "PayrollRoutingNumber") ;9-digit routing number of bank from which the payroll will be withdrawn. (Lead with zeros if less than 9 chars.)
IniWrite(payrollAccountNumber, scriptSettingsFile, "PayrollSettings", "PayrollAccountNumber") ;Account number from which the payroll will be withdrawn.
IniWrite(payrollEIN, scriptSettingsFile, "PayrollSettings", "CompanyTaxEIN") ;String to identify the business entity for tax purposes. (Chase specifications say to put zeros??)

;Payroll Settings (Variable. Should optimally be obtained from user during runtime, rather than read from the .ini file.)
;If these date values are not present in the .ini file, they will be calculated here by default.
;These default values can be used during user prompt to simplify date selection by pre-selecting a date close to what it should be.
payPeriodBeginOffset := IniRead(scriptSettingsFile, "PayrollSettings", "PayPeriodBeginOffset", -15) ;Read the pay period's beginning date offset from .ini settings, or use default if absent.
IniWrite(payPeriodBeginOffset, scriptSettingsFile, "PayrollSettings", "PayPeriodBeginOffset") ;Write the pay period's beginning date offset back to the file, creating the entry from default if absent.
payPeriodBegin := DateAdd(A_Now, payPeriodBeginOffset, "days") ;Date that the pay period began. (By default, two weeks ago).

payPeriodEndOffset := IniRead(scriptSettingsFile, "PayrollSettings", "PayPeriodEndOffset", -2) ;Read the pay period's end date offset from .ini settings, or use default if absent.
IniWrite(payPeriodEndOffset, scriptSettingsFile, "PayrollSettings", "PayPeriodEndOffset") ;Write the pay period's end date offset back to the file, creating the entry from default if absent.
payPeriodEnd := DateAdd(A_Now, PayPeriodEndOffset, "days") ;Date that the pay period ended. (By default, two days ago).

payDayOffset := IniRead(scriptSettingsFile, "PayrollSettings", "PayDayOffset", 1) ;Read the pay day's offset from .ini settings, or use default if absent.
IniWrite(payDayOffset, scriptSettingsFile, "PayrollSettings", "PayDayOffset") ;Write the pay day's offset back to the file, creating the entry from default if absent.
payDay := FormatTime(DateAdd(A_Now, payDayOffset, "days"),"MMM dd") ;Descriptive date that payday is (Assuming this is tomorrow).

transactionDayOffset := IniRead(scriptSettingsFile, "PayrollSettings", "TransactionDayOffset", 1) ;Read the transaction date's offset from .ini settings, or use default if absent.
IniWrite(transactionDayOffset, scriptSettingsFile, "PayrollSettings", "TransactionDayOffset") ;Write the transaction date offset back to the file, creating the entry from default if absent.
transactionDay := FormatTime(DateAdd(A_Now, transactionDayOffset, "days"), "yyMMdd") ;Day that the bank transaction should occur (Assuming this is tomorrow).

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