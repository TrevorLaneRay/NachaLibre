/*
	/=======================================================================\
	|Project Notes
	|	Routing number: 122100024 (Chase Bank, for Arizona?)
	|	Account Number: (9 Digits)
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
scriptVersion := "0.01"
scriptAuthor := "TrevorLaneRay"
;Create a little tray icon info.
NachaIconFile := "NachaIcon.ico"
busyIconFile := "NachaBusyIcon.ico"
errorIconFile := "NachaErrorIcon.ico"
A_IconTip := "NachaLibre v." . scriptVersion
A_ScriptName := "NachaLibre"
if FileExist(NachaIconFile)
    TraySetIcon NachaIconFile

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
Hotkey "F11", ReadCSVFileTest

/*
	/=======================================================================\
	|Script Functions
	|	Core functions of the script here.
	|	Reliable functions go here ONLY after extensive testing.
	\=======================================================================/
*/

/*
	/=======================================================================\
	|Beta Functions
	|	Here be dragons.
	|	Functions here are under active development.
	\=======================================================================/
*/

ReadCSVFileTest(HotkeyName) ;Test for parsing the target CSV file, line by line, field by field.
{
	TraySetIcon busyIconFile
	;Load CSV file into an variable.
	csvFile := FileRead("SampleCSV.csv")
	;Create an array for rows.
	CSVArray := []
	;We now go through the CSV, row by row.
	Loop Parse csvFile, "`n"
	{
		;Create an array of columns.
		RowContents := []
		;We now go through each column in the row.
		Loop parse, A_LoopField, ","
		{
			;Add the column content into the array of column items.
			RowContents.Push(A_LoopField)
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

OutputAuditFile(*) ;Test to output summary of transactions, and maintain running totals.
{
	; Should output amounts deposited to each account.
	return
}

CreateFile(*) ;Test to create a blank Nacha file.
{
	return
}

DeleteFile(*) ;Test to delete any preexisting Nacha file.
{
	;TODO: Pass this function a file as an argument, so we don't hard-code the file pathname.
	TraySetIcon busyIconFile
	;Delete existing Nacha file if it already exists.
	while FileExist("BlankNachaFile.ach")
	{
		if (A_Index >= 5)
		{
			;Give a heads-up if the file refuses to be deleted.
			TraySetIcon ErrorIconFile
			MsgBox "It just... won't... die.`nCouldn't delete the existing file after five tries.", "Couldn't Delete File", "Icon!"
			TraySetIcon NachaIconFile
			return
		}
		FileDelete("BlankNachaFile.ach")
		Sleep 200
		if FileExist("BlankNachaFile.ach")
		{
			;If the file still exists, attempt to delete it again.
			continue
		}
		if !FileExist("BlankNachaFile.ach")
		{
			MsgBox "There was a Nacha file.`nNow there is not.`nCarry on.", "Preexisting Nacha file removed.", "Iconi"
			TraySetIcon NachaIconFile
			return
		}
	}
	TraySetIcon NachaIconFile
	return
}