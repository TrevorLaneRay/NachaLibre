ReadCSVFile(fileNameToRead) ;Parse the target CSV file, line by line, field by field.
{
	if FileExist(scriptActiveIconFile)
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
            ;Note: Here would be a great opportunity to add some error handling, in case of typos, malformed fields, or other issues with the CSV file. For now, we just trim whitespace and dollar signs, and move on.
			CSVField%A_Index%Array.Push(Trim(A_LoopField,"$ `r`n"))
		}
	}

	LogEvent("Event", "CSV successfully processed.`nCSV File Lines: " . csvLineCount)
	TraySetIcon scriptIconFile
	return
}