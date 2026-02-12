/*
	/=======================================================================\
	|NachaLibre
	|	A straightforward script for converting CSV payroll data into NACHA format for ACH transactions.
	|	TODO:
	|		+Auto-split nacha output file into two parts if exceeds max amount.
	|			+Should set the "Part2" to be transacted on transactionDayOffset+1.
	|			+Recursively loop into additional parts for amounts exceeding double max amount.
	|		+Implement Addenda Records for pay period info in employee bank statements.
	|		+Implement UX improvements like SFX/GUI elements.
	|		+Improve logging functionality for audit/analysis.
	|		+Brainstorm any other useful ideas.
	|		+Use OutputDebug for logging to aid in debugging with tools like VS Code?
	|			+e.g.: OutputDebug A_Now ': Derp happened. Input file did not exist. Go Fish.'
	|	Problems:
	|		+None yet. Just needs more functionality.
	|	Ideas:
	|		+Break out individual functions into separate .ahk files for organization, and to allow users to more easily edit specific functionality.
	\=======================================================================/
*/

/*
	/=======================================================================\
	|Compiler Directives
	|	These commented lines are for the compiler. (They're ignored when running the script directly from source.)
	|	Windows Defender sometimes flags compiled AutoHotkey scripts as suspicious, so compiling can help with that.
	|	This especially comes in handy if you want to protect your source code from casual reverse-engineering.
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

;Ensure AHK is running on v2.0
#Requires AutoHotkey v2.0
;Make sure only one running instance of the script exists at any given time.
#SingleInstance Force

;Ensure we have UAC permission to actually function, i.e.: writing files/etc.
full_command_line := DllCall("GetCommandLine", "str")
if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
{
	try
	{
		if A_IsCompiled
			Run '*RunAs "' A_ScriptFullPath '" /restart'
		else
			Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
	}
	ExitApp
}

;Ensure the script has the ability to differentiate between virtual and physical input.
InstallKeybdHook true true
;Version & author of the script.
scriptVersion := "1.0.1"
scriptAuthor := "TrevorLaneRay"
;Create a little tray icon info.
A_IconTip := "NachaLibre v." . scriptVersion
A_ScriptName := "NachaLibre"
;Make a note of when the script was launched.
scriptLaunchTimestamp := A_Now

/*
	/=======================================================================\
	|Script Settings
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
	|Script Functionality
	|	Functions of the script that have proven reliable.
	\=======================================================================/
*/

ReadCSVFile(fileNameToRead) ;Parse the target CSV file, line by line, field by field.
{
	TraySetIcon scriptActiveIconFile
	;Load CSV file into an variable.
	csvFile := FileRead(fileNameToRead)
	global csvLineCount := 0
	LogEvent("Event", "CSV Loaded:`n" . fileNameToRead)

	;Some blank arrays for when we read the CSV, later to be used for Entry Record generation.
	;These should be global arrays, so that NachaConstructor() can use them later.
	global CSVField1Array := []
	global CSVField2Array := []
	global CSVField3Array := []
	global CSVField4Array := []
	global CSVField5Array := []
	global CSVField6Array := []
	global CSVField7Array := []

	;We now go through the CSV, row by row.
	Loop Parse csvFile, "`n", "`r"
	{
		;Skip the first line in the CSV, as it only contains headers.
		;Also, if there's a blank line at the end of the CSV, skip that too.
		if A_Index = 1 || A_LoopField = ""{
			continue
		}
		csvLineCount += 1
		;We now go through each column in the row.
		;We add each of the current row's column's field to that field's array.
		Loop parse, A_LoopField, ","
		{
			CSVField%A_Index%Array.Push(Trim(A_LoopField,"$ `r`n"))
		}
	}

	LogEvent("Event", "CSV successfully processed.`nCSV File Lines: " . csvLineCount)
	TraySetIcon scriptIconFile
	return
}

/*
	/=======================================================================\
	|Beta Functionality
	|	Here be dragons.
	|	Functions here are not fully finalized, and should be reviewed further.
	\=======================================================================/
*/

