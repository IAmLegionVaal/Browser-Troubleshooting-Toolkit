[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param(
 [ValidateSet('Edge','Chrome')][string]$Browser='Edge',
 [switch]$ClearCache,
 [switch]$ResetProxy,
 [switch]$RestartBrowser,
 [switch]$FlushDns,
 [switch]$DryRun,
 [switch]$Yes,
 [string]$OutputPath=(Join-Path $env:LOCALAPPDATA 'BrowserRepairReports')
)
$ErrorActionPreference='Stop';$script:Failures=0;$script:Actions=0
$run=Join-Path $OutputPath (Get-Date -Format yyyyMMdd_HHmmss);New-Item -ItemType Directory $run -Force|Out-Null
$log=Join-Path $run 'repair.log';$before=Join-Path $run 'before.json';$after=Join-Path $run 'after.json'
function Log($m){"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m"|Tee-Object -FilePath $log -Append}
function State{[pscustomobject]@{Collected=Get-Date;WinHttpProxy=(& netsh winhttp show proxy|Out-String);UserProxy=Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue|Select-Object ProxyEnable,ProxyServer,AutoConfigURL;Edge=Get-Process msedge -ErrorAction SilentlyContinue|Select-Object Id,StartTime;Chrome=Get-Process chrome -ErrorAction SilentlyContinue|Select-Object Id,StartTime;Dns=(Resolve-DnsName www.microsoft.com -ErrorAction SilentlyContinue|Select-Object -First 3 Name,IPAddress)}}
function Act($d,[scriptblock]$a){$script:Actions++;Log $d;if($DryRun){Log "DRY-RUN: $d";return};try{&$a;Log "SUCCESS: $d"}catch{$script:Failures++;Log "FAILED: $d - $($_.Exception.Message)"}}
State|ConvertTo-Json -Depth 5|Set-Content $before -Encoding UTF8
if(-not($ClearCache -or $ResetProxy -or $RestartBrowser -or $FlushDns)){Write-Error 'Choose at least one repair action.';exit 2}
if(-not $Yes -and -not $DryRun){if((Read-Host 'Apply selected browser repairs? Open tabs may close. Type YES') -ne 'YES'){Log 'Cancelled.';exit 10}}
$processName=if($Browser -eq 'Edge'){'msedge'}else{'chrome'}
$exe=if($Browser -eq 'Edge'){Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'}else{Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'}
if($ClearCache -or $RestartBrowser){Act "Closing $Browser" {Get-Process $processName -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue}}
if($ClearCache){$paths=if($Browser -eq 'Edge'){@("$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache","$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache","$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\GPUCache")}else{@("$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache","$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache","$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache")};foreach($path in $paths){Act "Clearing cache path $path" {if(Test-Path $path){Remove-Item $path -Recurse -Force -ErrorAction Stop}}}}
if($ResetProxy){Act 'Resetting WinHTTP proxy' {& netsh winhttp reset proxy|Out-Null;if($LASTEXITCODE){throw 'netsh failed'}};Act 'Disabling current-user manual proxy' {Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' ProxyEnable 0}}
if($FlushDns){Act 'Flushing DNS cache' {Clear-DnsClientCache}}
if($RestartBrowser){Act "Starting $Browser" {if(Test-Path $exe){Start-Process $exe}else{throw "$Browser executable not found"}}}
Start-Sleep 2;State|ConvertTo-Json -Depth 5|Set-Content $after -Encoding UTF8
if($script:Failures){Log "Completed with $script:Failures failure(s).";exit 20};Log "Repair completed. Actions: $script:Actions";exit 0
