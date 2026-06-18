#requires -Version 5.1
<#
.SYNOPSIS
    Browser Troubleshooting Toolkit.
.DESCRIPTION
    Read-only browser support checker. It does not read history, cookies, passwords, or cache.
#>
[CmdletBinding()]
param([string]$OutputPath,[string]$TestUrl='www.microsoft.com')

$RunStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
if ([string]::IsNullOrWhiteSpace($OutputPath)) { $OutputPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Browser_Troubleshooting_Reports' }
New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
function New-Check { param($Category,$Name,$Status,$Value,$Recommendation) [PSCustomObject]@{Category=$Category;Name=$Name;Status=$Status;Value=$Value;Recommendation=$Recommendation} }
$checks = @()
$browsers = @(
@{Name='Microsoft Edge';Path="$env:ProgramFiles (x86)\Microsoft\Edge\Application\msedge.exe"},
@{Name='Google Chrome';Path="$env:ProgramFiles\Google\Chrome\Application\chrome.exe"},
@{Name='Mozilla Firefox';Path="$env:ProgramFiles\Mozilla Firefox\firefox.exe"}
)
foreach($b in $browsers){ $found = Test-Path $b.Path; $checks += New-Check 'Browser Install' $b.Name ($(if($found){'OK'}else{'Info'})) $b.Path 'Confirm expected browser is installed.' }
foreach($p in @('msedge','chrome','firefox')){ $proc = Get-Process $p -ErrorAction SilentlyContinue; $checks += New-Check 'Browser Process' $p 'Info' (@($proc).Count) 'Running process count.' }
foreach($hostName in @($TestUrl,'login.microsoftonline.com','www.google.com') | Select-Object -Unique){
try{[void][System.Net.Dns]::GetHostAddresses($hostName);$dns='Resolved'}catch{$dns='DNS failed'}
try{$tcp=Test-NetConnection -ComputerName $hostName -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue}catch{$tcp=$false}
$checks += New-Check 'Connectivity' $hostName ($(if($tcp){'OK'}else{'Warning'})) "DNS=$dns; TCP443=$tcp" 'Review DNS, firewall, proxy, or internet path if this fails.'
}
try{ $proxy = (& netsh.exe winhttp show proxy 2>&1) -join ' '; $checks += New-Check 'Proxy' 'WinHTTP proxy' 'Info' $proxy 'Unexpected proxy context can affect browser access.' }catch{}
$checks | Export-Csv (Join-Path $OutputPath "browser_checks_$RunStamp.csv") -NoTypeInformation -Encoding UTF8
$checks | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $OutputPath "browser_checks_$RunStamp.json") -Encoding UTF8
$checks | ConvertTo-Html -Title 'Browser Troubleshooting' -PreContent "<h1>Browser Troubleshooting - $env:COMPUTERNAME</h1><p>Generated $(Get-Date)</p>" | Set-Content (Join-Path $OutputPath "browser_report_$RunStamp.html") -Encoding UTF8
$checks | Format-Table -AutoSize -Wrap
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
Start-Process explorer.exe -ArgumentList "`"$OutputPath`"" -ErrorAction SilentlyContinue
