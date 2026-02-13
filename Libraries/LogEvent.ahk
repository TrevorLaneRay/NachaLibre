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