# Powershell-Enable-BitLocker

This tool will clear/reset and enable your TPM and enable Bitlocker to use the TPM. It will also phone home using WinSCP binaries (not included) to upload a log of what happened. It is best used in a login script form and can run indefinitely and will report back the status of the drive. 

During the intial encryption it will save a copy of the recovery key which would then be uploaded in the logs and then deleted. 


If you run it as a login script you may want to hide the powershell window. This can be easily done by using a VBS to call the powershell file like so.

```
command = "powershell.exe -nologo -command C:\corp\bitlocker\bitlocker.ps1"
set shell = CreateObject("WScript.Shell")
shell.Run command,0
```
