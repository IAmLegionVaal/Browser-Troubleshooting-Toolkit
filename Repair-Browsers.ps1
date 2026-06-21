[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [ValidateSet('Edge','Chrome','Firefox','All')][string]$Browser='All',
    [switch]$ClearCache,
    [switch]$ResetPolicies,
    [switch]$RepairShortcuts,
    [switch]$ResetNetwork,
    [switch]$Force,
    [string]$OutputPath="$env:USERPROFILE\Desktop\BrowserRepair"
)
$ErrorActionPreference='Stop'
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
$Log=Join-Path $OutputPath ("repair-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
function Log($m){"$(Get-Date -Format s) $m"|Tee-Object -FilePath $Log -Append}
function IsAdmin{$p=[Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent();$p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}
if(-not($ClearCache-or$ResetPolicies-or$RepairShortcuts-or$ResetNetwork)){throw'Choose at least one repair action.'}
$targets=@();if($Browser-in @('Edge','All')){$targets+='msedge'};if($Browser-in @('Chrome','All')){$targets+='chrome'};if($Browser-in @('Firefox','All')){$targets+='firefox'}
$running=Get-Process -Name $targets -ErrorAction SilentlyContinue
if($running -and -not $Force){throw'Close the selected browsers or rerun with -Force.'}
if($running -and $PSCmdlet.ShouldProcess(($targets-join ', '),'Close browser processes')){$running|Stop-Process -Force}
if($ClearCache){
 $paths=@()
 if($Browser-in @('Edge','All')){$paths+=@("$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache","$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache")}
 if($Browser-in @('Chrome','All')){$paths+=@("$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache","$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache")}
 if($Browser-in @('Firefox','All')){$paths+=Get-ChildItem "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles" -Directory -ErrorAction SilentlyContinue|ForEach-Object{Join-Path $_.FullName 'cache2'}}
 foreach($p in $paths){if(Test-Path $p){if($PSCmdlet.ShouldProcess($p,'Clear browser cache')){Remove-Item "$p\*" -Recurse -Force -ErrorAction SilentlyContinue}}}
 Log 'Browser cache cleanup completed.'
}
if($ResetPolicies){if(-not(IsAdmin)){throw'Administrator rights are required to reset browser policies.'};$keys=@();if($Browser-in @('Edge','All')){$keys+='HKLM:\SOFTWARE\Policies\Microsoft\Edge'};if($Browser-in @('Chrome','All')){$keys+='HKLM:\SOFTWARE\Policies\Google\Chrome'};if($Browser-in @('Firefox','All')){$keys+='HKLM:\SOFTWARE\Policies\Mozilla\Firefox'};foreach($k in $keys){if(Test-Path $k){$backup=(Join-Path $OutputPath (($k-split '\')[-1]+'.reg.txt'));Get-ItemProperty $k|Out-File $backup;if($PSCmdlet.ShouldProcess($k,'Remove managed browser policy key')){Remove-Item $k -Recurse -Force}}};Log'Browser policy keys processed.'}
if($ResetNetwork){if(-not(IsAdmin)){throw'Administrator rights are required for network reset.'};if($PSCmdlet.ShouldProcess('Windows network stack','Flush DNS and reset Winsock')){ipconfig /flushdns|Tee-Object -FilePath $Log -Append;netsh winsock reset|Tee-Object -FilePath $Log -Append;Log'Network reset completed; reboot may be required.'}}
if($RepairShortcuts){$shell=New-Object -ComObject WScript.Shell;Get-ChildItem "$env:USERPROFILE\Desktop" -Filter *.lnk -ErrorAction SilentlyContinue|ForEach-Object{$s=$shell.CreateShortcut($_.FullName);if($s.TargetPath -and -not(Test-Path $s.TargetPath)){Log "Broken shortcut detected: $($_.FullName) -> $($s.TargetPath)"}}}
Log'Repair workflow finished.'
