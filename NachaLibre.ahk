/*
	/=======================================================================\
	|NachaLibre
	|	A straightforward generator to take an Excel-exported CSV file, and turn it into a Nacha file for banks.
	|	Intended to simplify Excel-based payroll tasks.
	|Project Notes
	|	Current Task(s):
	|		[ ]	Establish variables defining Nacha file format parameters.
	|	TODO Functions:
	|		[X]	Function: Read CSV file into script cleanly.
	|		[X]	Function: Output a tab-separated txt for preview.
	|		[ ]	Function: Import new instances of Employee/Accounts into separate database.
	|			[ ]	SubFunction: Run sanity checks against this database to verify any changes since the last time?
	|		[ ]	Function: Generate a Nacha-formatted array of lines from PayrollArray()
	|			Of course, this should be done after the import of CSV is reviewed and confirmed.
	|		[ ]	Function: Output Nacha-formatted .ach file(s) from the array of Nacha Lines.
	|	TODO Features:
	|		[ ]	Feature: (Required) Split Nacha files by an upper limit applied to the running total.
	|			This can be done by returning an array of processed arrays from PayrollArray().
	|			Each array would have <= maxPayrollAmount. (For now, we'll call this $500K.)
	|			Alternatively, this can be done later during the Nacha file generation stage.
	|			Before an entry is added, its amount can be checked.
	|			If the amount is above maxPayrollAmount, we can finalize that Nacha file, and start with a new one.
	|		[ ]	Feature: Load user/payroll/script parameters from separate .ini or .txt file.
	|			This would make it much easier to adjust values after compilation. No hard-coded values.
	|		[ ] Feature: Separate Nacha file validator to import and verify .ach files on-demand.
	|			The ability to summarize an existing Nacha file would be a godsend. I want this. :D
	|	TODO Minutae/QoL:
	|		[X] Add icons in the tray for visual status indication of script activity.
	|		[ ] Add descriptive tooltips on the tray icon to explain its current state.
	|		[ ] Add a brief splash screen on launch, so it's obvious when we launch it.
	|		[ ]	Make some useful, human-readable documentation for any other mortal souls going through this in the future.
	|	Queries:
	|		[ ] When a deposit is made to an employee account, do we HAVE to specify if it's a checking/savings/credit?
	|			One would think that the recipient account number would be implicitly one type or another...
	|		[ ] Should we add handling for employee first/last names being entered as a single string, rather than separated?
	|			(This is a nice idea, but this should be considered common-sense to have the surname/firstname as separate.)
	\=======================================================================/
*/

/*
	/=======================================================================\
	|Compiler Directives
	|	These commented lines are for the compiler.
	|	If turning the script into an executable, this helps.
	|	TODO: Windows Defender is paranoid. Find some way to un-rustle its jimmies.
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
InstallKeybdHook true true
;Version & author of the script.
scriptVersion := "0.06"
scriptAuthor := "TrevorLaneRay"
HoursHavingFunOnThis := [6.1, 2.25, 4.15, 3.8, 2.6]
;Create a little tray icon info.
NachaIconFile := "NachaIcon.ico"
busyIconFile := "NachaIconYellow.ico"
errorIconFile := "NachaIconRed.ico"
okIconFile := "NachaIconGreen.ico"
A_IconTip := "NachaLibre v." . scriptVersion
A_ScriptName := "NachaLibre"
if FileExist(NachaIconFile)
    TraySetIcon NachaIconFile

/*
	/=======================================================================\
	|User Settings
	|	These settings are for user-specified parameters.
	|	Adjust these to your specific use case.
	|	Later, let's get these out of the script, and into a separate .ini file for customization after compilation.
	\=======================================================================/
*/

;File/Folder Settings
csvFileName := "SampleCSV.csv"
NachaFileFolderName := "NachaFiles"
nachaFileName := "NachaFile"
auditLogFileFolderName := "AuditLogs"
auditLogFileName := "AuditLog"

