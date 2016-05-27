
if((Get-ChildItem C:\corp\bitlocker | Where-Object {$_.Name -like "*.log" } | Measure-Object | Select Count).Count -eq 0)
{
    exit
}
#Load WinSCP .NET assembly
$ScriptPath = $(Split-Path -Parent $MyInvocation.MyCommand.Definition) 
[Reflection.Assembly]::LoadFrom( $(Join-Path $ScriptPath "WinSCPnet.dll") ) | Out-Null
# Setup session options
$sessionOptions = New-Object WinSCP.SessionOptions
$sessionOptions.Protocol = [WinSCP.Protocol]::ftp
$sessionOptions.FtpSecure = [WinSCP.FtpSecure]::Explicit
$sessionOptions.HostName = "ftp.somesite.com"
#This account should be appropriately restricted server side to only be able to upload small text files, no traversing folders or anything else. Otherwise this password should be encrypted in this file somehow
$sessionOptions.UserName = "domain\user"
$sessionOptions.Password = "password" 

$session = New-Object WinSCP.Session

try
{
    # Connect
    $session.Open($sessionOptions)

    # Upload files
    $transferOptions = New-Object WinSCP.TransferOptions
    $transferOptions.TransferMode = [WinSCP.TransferMode]::Automatic

    $transferResult = $session.PutFiles("*.log", "/", $False, $transferOptions)

    if($transferResult.IsSuccess)
    {
        foreach ($transfer in $transferResult.Transfers)
        {
            Remove-Item $transfer.FileName
        }
    }
    else #error handling, usually file that is already in FTP and cannot be overwritten
    {
        foreach($tran in $transferResult.Transfers)
        {
            Rename-Item $tran.FileName ($tran.Filename + (Get-Random))#will be resent next upload
        }
    }
}
finally
{
    $session.Dispose()
}

exit 0
