; This file is just a primordial test to make sure library inclusion is working properly.
LibraryFunctionTest(){
    scriptRunTime := DateDiff(A_Now, scriptLaunchTimestamp, "Seconds")
    MsgBox("Timestamp: " . scriptLaunchTimestamp . "`nScript Runtime: " . scriptRunTime . " Seconds`n`nTest library included successfully.", "Library Inclusion Test", "Iconi")
    return
}