;Payroll Settings
maxPayrollAmount := 5000000 ;Upper limit of dollars at which to split Nacha submissions (dependent on bank?).
payrollBankName := "JPMORGAN CHASE" ;Name of the bank the payroll will be sent from.
payrollCompanyName := "HURP DERP LLC" ;Name of your company. Needs to be upper case. A-Z, space, and periods, max 23 chars.
payrollRecipientCompanyName := "Hurp Derp LLC" ;Name of your company. (Same as above, but will be what appears in an employee's bank statement. Max 16 chars.)
payrollRoutingNumber := "123456789" ;Routing number of bank from which the payroll will be withdrawn.
payrollAccountNumber := "987654321" ;Account number from which the payroll will be withdrawn.
payrollEIN := "12-3456789" ;String to identify the business entity for tax purposes. (10 chars, leading zeros.)

/*
	/=======================================================================\
	|Nacha Parameters
	|	These settings are for the minutae of constructing the Nacha file format.
	|	These will likely never need to be changed, unless banking situation calls for it.
	|	For development purposes, this will be written with Chase Bank's specifications in mind.
	|	TL;DR: No touchie. If customization is needed, do so above, in the "Payroll Settings" section of variables.
	\=======================================================================/
*/

;~ File Header Record (The first line in the Nacha file.)

;Record Type Code - Value should only ever be '1'. This identifies the line as the file header record.
fileHeaderRecordPosition1 := 1
fileHeaderRecordLength1 := 1
fileHeaderRecordValue1 := "1"
;Priority Code - Value is 01. The lower the number, the higher the processing priority. Currently, only 01 is used.
fileHeaderRecordPosition2 := 2
fileHeaderRecordLength2 := 2
fileHeaderRecordValue2 := "01"
;Immediate Destination - Originating bank's transit routing number.
fileHeaderRecordPosition3 := 4
fileHeaderRecordLength3 := 10
fileHeaderRecordValue3 := payrollRoutingNumber
;Immediate Origin - Company EIN number? Or is this an ACH ID? The use of an IRS federal tax ID number is more likely. The company ID is displayed in the output with leading zeros.
fileHeaderRecordPosition4 := 14
fileHeaderRecordLength4 := 10
;~ fileHeaderRecordValue4 := payrollEIN
fileHeaderRecordValue4 := "0000000000" ;If Chase lets us use our EIN, delete this line and use the previous line instead.
;File Creation Date - Date the input file was created. (This will be redetermined later when the file is actually created.)
fileHeaderRecordPosition5 := 24
fileHeaderRecordLength5 := 6
fileHeaderRecordValue5 := FormatTime(A_Now, "yyMMdd")
;File Creation Time - Time of day the input file was created. (This will be redetermined later when the record is added to the file.)
fileHeaderRecordPosition6 := 30
fileHeaderRecordLength6 := 4
fileHeaderRecordValue6 := FormatTime(A_Now, "HHmm")
;File ID Modifier - Initial value is A. This is a code to distinguish between multiple Nacha files. If more than one file is delivered, they must have different file IDs.
;Remember, if we hit the upper limit on dollar amount per Nacha file, we need to create a new Nacha file, iterating this by one letter.
;This also implies that we can only upload 26 nacha files per minute? If a bank has an upper limit of $500K per file, then our max payroll amount per minute would be... $13,000,000. Whoof.
fileHeaderRecordPosition7 := 34
fileHeaderRecordLength7 := 1
fileHeaderRecordValue7 := ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
;Record Size - Value is "094" - Number of bytes per record (e.g.: number of characters on each line). (Why need this tho? It's understood that 94chars is the file format... duh.)
fileHeaderRecordPosition8 := 35
fileHeaderRecordLength8 := 3
fileHeaderRecordValue8 := " 94"
;Blocking Factor - Value is "10". (Duh. It's explicitly part of the Nacha specifications. Why do we even need this in the file?)
fileHeaderRecordPosition9 := 38
fileHeaderRecordLength9 := 2
fileHeaderRecordValue9 := "10"
;Format Code - Value is '1'. (Is there some other, proprietary standard of Nacha file layout nobody knows about? Must be super-secret.)
fileHeaderRecordPosition10 := 40
fileHeaderRecordLength10 := 1
fileHeaderRecordValue10 := "1"
;Immediate Destination Name - Name of the bank that the payroll will be sent from. (Most likely the bank where the Nacha file will be uploaded to.)
fileHeaderRecordPosition11 := 41
fileHeaderRecordLength11 := 23
fileHeaderRecordValue11 := payrollBankName
;Immediate Origin Name - Name of your company, probably the one you'll be processing payroll for.
fileHeaderRecordPosition12 := 64
fileHeaderRecordLength12 := 23
fileHeaderRecordValue12 := payrollCompanyName
;Reference Code - Optional field used to describe the Nacha file for accounting purposes. (This is usually just blank spaces, unless there's something useful we can put here.)
fileHeaderRecordPosition13 := 87
fileHeaderRecordLength13 :=8
fileHeaderRecordValue13 := "        "

;~ Batch Header Record (The line beginning with '5'.)
	;~ The batch header record identifies the originating entity and the type of transactions contained in the batch.

;Record Type Code - Just the digit '5'. Identifies this line as a batch header record.
batchHeaderRecordPosition1 := 1
batchHeaderRecordLength1 := 1
batchHeaderRecordValue1 := "5"
;Service Class Code - Determines whether you're paying people (220 "Credit"), or charging them (225 "Debit"). Don't mess this up unless you want angry employees. :D
batchHeaderRecordPosition2 := 2
batchHeaderRecordLength2 := 3
batchHeaderRecordValue2 := "220"
;Company Name - Name of your company. (This should be what appears when employees look at their bank statements. 16 chars, fill with spaces at the end if less.)
batchHeaderRecordPosition3 := 5
batchHeaderRecordLength3 := 16
batchHeaderRecordValue3 := payrollRecipientCompanyName
;Company Discretionary Data - In the case of Chase Bank, this is the funding account number. This is the "Pay from" account for payments, or the "Deposit to" account for reversals/collections.
;Chase bank wants this right-aligned, and filled with zeros in the empty space before it.
batchHeaderRecordPosition4 := 21
batchHeaderRecordLength4 := 20
batchHeaderRecordValue4 := payrollAccountNumber
;Company Identification - This *should* be the 10-character tax ID/EIN... Or is it some ACH ID? Chase bank is unclear on this. For now, we'll do zeros until we're sure.
batchHeaderRecordPosition5 := 41
batchHeaderRecordLength5 := 10
;~ batchHeaderRecordValue5 := payrollEIN
batchHeaderRecordValue5 := "0000000000" ;Delete this line and use the above line instead, if we can put our EIN here.
;Standard Entry Class Code - Clarifies whether the Service Class Code is payroll (PPD), corporate payments (CCD), or collections (WEB). There's also "TEL" but who knows what that's for.
batchHeaderRecordPosition6 := 51
batchHeaderRecordLength6 :=3
batchHeaderRecordValue6 := "PPD"
;Company Entry Description - God only knows why we need to put this here; we just stated what this is for in the previous field. Duh.
batchHeaderRecordPosition7 := 54
batchHeaderRecordLength7 := 10
batchHeaderRecordValue7 := "PAYROLL"
;Company Descriptive Date - Seems to be flexible/optional, but it's essentially used as a "descriptive Payday date." Chase describes it as MMM DD (JAN 02). Likely is what will appear on bank statements.
;Since we might not be generating the Nacha file ON the actual payday, we might need to ask the user what date to put here. For now, we'll assume it's the day we create the Nacha file.
batchHeaderRecordPosition8 := 64
batchHeaderRecordLength8 := 6
batchHeaderRecordValue8 := FormatTime(A_Now, "MMM dd")
;Effective Entry Date - MUST be later than the file creation date, according to Chase. We'll just add one day to today for use here? (6chars, yymmdd)
batchHeaderRecordPosition9 := 70
batchHeaderRecordLength9 := 6
batchHeaderRecordValue9 := FormatTime(DateAdd(A_Now, 1, "days"), "yyMMdd")
;Settlement Date - No touchie. Bank will insert this automatically. Leave blank space here.
batchHeaderRecordPosition10 := 76
batchHeaderRecordLength10 := 3
batchHeaderRecordValue10 := "   "
;Originator Status Code - Identifies the bank as a Depository Financial Institution, or DFI. This will always be 1... so why is it needed? Goofballs.
batchHeaderRecordPosition11 := 79
batchHeaderRecordLength11 := 1
batchHeaderRecordValue11 := "1"
;Originating DFI Identification - The transit routing number of the originating financial institution. For all intents and purposes, this should be the same as the one in the file header. (8chars, Leading zeros.)
batchHeaderRecordPosition12 := 80
batchHeaderRecordLength12 := 8
batchHeaderRecordValue12 := payrollRoutingNumber
;Batch Number - The heck is a batch? How many can fit in a batch? How many batches can a natcha batch, Stretch? (7chars, leading zeros, iterating +1 for each batch.)
;Just guessing here, but I'm guessing each "batch" is a separate transaction for the company payroll. Doesn't seem to have an upper limit on number of items in a batch, or number of batches. 9,999,999?
;Thus, if the bank has an upper limit on the amount of each "transaction," then we may need to iterate this.
batchHeaderRecordPosition13 := 88
batchHeaderRecordLength13 := 7
batchHeaderRecordValue13 := 1

;~ PPD Detail Record
	;~ This record contains the information needed to post a deposit to an account, such as the receiver's name, account number, and payment amount.

;~ Batch Control Total
	;~ This record appears at the end of each batch. It holds totals for the batch.

;~ File Control Record
	;~ This record provides a final check on the submitted data. It contains block and batch counts and totals for each type of entry.

/*
	/=======================================================================\
	|Hotkeys
	|	These hotkeys are for controlling the state of the script.
	|	These will work anywhere, not just in a specific window.
	\=======================================================================/
*/
#UseHook
Pause::Pause
+F12::Reload
^+F12::ExitApp
F11::
{
	;Read the CSV file into the script.
	PayrollArray := ReadCSVFile(csvFileName)
	;Process the CSV into a simple preview for double-checking.
	;This will output "true" if the preview is accepted by user, or "false" if rejected.
	OutputPreviewFile(PayrollArray, auditLogFileFolderName, auditLogFileName)
	return
}

/*
	/=======================================================================\
	|Script Functions
	|	Core functions of the script here.
	|	Reliable functions go here ONLY after extensive testing.
	\=======================================================================/
*/

ReadCSVFile(fileNameToRead) ;Parse the target CSV file, line by line, field by field.
{
	TraySetIcon busyIconFile
	;Load CSV file into an variable.
	csvFile := FileRead(fileNameToRead)
	;Create a blank array to use for rows.
	CSVArray := []
	;We now go through the CSV, row by row.
	Loop Parse csvFile, "`n", "`r"
	{
		;Create a blank array to hold the contents of each column in the current row.
		RowContents := []
		;We now go through each column in the row.
		Loop parse, A_LoopField, ","
		{
			;Add the column content into the array of column items.
			;We'll trim off any unnecessary characters from the beginning or end of the column's data.
			;This is useful since dollar amounts, when exported as CSV from Excel, aren't purely numeric values, but characters like '$'.
			;Perhaps later we can also check for numbers in the employee name field, which shouldn't be present.
			RowContents.Push(Trim(A_LoopField,"$ `r`n"))
		}
		;Add that row of column contents onto the array of rows.
		CSVArray.Push(RowContents)
	}
	;Report how many lines were read from the CSV.
	MsgBox(CSVArray.Length . " Lines Read.", "CSV reading loop completed.", 64)
	TraySetIcon NachaIconFile
	;Here we should expect to somehow return the final array of parsed CSV data, as an array of rows, each row an array of column items.
	return CSVArray
}

OutputPreviewFile(ArrayOfEntriesToLog, logLocation, outputFile) ;Test to output summary of transactions, useful for double-checking the CSV.
{
	;Note: This function will return a "true" value if the output is accepted by the user, or "false" value if rejected.
	TraySetIcon busyIconFile
	dateStamp := A_YYYY . A_MM . A_DD . A_Hour . A_Min . A_Sec
	runningTotal := 0
	;Let's go through the array of entries passed to this function.
	for entryIndex, EntryContents in ArrayOfEntriesToLog
	{
		;Add a date/time stamp as the first field on each entry when we log it.
		A_Index = 1 ? outputLogData .= "Date" . A_Tab : outputLogData .= dateStamp . A_Tab
		;And for each entry, let's go through each field.
		for entryField, entryData in EntryContents
		{
			;Append each field's contents to the output log, separated by tabs.
			if A_Index != 5
			{
				;Insert a tab if the field isn't the last in the row.
				entryData .= A_Tab
			}
			outputLogData .= entryData
			;Add the entryAmount to a running total for a summary.
			;Later, this running total will be used to determine if a Nacha file has to be split by an upper limit.
			if A_Index = 5 && entryData != "Amount"
			{
				runningTotal += entryData
			}
		}
		outputLogData .= "`n"
	}
	outputLogData := "Process Total: $" . Round(runningTotal, 2) . "`n" . outputLogData
	previewFile := logLocation . "\Previews\" . "(Preview) " . outputFile . " " . dateStamp . ".txt"
	DirCreate(logLocation . "\Previews\")
	FileAppend(outputLogData, previewFile)
	Run previewFile
	TraySetIcon okIconFile
	Sleep 1000
	importConfirmation := MsgBox("Please review the imported CSV.`nWe need to make sure it looks right.`nOnce reviewed, come back here and confirm.`n`nDoes the file of $" . Round(runningTotal, 2) . " look correct?","CSV Import Review","Icon? YesNo")
	if importConfirmation = "Yes"
	{
		TraySetIcon busyIconFile
		outputFile := logLocation . "\" . outputFile . " " . dateStamp . ".txt"
		FileAppend(outputLogData, outputFile)
		TraySetIcon okIconFile
		MsgBox("Alrighty.`nYou can close the preview of the imported data if you don't need it.`n(A copy is saved.)`nWe can now proceed with processing the data into Nacha format.","CSV Review Complete","Iconi")
		TraySetIcon NachaIconFile
		return true
	}else if importConfirmation = "No"
	{
		TraySetIcon ErrorIconFile
		MsgBox("Okiedokes.`nGo ahead and make corrections to the CSV file where necessary.`nWe can try again later with the revised version.","CSV Data Not Accepted","Icon!")
		TraySetIcon NachaIconFile
		return false
	}
	TraySetIcon NachaIconFile
	return
}

/*
	/=======================================================================\
	|Beta Functions
	|	Here be dragons.
	|	Functions here are under active development.
	\=======================================================================/
*/

Derp(*){
	return "Herp derp."
}