/*
	/=======================================================================\
	|IconEncoder
	|	Super simple icon encoder for converting .ico files into Base64 strings that can be stored in variables, and then decoded and written to files when needed.
    |   Inspiration: https://www.reddit.com/r/AutoHotkey/comments/y0l66s/comment/iru0he6/
    |
	|	TODO:
	|		+Some way to decode the Base64 strings back into .ico files, for testing and verification purposes.
	|	Problems:
	|		+No issues so far.
	|	Ideas:
	|		+What if each time we encode an icon, it automatically decodes it, and sets that decoded file as the tray icon? 🤪
    |           +Ridiculous, but it would be a fun way to verify that the encoding and decoding process is working correctly, albeit it'd happen in the blink of an eye.
	\=======================================================================/
*/

;Ensure AHK is running on v2.0, as a 64-bit version.
#Requires AutoHotkey v2.0+ 64-bit
;Make sure only one running instance of the script exists at any given time.
#SingleInstance Force

;Ensure we have UAC permission to actually function.
;(Necessary for writing files to certain locations, and for other functions that require elevated permissions.)
#Include UACCheck.ahk ;This library checks if the script is running with admin privileges, and if not, restarts the script with those privileges.

;Ensure the script has the ability to differentiate between virtual and physical input.
InstallKeybdHook true true

;Version & author of the script.
scriptVersion := "0.1.2"
scriptAuthor := "TrevorLaneRay"
;Create a little tray icon info.
A_IconTip := "IconEncoder v." . scriptVersion
A_ScriptName := "IconEncoder"

#UseHook
Pause::Pause ;Panic button.
+F12::Reload ;Restart the script.
^+F12::ExitApp ;Terminate the script immediately.
F9:: IconEncoder()

IconEncoder(){
    ;Get a list of all .ico files in the ScriptIcons folder, and store their paths and names in arrays.
    IconPathArray := []
    IconFileNameArray := []
    Loop Files "..\ScriptIcons\*.ico" {
        IconPathArray.Push(A_LoopFileFullPath)
        iconName := SubStr(A_LoopFileName, 1, -4) ; Remove the ".ico" extension
        IconFileNameArray.Push(iconName)
    }
    for iconFile in IconPathArray {
        if !FileExist(iconFile){
            Continue
        }
        binaryData := FileRead(iconFile, "Raw")
        fileSize := FileGetSize(iconFile)
        stringLength := 4 * Ceil(fileSize / 3) + 1
        VarSetStrCapacity(&outputString, stringLength)
        flags := 0x40000001
        DllCall("crypt32\CryptBinaryToString", "ptr", binaryData, "uint", fileSize, "uint", flags, "str", outputString, "uint*", &stringLength)
        iconVariableContent := IconFileNameArray[A_Index] . " := `"" . outputString . "`"`n"
        FileAppend(iconVariableContent, "EncodedIcons.ahk")
    }
    return
}