;Initial location where we assume the settings file will be.
;If it does NOT exist, it will be created with default values.
;If it DOES exist, it will be loaded and used to populate the script's settings variables.
;If the DefaultSettingsFile exists, and specifies a different settings file for custom settings, then we'll look for that file instead, and if it exists, we'll load settings from there.
;Note: While the user can directly edit the DefaultSettingsFile, it's better if they create a copy of it and specify that copy in the DefaultSettingsFile as the location for script settings, and then edit that copy.
    ;This way, if the user accidentally deletes or misconfigures their custom settings file, they can easily reference the original.
    ;In the worst case, the user can delete BOTH the default and custom settings files, and then when they run the script, a new default settings file with default values will be generated for them to reference.
defaultScriptSettingsFile := "ScriptFiles\DefaultSettingsFile.ini" ;Where we'll first look for the settings file.

;Flag to indicate whether we had to create a new default settings file
;(Used later to determine whether to show a message box about the new settings file).
newDefaultSettingsFileCreated := false

;Default Settings File Info
defaultScriptSettingsTimestamp := A_Now ;When this settings file was created (if we're creating a new one).
defaultScriptSettingsVersion := scriptVersion ;What version of the script was used to generate the settings file.
defaultScriptSettingsAuthor := scriptAuthor ;;Who authored the script that created the settings file.

;Default Script-Specific Settings
defaultScriptLogFile := "ScriptLogs\ScriptLog.log" ;Make sure we have somewhere to dump diagnostic info to.
defaultScriptIconFile := "ScriptIcons\ScriptIcon.ico" ;Icon indicating that the script is idle, and ready.
defaultScriptActiveIconFile := "ScriptIcons\ActiveIcon.ico" ;Icon indicating that the script is performing functions.
defaultScriptSuccessIconFile := "ScriptIcons\SuccessIcon.ico" ;Icon indicating that a task has completed successfully.
defaultScriptErrorIconFile := "ScriptIcons\ErrorIcon.ico" ;Icon indicating that an error has occurred.
defaultScriptHungIconFile := "ScriptIcons\HungIcon.ico" ;Icon indicating that something is in progress, but is waiting on something.
defaultScriptWarningIconFile := "ScriptIcons\WarningIcon.ico" ;Icon indicating that a warning has occurred.

;Default Input/Output File/Folder Settings
defaultCSVFileFolderName := "SourceCSVs" ;The default name of the folder for source CSV files.
defaultCSVFileName := "SampleCSV.csv" ;The default name of the CSV file to import.
defaultNachaFileFolderName := "NachaOutput" ;Name for the folder in which to place finalized, validated Nacha files.
defaultNachaFileName := "NachaFile" ;Name of the Nacha file to save.
defaultAuditLogFileFolderName := "AuditLogs" ;Name for the folder in which to store streamlined logs for fiscal audits.
defaultAuditLogFileName := "AuditLog" ;Name of the file in which streamlined transaction logs are stored.

;Default Bank Settings
defaultMaxPayrollAmount := 500000 ;Upper limit of dollars at which to split Nacha submissions (dependent on bank).
defaultPayrollBankName := "BANK NAME" ;Name of the bank the payroll will be sent from.
defaultPayrollCompanyName := "COMPANY NAME" ;Name of your company. Needs to be upper case. A-Z, space, and periods, max 23 chars.
defaultPayrollRecipientCompanyName := "Company Name" ;Name of your company. (Same as above, but will be what appears in an employee's bank statement. Max 16 chars.)
defaultPayrollRoutingNumber := "000000000" ;9-digit routing number of bank from which the payroll will be withdrawn. (Lead with zeros if less than 9 chars.)
defaultPayrollAccountNumber := "000000000000" ;Account number from which the payroll will be withdrawn.
defaultPayrollEIN := "0000000000" ;String to identify the business entity for tax purposes. (Chase specifications say to put zeros??)

;Default Transaction Settings
defaultPayPeriodBeginOffset := -15 ;Date that the pay period began. (By default, two weeks ago).
defaultPayPeriodEndOffset := -2 ;Date that the pay period ended. (By default, two days ago).
defaultPayDayOffset := 1 ;Descriptive date that payday is (Assuming this is tomorrow).
defaultTransactionDayOffset := 1 ;Day that the bank transaction should occur (Assuming this is tomorrow).

if not FileExist(defaultScriptSettingsFile) {
    ;If we have no settings file, use these default values and then write them to a new default settings file.
    newDefaultSettingsFileCreated := true

    ;Write the above default values to the new default settings file.
	IniWrite(defaultScriptSettingsTimestamp, defaultScriptSettingsFile, "SettingsInfo", "SettingsFileCreationTimestamp")
	IniWrite(defaultScriptSettingsVersion, defaultScriptSettingsFile, "SettingsInfo", "SettingsFileCreationVersion")
	IniWrite(defaultScriptSettingsAuthor, defaultScriptSettingsFile, "SettingsInfo", "SettingsFileCreationAuthor")

    IniWrite(defaultScriptSettingsFile, defaultScriptSettingsFile, "ScriptSettings", "SettingsFileLocation")
	IniWrite(defaultScriptLogFile, defaultScriptSettingsFile, "ScriptSettings", "ScriptLogFileLocation")
	IniWrite(defaultScriptIconFile, defaultScriptSettingsFile , "ScriptSettings" , "ScriptIconFile")
	IniWrite(defaultScriptActiveIconFile, defaultScriptSettingsFile, "ScriptSettings", "ScriptActiveIconFile")
	IniWrite(defaultScriptSuccessIconFile, defaultScriptSettingsFile, "ScriptSettings", "ScriptSuccessIconFile")
	IniWrite(defaultScriptErrorIconFile, defaultScriptSettingsFile, "ScriptSettings", "ScriptErrorIconFile")
	IniWrite(defaultScriptHungIconFile, defaultScriptSettingsFile, "ScriptSettings", "ScriptHungIconFile")
    IniWrite(defaultScriptWarningIconFile, defaultScriptSettingsFile, "ScriptSettings", "ScriptWarningIconFile")

    IniWrite(defaultCSVFileFolderName, defaultScriptSettingsFile, "PayrollSettings", "CSVFileFolderName")
    IniWrite(defaultCSVFileName, defaultScriptSettingsFile, "PayrollSettings", "CSVFileName")
    IniWrite(defaultNachaFileFolderName, defaultScriptSettingsFile, "PayrollSettings", "NachaFileFolderName")
    IniWrite(defaultNachaFileName, defaultScriptSettingsFile, "PayrollSettings", "NachaFileName")
    IniWrite(defaultAuditLogFileFolderName, defaultScriptSettingsFile, "PayrollSettings", "AuditLogFileFolderName")
    IniWrite(defaultAuditLogFileName, defaultScriptSettingsFile, "PayrollSettings", "AuditLogFileName")

    IniWrite(defaultMaxPayrollAmount, defaultScriptSettingsFile, "BankSettings", "MaxPayrollAmount")
    IniWrite(defaultPayrollBankName, defaultScriptSettingsFile, "BankSettings", "PayrollBankName")
    IniWrite(defaultPayrollCompanyName, defaultScriptSettingsFile, "BankSettings", "PayrollCompanyName")
    IniWrite(defaultPayrollRecipientCompanyName, defaultScriptSettingsFile, "BankSettings", "PayrollRecipientCompanyName")
    IniWrite(defaultPayrollRoutingNumber, defaultScriptSettingsFile, "BankSettings", "PayrollRoutingNumber")
    IniWrite(defaultPayrollAccountNumber, defaultScriptSettingsFile, "BankSettings", "PayrollAccountNumber")
    IniWrite(defaultPayrollEIN, defaultScriptSettingsFile, "BankSettings", "PayrollEIN")

    ;Payroll Settings (Mercurial. Should optimally be obtained from user during runtime, rather than read from the .ini file.)
    ;If these date values are not present in the .ini file, they will be chosen here by default.
    ;These default values can be used during user prompt to simplify date selection by pre-selecting a date close to what it should be.
    IniWrite(defaultPayPeriodBeginOffset, defaultScriptSettingsFile, "TransactionSettings", "PayPeriodBeginOffset")
    IniWrite(defaultPayPeriodEndOffset, defaultScriptSettingsFile, "TransactionSettings", "PayPeriodEndOffset")
    IniWrite(defaultPayDayOffset, defaultScriptSettingsFile, "TransactionSettings", "PayDayOffset")
    IniWrite(defaultTransactionDayOffset, defaultScriptSettingsFile, "TransactionSettings", "TransactionDayOffset")
}

;Now that we have a default settings file to fall back on, we'll attempt to load settings from it to populate the script's settings variables.
if FileExist(defaultScriptSettingsFile) {
    ;If we have a default settings file, then we'll load settings from there.
    ;But first, check if the settings file specifies a different settings file to use for custom settings.
    ;If so, and if that file exists, then we'll load settings from there instead of the default settings file.
    scriptSettingsFile := IniRead(defaultScriptSettingsFile, "ScriptSettings", "SettingsFileLocation", defaultScriptSettingsFile) ;Location of the .ini file from which to pull script settings. If not specified, will pull from the default settings file.
    if (scriptSettingsFile != defaultScriptSettingsFile) && FileExist(scriptSettingsFile) {
        ;If the specified settings file is different from the default, and it exists, then we'll use that one instead.
        scriptSettingsFile := scriptSettingsFile
    } else {
        ;Otherwise, we'll use the default settings file.
        scriptSettingsFile := defaultScriptSettingsFile
    }

    ;TODO: if the existing settings file (either default or custom)is missing any of the expected settings, we should write those missing settings with default values.
        ;That way, the settings file is always comprehensive and up-to-date with the latest version of the script.

    scriptSettingsTimestamp := IniRead(scriptSettingsFile, "SettingsInfo", "SettingsFileCreationTimestamp", defaultScriptSettingsTimestamp)
    scriptSettingsVersion := IniRead(scriptSettingsFile, "SettingsInfo", "SettingsFileCreationVersion", defaultScriptSettingsVersion)
    scriptSettingsAuthor := IniRead(scriptSettingsFile, "SettingsInfo", "SettingsFileCreationAuthor", defaultScriptSettingsAuthor)

    scriptLogFile := IniRead(scriptSettingsFile, "ScriptSettings", "ScriptLogFileLocation", defaultScriptLogFile)
    scriptIconFile := IniRead(scriptSettingsFile, "ScriptSettings", "ScriptIconFile", defaultScriptIconFile)
    scriptActiveIconFile := IniRead(scriptSettingsFile, "ScriptSettings", "ScriptActiveIconFile", defaultScriptActiveIconFile)
    scriptSuccessIconFile := IniRead(scriptSettingsFile, "ScriptSettings", "ScriptSuccessIconFile", defaultScriptSuccessIconFile)
    scriptErrorIconFile := IniRead(scriptSettingsFile, "ScriptSettings", "ScriptErrorIconFile", defaultScriptErrorIconFile)
    scriptHungIconFile := IniRead(scriptSettingsFile, "ScriptSettings", "ScriptHungIconFile", defaultScriptHungIconFile)
    scriptWarningIconFile := IniRead(scriptSettingsFile, "ScriptSettings", "ScriptWarningIconFile", defaultScriptWarningIconFile)

    csvFileFolderName := IniRead(scriptSettingsFile, "PayrollSettings", "CSVFileFolderName", defaultCSVFileFolderName)
    csvFileName := IniRead(scriptSettingsFile, "PayrollSettings", "CSVFileName", defaultCSVFileName)
    nachaFileFolderName := IniRead(scriptSettingsFile, "PayrollSettings", "NachaFileFolderName", defaultNachaFileFolderName)
    nachaFileName := IniRead(scriptSettingsFile, "PayrollSettings", "NachaFileName", defaultNachaFileName)
    auditLogFileFolderName := IniRead(scriptSettingsFile, "PayrollSettings", "AuditLogFileFolderName", defaultAuditLogFileFolderName)
    auditLogFileName := IniRead(scriptSettingsFile, "PayrollSettings", "AuditLogFileName", defaultAuditLogFileName)

    maxPayrollAmount := IniRead(scriptSettingsFile, "BankSettings", "MaxPayrollAmount", defaultMaxPayrollAmount)
    payrollBankName := IniRead(scriptSettingsFile, "BankSettings", "PayrollBankName", defaultPayrollBankName)
    payrollCompanyName := IniRead(scriptSettingsFile, "BankSettings", "PayrollCompanyName", defaultPayrollCompanyName)
    payrollRecipientCompanyName := IniRead(scriptSettingsFile, "BankSettings", "PayrollRecipientCompanyName", defaultPayrollRecipientCompanyName)
    payrollRoutingNumber := IniRead(scriptSettingsFile, "BankSettings", "PayrollRoutingNumber", defaultPayrollRoutingNumber)
    payrollAccountNumber := IniRead(scriptSettingsFile, "BankSettings", "PayrollAccountNumber", defaultPayrollAccountNumber)
    payrollEIN := IniRead(scriptSettingsFile, "BankSettings", "PayrollEIN", defaultPayrollEIN)

    payPeriodBeginOffset := IniRead(scriptSettingsFile, "TransactionSettings", "PayPeriodBeginOffset", defaultPayPeriodBeginOffset)
    payPeriodEndOffset := IniRead(scriptSettingsFile, "TransactionSettings", "PayPeriodEndOffset", defaultPayPeriodEndOffset)
    payDayOffset := IniRead(scriptSettingsFile, "TransactionSettings", "PayDayOffset", defaultPayDayOffset)
    transactionDayOffset := IniRead(scriptSettingsFile, "TransactionSettings", "TransactionDayOffset", defaultTransactionDayOffset)
} else if not FileExist(scriptSettingsFile){
    ;We just ensured that a default settings file exists, so if we still can't find a settings file at this point, then something has gone horribly wrong.
    ;We'll attempt to log an error and exit the script, since it shouldn't be run without any settings file(s).
    LogEvent("Error", "Couldn't find or create a settings file, so the script should not be run.`nPlease verify that the script has permission to create files in the `"ScriptFiles`" folder, and that there is not some other issue preventing file creation.")
    ExitApp()
}

if newDefaultSettingsFileCreated{
    Run scriptSettingsFile ;Open the newly created default settings file for the user to review.
    LogEvent("Event", "No settings file found, so a new default settings file has been created at " . defaultScriptSettingsFile)
    Sleep(2000) ;Wait for 2 seconds to ensure the file has opened before showing the message box.
    MsgBox("Default Settings File Created, A new default settings file has been created in " . defaultScriptSettingsFile . ".`n`nPlease review this file and adjust settings as necessary for your use case.`nIf you want to use a different settings file for customization, create a copy of this default settings file, specify the name of that copy in the `"SettingsFileLocation`" setting in the default settings file, and then edit that copy with your custom settings.`nIf you have any questions or need assistance, please refer to the documentation or boop Trevor on the nose.`nThe script will now terminate.`nRelaunch once settings are sorted out.", "New Settings File Created", "Iconi")
    ExitApp()
}