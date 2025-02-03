/*
	/=======================================================================\
	|NachaLibre
	|	A straightforward generator to take an Excel-exported CSV file, and turn it into a Nacha file for banks.
	|	Intended to simplify Excel-based payroll tasks.
	|Project Notes
	|	Current Task(s):
	|		[ ]	Nacha file construction functionality.
	|			The real work begins here... a function to properly concatenate fields into 94-character lines.
	|			Will also need on-the-fly sanity checks to GUARANTEE data is PERFECTLY error-free.
	|			Working in the real world, where real damage can be done if not careful. Have to get this airtight.
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
	|		[ ] When a deposit is made to an employee account, we HAVE to specify whether it's a checking or savings account.
	|			This means it involves a bit of tedious work, gathering the type of each employee's account number, routing, and type.
	|		[ ] Should we add handling for employee first/last names being entered as a single string, rather than separated?
	|			(This is a nice idea, but this should be considered common-sense to have the surname/firstname as separate.)
	|		[ ] Is there a way to easily determine in bulk what type of account each employee has (checking/savings)?
	|			Please... for the love of all that's holy, PLEASE let this not necessitate several hundred phone calls and research by employees...
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
scriptVersion := "0.07"
scriptAuthor := "TrevorLaneRay"
HoursHavingFunOnThis := [6.1, 2.25, 4.15, 3.8, 2.6, 5.5]
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
payPeriodBegin := DateAdd(A_Now, -14, "days") ;Date that the pay period began. (This should be input by the user manually.)
payPeriodEnd := A_Now ;Date that the pay period ended. (This should be input by the user manually.)
payrollBankName := "JPMORGAN CHASE" ;Name of the bank the payroll will be sent from.
payrollCompanyName := "HURP DERP LLC" ;Name of your company. Needs to be upper case. A-Z, space, and periods, max 23 chars.
payrollRecipientCompanyName := "Hurp Derp LLC" ;Name of your company. (Same as above, but will be what appears in an employee's bank statement. Max 16 chars.)
payrollRoutingNumber := "123456789" ;9-digit routing number of bank from which the payroll will be withdrawn. (Lead with zeros if less than 9 chars.)
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

;~ File Header Record (The first line in the Nacha file, beginning with '1'.)

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
;File Creation Date - Date the input file was created. (This will be recalculated later when the file is actually created.)
fileHeaderRecordPosition5 := 24
fileHeaderRecordLength5 := 6
fileHeaderRecordValue5 := FormatTime(A_Now, "yyMMdd")
;File Creation Time - Time of day the input file was created. (This will be recalculated later when the record is added to the file.)
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
;Company Descriptive Date - Seems to be flexible/optional, but it's essentially used as a "descriptive Payday date."
	;Chase describes it as MMM DD (JAN 02). Likely is what will appear on bank statements.
	;Since we likely will not be generating the Nacha file ON the actual payday, we will need to ask the user what date to put here.
	;For initial purposes here, we'll use the day after create the Nacha file.
batchHeaderRecordPosition8 := 64
batchHeaderRecordLength8 := 6
batchHeaderRecordValue8 := FormatTime(DateAdd(A_Now, 1, "days") "MMM dd")
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
;Originating DFI Identification - The first 8 digits of the transit routing number of the originating financial institution.
	;For all intents and purposes, this should be derived from the same one that's in the file header.
batchHeaderRecordPosition12 := 80
batchHeaderRecordLength12 := 8
batchHeaderRecordValue12 := SubStr(payrollRoutingNumber, 1, 8)
;Batch Number - The heck is a batch? How many can fit in a batch? How many batches can a natcha batch, Stretch? (7chars, leading zeros, iterating +1 for each batch.)
	;Just guessing here, but I'm guessing each "batch" is a separate transaction for the company payroll.
	;Doesn't seem to have an upper limit on number of items in a batch, or number of batches. 9,999,999?
	;Thus, if the bank has an upper limit on the amount of each "transaction," then we may need to iterate this.
batchHeaderRecordPosition13 := 88
batchHeaderRecordLength13 := 7
batchHeaderRecordValue13 := "0000001"

;~ PPD Detail Record (The line beginning with '6'.)
	;~ This record contains the information needed to post a deposit to an account, such as the receiver's name, account number, and payment amount.

;Record Type Code - Identifies this row as the Entry Detail Record. Will always be '6'.
entryDetailRecordPosition1 := 1
entryDetailRecordLength1 := 1
entryDetailRecordValue1 := "6"
;Transaction Code - Identifies the type of account to/from which to deposit or withdraw funds. (This will be fetched from imported CSV data.)
	;Deposit to checking account: 22
	;Deposit to savings account: 32
entryDetailRecordPosition2 := 2
entryDetailRecordLength2 := 2
entryDetailRecordValue2 := "22"
;Receiving DFI ID - First eight digits of the employee's bank's 9-digit routing number. (This will be fetched from imported CSV data.)
entryDetailRecordPosition3 := 4
entryDetailRecordLength3 := 8
entryDetailRecordValue3 := SubStr("REPLACEMEWITHEMPLOYEEROUTINGNUMBER", 1, 8)
;Check Digit - Last digit of the employee's bank's 9-digit routing number. (This will be fetched from imported CSV data.)
entryDetailRecordPosition4 := 12
entryDetailRecordLength4 := 1
entryDetailRecordValue4 := SubStr("REPLACEMEWITHEMPLOYEEROUTINGNUMBER", -1, 1)
;DFI Account Number - Bank account number of the employee. This can apparently be alphanumeric, not just numbers.
entryDetailRecordPosition5 := 13
entryDetailRecordLength5 := 17
entryDetailRecordValue5 := "0123456789ABCDEFG"
;Dollar Amount - Formatted as 00$$¢¢ (i.e.: "0000012345" would be $123.45).
entryDetailRecordPosition6 := 30
entryDetailRecordLength6 := 10
entryDetailRecordValue6 := "0000000000"
;Individual Identification Number - Identifies the Reciver's ID in batch. Uppercase A-Z, or 0-9. (Mandatory for Chase. Could this be company internal employee number?)
entryDetailRecordPosition7 := 40
entryDetailRecordLength7 := 15
entryDetailRecordValue7 := "0123456789ABCDE"
;Individual or Receiving Company Name - Employee Name. (i.e.: "John Doe" 22chars, left-aligned, fill with spaces.)
entryDetailRecordPosition8 := 55
entryDetailRecordLength8 := 22
entryDetailRecordValue8 := "John Doe"
;Discretionary Data - Just leave this blank (2 spaces).
entryDetailRecordPosition9 := 77
entryDetailRecordLength9 := 2
entryDetailRecordValue9 := "  "
;Addenda Record Indicator - This indicates whether there's an addenda record (beginning with a 7) where internal company data might go. (Present: 1, Absent: 0)
	;If we want to take advantage of extra info in bank statements, the Addenda Record is handy, so we'll take advantage of it.
entryDetailRecordPosition10 := 79
entryDetailRecordLength10 := 1
entryDetailRecordValue10 := "1"
;Trace Number - Usually this is stripped out and replaced by the bank. For Chase bank, they want the first eight digits of the funding account's routing number.
	;After the routing number, they want the number of the record as it appears in sequence in the batch, starting with "0000001".
	;Example for Chase: Routing = "122100024" then each transaction trace number would be "122100020000001", "122100020000002", "122100020000003", etc.
entryDetailRecordPosition11 := 80
entryDetailRecordLength11 := 15
entryDetailRecordValue11 := SubStr(payrollRoutingNumber, 1, 8) . "0000001"

;~ Addenda Record (The line beginning with '7'.)
	;~ This should be where we can add notes, like when the pay period began/ended, and how many hours worked, etc.
	;~ If we don't need the addenda, Chase lets us turn it off by setting the PPD Detail Record's Addenda Record Indicator to '0'.

;Record Type Code -
addendaRecordPosition1 := 1
addendaRecordLength1 := 1
addendaRecordValue1 := "7"
;Addenda Type Code -
addendaRecordPosition2 := 2
addendaRecordLength2 := 2
addendaRecordValue2 := "05"
;Payment Related Information - The good stuff. Here we can make detailed notes, which should show up on employees' bank statements.
	;80 char limit, followed by spaces. No special characters, except for ( ) ! # $ % & ' * + - . / : ; = ? @ [ ] ^ _ { | } .
addendaRecordPosition3 := 4
addendaRecordLength3 := 80
addendaRecordValue3 := "PayPeriod From " . FormatTime(DateAdd(A_Now, -14, "days"), "MMM dd") . " - " . FormatTime(A_Now, "MMM dd")
;Addenda Sequence Number -This number indicates the number of addenda records being sent with the associated Entry Detail Record.
	;Since only one addenda sequence number Chase allows per six (6) record in the CCD and PPD application, this field will always be “0001”.
addendaRecordPosition4 := 84
addendaRecordLength4 := 4
addendaRecordValue4 := "0001"
;Entry Detail Sequence Number - This field contains the ascending sequence number of the related entry detail record’s trace number.
	;This number is the same as the last 7 digits of the trace number of the related entry detail record. (This will be iterated by 1 for each entry in the CSV.)
	;Basically, it identifies which entry in the current batch the addenda is for.
addendaRecordPosition5 := 88
addendaRecordLength5 := 7
addendaRecordValue5 := "0000001"

;~ Batch Control Record (The line beginning with '8')
	;~ This record appears at the end of each batch. It holds totals for the batch.

;Record Type Code - Identifies this line as a Batch Control Record, beginning with an '8'.
batchControlRecordPosition1 := 1
batchControlRecordLength1 := 1
batchControlRecordValue1 := "8"
;Service Class Code - Same as the Service Class Code in the Batch Header Record. Determines whether you're paying people (220 "Credit"), or charging them (225 "Debit").
batchControlRecordPosition2 := 2
batchControlRecordLength2 := 3
batchControlRecordValue2 := "220"
;Entry / Addenda Count - Just like it sounds like; it's a sum totalling the number of lines that begin with 5 or 7. (Entry Detail Records and Addenda Records)
batchControlRecordPosition3 := 5
batchControlRecordLength3 := 6
batchControlRecordValue3 := "000001"
;Entry Hash - Basically used as a digital sanity check. It's a sum of the Entry Detail Records' Receiving DFI IDs.
	;Just adds up all the entries' routing numbers (only the first eight digits of each, though: field 3, positions 4-11).
batchControlRecordPosition4 := 11
batchControlRecordLength4 := 10
batchControlRecordValue4 := "0000000001"
;Total Debit Entry Dollar Amount - A sum totalling the whole amount withdrawn from accounts in the batch. Formatted as 00$$¢¢ (i.e.: "000000012345" would be $123.45).
batchControlRecordPosition5 := 21
batchControlRecordLength5 := 12
batchControlRecordValue5 := "000000012345"
;Total Credit Entry Dollar Amount - A sum totalling the whole amount deposited to accounts in the batch. Formatted as 00$$¢¢ (i.e.: "000000012345" would be $123.45).
batchControlRecordPosition6 := 33
batchControlRecordLength6 := 12
batchControlRecordValue6 := "000000012345"
;Company Identification - This *should* be the 10-character tax ID/EIN... Or is it some ACH ID? Chase bank is unclear on this. For now, we'll do zeros until we're sure.
	;This must match whatever's in the Batch Header Record, field 5, position 41-50.
batchControlRecordPosition7 := 45
batchControlRecordLength7 := 10
;~ batchControlRecordValue7 := payrollEIN
batchControlRecordValue7 := "0000000000" ;If we can use our EIN, delete this line and use the one above.
;Message Authentication Code - Chase leaves this blank. No idea what it's for. Just 19 spaces.
batchControlRecordPosition8 := 55
batchControlRecordLength8 := 19
batchControlRecordValue8 := "                   "
;Reserved - Yet another field that's always supposed to be blank. Just 6 spaces. *shrug*
batchControlRecordPosition9 := 74
batchControlRecordLength9 := 6
batchControlRecordValue9 := "      "
;Originating DFI Identification - This must be the same as in the Batch Header Record, field 12. First eight digits of funding bank's 9-digit routing number.
batchControlRecordPosition10 := 80
batchControlRecordLength10 := 8
batchControlRecordValue10 := SubStr(payrollRoutingNumber, 1, 8)
;Batch Number - This should be the same as in the Batch Header Record, field 13, position 88.
batchControlRecordPosition11 := 88
batchControlRecordLength11 := 7
batchControlRecordValue11 := batchHeaderRecordValue13

;~ File Control Record (The line beginning with '9')
	;~ This record provides a final check on the submitted data. It contains block and batch counts and totals for each type of entry.

;Record Type Code - Identifies this line as a File Control Record, beginning with a '9'.
fileControlRecordPosition1 := 1
fileControlRecordLength1 := 1
fileControlRecordValue1 := "9"
;Batch Count - Number of batches in the file. (If there's no upper limit hit, then this will only ever be "000001".
;If we need to split the batch because of a limit, then this will be "000002".
fileControlRecordPosition2 := 2
fileControlRecordLength2 := 6
fileControlRecordValue2 := "000001"
;Block Count - Total number of blocks in file (records in file, divided by 10).
;If not evently divisible by 10, additional lines of 94 '9's should be added at the end of the file, to make the file's lines total a number divisible by 10.
fileControlRecordPosition3 := 8
fileControlRecordLength3 := 6
fileControlRecordValue3 := "000001"
;Entry / Addenda Count - Total number of Entry Detail Records and Addenda Records in the file. (Basically a count of how many lines begin with a '6' or '7'. 8chars, leading zeros.)
fileControlRecordPosition4 := 14
fileControlRecordLength4 := 8
fileControlRecordValue4 :="00000001"
;Entry Hash - Sum of all the transit routing numbers from all Entry Detail Records.
;(Basically add up all the first 8 digits of routing numbers in the lines beginning with '6', from positions 4-11.)
;10 chars, leading zeros. Truncate to the last 10 characters if the sum has more than 10 characters.
fileControlRecordPosition5 := 22
fileControlRecordLength5 := 10
fileControlRecordValue5 := "0000000001"
;Total Debit Entry Dollar Amount In File - Grand total of how much money was withdrawn from all the entries' accounts. Formatted as 00$$¢¢ (i.e.: "000000012345" would be $123.45).
fileControlRecordPosition6 := 32
fileControlRecordLength6 := 12
fileControlRecordValue6 := "000000012345"
;Total Credit Entry Dollar Amount In File - Grand total of how much money was deposited into all the entries' accounts. Formatted as 00$$¢¢ (i.e.: "000000012345" would be $123.45).
fileControlRecordPosition7 := 44
fileControlRecordLength7 := 12
fileControlRecordValue7 := "000000012345"
;Reserved - Blank. Fill it with 39 blank spaces.
fileControlRecordPosition8 := 56
fileControlRecordLength8 := 39
fileControlRecordValue8 := "                                       "

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