NachaConstructor(*){ ;Build the Nacha file line by line, field by field.
	TraySetIcon scriptActiveIconFile
	nachaData :=  "" ;Will contain the raw text data of the entire Nacha file.
	nachaLine := "" ;Will contain the current line of the Nacha file we're working on.
	nachaLineCounter := 0 ;Will contain the total number of lines that should be in the file. (Used for padding and blocks.)
	totalEntryCounter := 0 ;Will contain the total number of entry and addenda records.
	batchEntryCounter := 0 ;Will contain the current counter of entries in the current batch.
	entryHash := 0 ;Will contain a sum of all entries' Recieving DFI IDs.
	totalCreditAmount := 0 ;Used in File and Batch Control Records, for sanity check.

	;/===================File Header Record===================\
	nachaLine .= "1" ;Record Type Code (This will never change.)
	nachaLine .= "01" ;Priority Code (This will never change.)
	nachaLine .= Format("{:010}", payrollRoutingNumber) ;Immediate Destination
	nachaLine .= Format("{:010}", payrollEIN) ;Immediate Origin (Supposedly the company EIN for taxes, but Chase wants 0's?)
	nachaLine .= FormatTime(A_Now, "yyMMdd") ;File Creation Date
	nachaLine .= FormatTime(A_Now, "HHmm") ;File Creation Time
	nachaLine .= "A" ;File ID Modifier (Implement iteration for multiple files later on?)
	nachaLine .= "094" ;Record Size (This will never change.)
	nachaLine .= "10" ;Blocking Factor (This will never change.)
	nachaLine .= "1" ;Format Code (This will never change.)
	nachaLine .= Format("{:-23}", payrollBankName) ;Immediate Destination Name
	nachaLine .= Format("{:-23}", payrollCompanyName) ;Immediate Origin Name
	nachaLine .= "        " . "`n" ;Reference Code (and a newline to end the File Header Record).

	nachaData .= nachaLine ;Append the current line's contents to the nachaData.
	;~ LogEvent("Event", "Constructed File Header Record - Line " . nachaLineCounter . "`nLine Contents:`n" . nachaLine)
	nachaLine := "" ;Reset current line's contents to be ready for the next line's content.
	nachaLineCounter += 1
	;\========================================================/

	;/================Batch Header Record================\
	nachaLine .= "5" ;Record Type Code
	nachaLine .= "220" ;Service Class Code
	nachaLine .= SubStr(Format("{:-16}", payrollCompanyName), 1, 16) ;Company Name (TODO: Trim company name to 16chars *before* padding, so that it doesn't overflow if longer.)
	nachaLine .= Format("{:020}", payrollAccountNumber) ;Company Discretionary Data
	nachaLine .= "0000000000" ;Company Identification (EIN for Taxes, ignored by Chase)
	nachaLine .= "PPD" ;Standard Entry Class Code
	nachaLine .= Format("{:-10}", "PAYROLL") ;Company Entry Description
	nachaLine .= payDay ;Company Descriptive Date (Payday)
	nachaLine .= transactionDay ;Effective Entry Date (Date the transaction occurs on)
	nachaLine .= "   " ;Settlement Date (Don't touch; Chase will modify this.
	nachaLine .= "1" ;Originator Status Code
	nachaLine .= SubStr(payrollRoutingNumber, 1, 8) ;Originating DFI Identification
	nachaLine .= "0000001" . "`n" ;Batch Number (and a newline to end the Batch Header Record).

	nachaData .= nachaLine ;Append the current line's contents to the nachaData.
	;~ LogEvent("Event", "Constructed Batch Header Record - Line " . nachaLineCounter . "`nLine Contents:`n" . nachaLine)
	nachaLine := "" ;Reset current line's contents to be ready for the next line's content.
	nachaLineCounter += 1
	;\========================================================/

	;/================Entry Detail Records================\
	;Let's go through the array of payroll entries passed to this function.
	Loop csvLineCount {
		totalEntryCounter += 1
		batchEntryCounter += 1

		;Take each field of the current entry, format it appropriately, and tack it all onto the current PPD Detail Record line.
		ppdField1Data := "6" ;Record Type Code
		if CSVField4Array[A_Index] = "Checking" {
			ppdField2Data := "22" ;Indicates that the payee has a Checking account.
		} else if CSVField4Array[A_Index] = "Savings" {
			ppdField2Data := "32" ;Indicates that the payee has a Savings account.
		}
		ppdField3Data := SubStr(Format("{:09}", CSVField5Array[A_Index]), 1, 8) ;First eight digits of Employee Routing Number
		entryHash += ppdField3Data
		ppdField4Data := SubStr(CSVField5Array[A_Index], -1, 1) ;Last digit of Employee Routing Number
		ppdField5Data := Format("{:-17}", Trim(CSVField6Array[A_Index], " ")) ;Employee Account Number
		ppdField6Data := Format("{:010}", StrReplace(CSVField7Array[A_Index], ".")) ;Dollar amount, formatted as $$$$$$$$¢¢
		totalCreditAmount += CSVField7Array[A_Index] ;Total dollar amount thus far.
		ppdField7Data := Format("{:-15}", Trim(CSVField1Array[A_Index], " ")) ;Individual Identification Number
		ppdField8Data := SubStr(Format("{:-22}", Trim(CSVField2Array[A_Index] . " " CSVField3Array[A_Index], " ")), 1, 22) ;Employee Name
		ppdField9Data := Format("{:-2}", "") ;Discretionary Data (This is to be blank, just two spaces.)
		ppdField10Data := "0" ;Addenda Record Indicator (Add later for additional pay period info / hours worked in employee bank statement.)
		ppdField11Data := SubStr(payrollRoutingNumber, 1, 8) . Format("{:07}", batchEntryCounter) ;Trace Number

		nachaLine := ppdField1Data . ppdField2Data . ppdField3Data . ppdField4Data . ppdField5Data . ppdField6Data . ppdField7Data . ppdField8Data . ppdField9Data . ppdField10Data . ppdField11Data . "`n"
		nachaData .= nachaLine ;Append the current line's contents to the nachaData.
		nachaLine := "" ;Reset current line's contents to be ready for the next line's content.
		nachaLineCounter += 1
	}
	if totalCreditAmount >= maxPayrollAmount
	{
		LogEvent("Error", "Max Payroll Amount Exceeded.`n Payroll: $" . totalCreditAmount . "`nPayroll Limit: $" . maxPayrollAmount . "`nIf this is a bank-imposed limit, this NACHA file will not be accepted.")
		;TODO: Implement logic to split the payroll into multiple batches/files if the total amount exceeds the specified limit.
	}
	;~ else LogEvent("Event", "Constructed Entry Detail Records.`nEntry Count: " . totalEntryCounter . "`nTotal Payment Amount: $" . totalCreditAmount)

	;\========================================================/

	;/================Batch Control Record================\
	nachaLine := "" ;Reset current line's contents to be ready for the next line's content.
	nachaLine .= "8" ;Record Type Code
	nachaLine .= "220" ;Service Class Code
	nachaLine .= Format("{:06}", csvLineCount) ;Entry/Addenda Count
	nachaLine .= SubStr(Format("{:010}", entryHash), -10, 10) ;Entry Hash
	nachaLine .= Format("{:012}", 0) ;Total Debit Amount
	nachaLine .= Format("{:012}", StrReplace(Round(totalCreditAmount, 2), ".")) ;Total Credit Amount
	nachaLine .= "0000000000" ;Company Identification (EIN for tax purposes - Does Chase want this as 0's?)
	nachaLine .= "                   " ;Message Authentication Code (Chase leaves this blank. No idea what it's for. Just 19 spaces.)
	nachaLine .= "      " ;Reserved (Yet another field that's always supposed to be blank. Just 6 spaces. *shrug*)
	nachaLine .= SubStr(Format("{:08}", payrollRoutingNumber), 1, 8) ;Originating DFI Identification (Same as in the Batch Header Record, field 12. First eight digits of funding bank's 9-digit routing number.)
	nachaLine .= "0000001" . "`n" ;Batch Number (and a newline to end the current Entry Record.)

	nachaData .= nachaLine ;Append the current line's contents to the nachaData.
	;~ LogEvent("Event", "Constructed Batch Control Record - Line " . nachaLineCounter . "`nLine Contents:`n" . nachaLine)
	nachaLineCounter += 1
	nachaLine := "" ;Reset current line's contents to be ready for the next line's content.
	;\========================================================/

	;/================File Control Record================\
	Loop Parse nachaData, "`n", "`r"
	{
		;Tally up total number of entry lines.
		nachaFileLines := A_Index
	}
	;Tally up how many blocks (total lines, divided by 10) are in the file.
	;Note the +1 here is to account for this File Control Record line.
	;Essentially: if the number of lines is not divisible evenly by 10, add one block to account for the remainder.
	Mod(nachaFileLines + 1, 10) = 0 ? nachaFileBlockCount := ((nachaFileLines + 1) / 10) : nachaFileBlockCount := Round((nachaFileLines + 1) / 10) + 1
	nachaLine .= "9" ;Record Type Code
	nachaLine .= Format("{:06}", 1) ;Batch Count
	nachaLine .= Format("{:06}", nachaFileBlockCount) ;Block Count
	nachaLine .= Format("{:08}", csvLineCount) ;Entry/Addenda Count
	nachaLine .= SubStr(Format("{:010}", entryHash), -10, 10) ;Entry Hash
	nachaLine .= Format("{:012}", 0) ;Total Debit Amount
	nachaLine .= Format("{:012}", StrReplace(Round(totalCreditAmount, 2), ".")) ;Total Credit Amount
	nachaLine .= Format("{:-39}", "") ;Reserved

	nachaData .= nachaLine ;Append the current line's contents to the nachaData.
	;~ LogEvent("Event", "Constructed File Control Record - Line " . nachaLineCounter . "`nLine Contents:`n" . nachaLine)
	nachaLineCounter += 1
	nachaLine := "" ;Reset current line's contents to be ready for the next line's content.
	;\========================================================/

	;/=========================Padding========================\
	Loop Parse nachaData, "`n", "`r"
	{
		;Tally up total number of lines in the current nachaData.
		nachaFileLines := A_Index
	}
	if (Mod(nachaFileLines, 10)) {
		;If the nachaData is not evenly divisible by 10...
		paddingLineCount := 0
		Loop 10 - Mod(nachaFileLines, 10) {
			;Add lines of 9's to pad the file so the number of lines in the file is evenly divisible by 10.
			nachaLine .= "`n" . "9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999"
			paddingLineCount += 1
		}
	} else {
		;If the total nachaData lines are a multiple of 10, we won't need padding.
		paddingLineCount := 0
	}
	nachaData .= nachaLine ;Append the current line's contents to the nachaData.
	;~ LogEvent("Event", "Constructed Padding.`n" . paddingLineCount . " lines of padding added to " . nachaFileLines . " record lines.`nFile should now be " . (paddingLineCount + nachaFileLines) . " lines long.")
	;\========================================================/

	A_Clipboard := nachaData
	dateStamp := A_YYYY . A_MM . A_DD . A_Hour . A_Min . A_Sec
	FileAppend(nachaData,nachaFileFolderName . "\" . dateStamp . NachaFileName . ".ach")
	if FileExist(scriptSuccessIconFile)
		TraySetIcon scriptSuccessIconFile
	LogEvent("Notice", totalEntryCounter . " entries processed.`nPay Period: " . FormatTime(payPeriodBegin, "MMM dd") . "-" . FormatTime(payPeriodEnd, "MMM dd") . "`nTotal amount: $" . Round(totalCreditAmount, 2) . "`nPayday: " . payDay . "`nTransaction Date: " . transactionDay . "`nSource Account: " . payrollAccountNumber . "`nSource Routing: " . payrollRoutingNumber . "`nThe " . (nachaFileLines + paddingLineCount) . "-line NACHA file has been saved.")
	if FileExist(scriptIconFile)
		TraySetIcon scriptIconFile
	return
}

LogEvent(eventType := "Event", logInfo := "DERP"){ ;Diagnostic panic and logging.
	;There are multiple event types we should account for:
	;"Event" = Normal functionality events.
	;"Error" = Something went wrong. We notify the user and log it.
	;"Notice" = Nothing's wrong, but we need to tell the user something and log it.
	if FileExist(scriptIconFile)
		TraySetIcon scriptActiveIconFile
	logTimeStamp := A_Now
	scriptRunTime := DateDiff(logTimeStamp, scriptLaunchTimestamp, "Seconds")

	outputLogData := "/=======================================================================\`nLog Type: " . eventType . "`nScript Launched: " . scriptLaunchTimestamp . "`nLog Timestamp: " . logTimeStamp . "`nScript Runtime: " . scriptRunTime . " Seconds`n`nLogEntry:`n" . logInfo . "`n\=======================================================================/`n"
	FileAppend(outputLogData, scriptLogFile)

	if eventType = "Notice"
	{
		;Here we'll display an informational message to the user, informing them of the event we just logged.
		if FileExist(scriptHungIconFile)
			TraySetIcon scriptHungIconFile
		MsgBox("Timestamp: " . scriptLaunchTimestamp . "`nScript Runtime: " . scriptRunTime . " Seconds`n`nLogged message:`n" . logInfo, "NachaLibre Notice", "Iconi")
	} else if eventType = "Error"
	{
		;Here we'll display an error message to the user, informing them of the problem we just logged.
		if FileExist(scriptErrorIconFile)
			TraySetIcon scriptErrorIconFile
		MsgBox("Timestamp: " . scriptLaunchTimestamp . "`nScript Runtime: " . scriptRunTime . " Seconds`n`nLogged message:`n" . logInfo, "NachaLibre Error", "Icon!")
	}

	if FileExist(scriptIconFile)
		TraySetIcon scriptIconFile
	return
}