/*
	/=======================================================================\
	|Project Notes
	|	TODO Functions:
	|		[X]	Function: Read CSV file into script cleanly.
	|		[X]	Function: Output a tab-separated txt for preview.
	|		[ ]	Function: Import new instances of Employee/Accounts into separate database.
	|			[ ]	SubFunction: Run sanity checks against this database to verify any changes since the last time.
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
	|		[ ]	Feature: Load payroll/script parameters from separate .ini or .txt file.
	|			This would make it much easier to adjust values after compilation.
	|		[ ] Feature: Separate Nacha file validator to import and verify .ach files on-demand.
	|	TODO Minutae/QoL:
	|		[X] Add icons in the tray for visual status indication of script activity.
	|		[ ] Add descriptive tooltips on the tray icon to explain its current state.
	|		[ ] Add a brief splash screen on launch, so it's obvious when we launch it.
	|	Queries:
	|		[ ] When a deposit is made to an employee account, do we HAVE to specify if it's a checking/savings/credit?
	\=======================================================================/
*/

/*
	/=======================================================================\
	|Compiler Directives
	|	These commented lines are for the compiler.
	|	If turning the script into an executable, this helps.
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

;Ensure we have UAC permission to actually function.
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
scriptVersion := "0.02"
scriptAuthor := "TrevorLaneRay"
;Create a little tray icon info.
NachaIconFile := "NachaIcon.ico"
busyIconFile := "NachaBusyIcon.ico"
errorIconFile := "NachaErrorIcon.ico"
okIconFile := "NachaOKIcon.ico"
A_IconTip := "NachaLibre v." . scriptVersion
A_ScriptName := "NachaLibre"
if FileExist(NachaIconFile)
    TraySetIcon NachaIconFile

csvFileName := "SampleCSV.csv"
NachaFileFolderName := "NachaFiles"
nachaFileName := "NachaFile"
auditLogFileFolderName := "AuditLogs"
auditLogFileName := "AuditLog"

/*
	/=======================================================================\
	|Payroll Settings
	|	These settings are for specific payroll parameters.
	|	Adjust these to your specific use case.
	\=======================================================================/
*/
maxPayrollAmount := 5000000 ;Upper bound on which to split Nacha submissions (dependent on bank).
payrollRoutingNumber := 123456789 ;Routing number of bank from which the payroll will be withdrawn.
payrollAccountNumber := 987654321 ;Account number from which the payroll will be withdrawn.
payrollEIN := "12-3456789" ;Number to identify the business entity for tax purposes.

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
	PayrollArray := ReadCSVFile(csvFileName)
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
	;Create an array for rows.
	CSVArray := []
	;We now go through the CSV, row by row.
	Loop Parse csvFile, "`n", "`r"
	{
		;Create an array of columns.
		RowContents := []
		;We now go through each column in the row.
		Loop parse, A_LoopField, ","
		{
			;Add the column content into the array of column items.
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

/*
	/=======================================================================\
	|Beta Functions
	|	Here be dragons.
	|	Functions here are under active development.
	\=======================================================================/
*/

OutputPreviewFile(ArrayOfEntriesToLog, logLocation, outputFile) ;Test to output summary of transactions, useful for maintaining running totals.
{
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
	}else if importConfirmation = "No"
	{
		TraySetIcon ErrorIconFile
		MsgBox("Okiedokes.`nGo ahead and make corrections to the CSV file where necessary.`nWe can try again later with the revised version.","CSV Data Not Accepted","Icon!")
	}
	TraySetIcon NachaIconFile
	return
}