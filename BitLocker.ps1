function Finished
{
    Stop-Transcript
    & c:\corp\bitlocker\LogUpload.ps1
    Exit
}


if(!(Test-Path c:\corp\bitlocker\))
{
    md c:\corp\bitlocker\
}
try
{
    $wmiInfo = Get-wmiobject Win32_Bios
    Start-Transcript -Path "c:\corp\bitlocker\$($env:COMPUTERNAME).$($wmiInfo.SerialNumber).$(get-date -uformat '%Y-%m-%d-%H-%M-%S-%p').log"
    Get-Tpm
    Get-BitLockerVolume
    manage-bde.exe -status c: | find "Protection On"
    if($lastexitcode -eq 0)
    {
        Finished
    }
    manage-bde.exe -status c: | find "Encryption in Progress"
    if($lastexitcode -eq 0)
    {
        Finished
    }

    if ((Get-Tpm | Select -Property TpmReady).TpmReady -eq $False)
    {
        $clear = Initialize-Tpm -AllowClear -AllowPhysicalPresence | Select -Property RestartRequired, ClearRequired
        if($clear.ClearRequired)
        {
            $wshell = New-Object -ComObject Wscript.Shell
            $wshell.Popup("Clear TPM required, contact support.",0,"OK",0x1) 
        }
        if($clear.RestartRequired)
        {
            $wshell = New-Object -ComObject Wscript.Shell
            Stop-Transcript
            & .\LogUpload.ps1
            $wshell.Popup("Reboot Required to initialize TPM, Ok to continue. Note: Computer will reboot immediately, save your work. Durring reboot when prompted press F1 to continue.",0,"OK",0x0)
            Restart-Computer
        }
    }
    else
    {
        $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.Drivetype -eq 3} | Select -Property DeviceID 
        foreach($drive in $drives)
        {
            manage-bde.exe -status $drive.deviceid | find "Protection On"
            if($lastexitcode -eq 1)
            {
                Enable-BitLocker -MountPoint $drive.DeviceID -TpmProtector
                manage-bde.exe -protectors -add -RecoveryPassword $drive.DeviceID | Out-Host
            }
        }
        $wshell = New-Object -ComObject Wscript.Shell
        Stop-Transcript
        & .\LogUpload.ps1
        $wshell.Popup("Reboot Required to start encryption process, OK to continue. Note: Computer will reboot immediately, save your work.",0,"OK",0x0)
        Restart-Computer
    }
    Finished
}Catch{
    $_.Exception.Message
    Stop-Transcript
    $wshell = New-Object -ComObject Wscript.Shell
    $wshell.Popup("Error at line:" + $_.InvocationInfo.ScriptLineNumber + "`nContact helpdesk for assistance 877.678.2743 `n" + $_.Exception.Message,0,"OK",0x0)
    & c:\corp\bitlocker\LogUpload.ps1
    Exit
    
    }
