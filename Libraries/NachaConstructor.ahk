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
		;Panic if the routing number is not 9 digits, as that would invalidate the entire file and cause it to be rejected by the bank.
		;(This should be checked before we even attempt to construct the line, to avoid generating an invalid file.)
		if StrLen(CSVField5Array[A_Index]) != 9 {
			LogEvent("Error", "Truncated Employee Routing Number for entry " . A_Index . ".`nOffending routing number: " . CSVField5Array[A_Index] . "`nWe'll abort for now.`nPlease verify that all routing numbers are 9 digits, including leading zeros if necessary.")
			Reload ;For now, we'll just restart the script to prevent generating an invalid NACHA file.
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