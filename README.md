# Browser Troubleshooting Toolkit

A PowerShell toolkit for browser support checks and selected guarded Edge or Chrome repairs.

## Diagnostic script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Browser_Troubleshooting_Toolkit.ps1
```

## Repair script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Browser_Repair_Toolkit.ps1 -Browser Edge -ClearCache -DryRun
```

Examples:

```powershell
.\Browser_Repair_Toolkit.ps1 -Browser Edge -ClearCache -RestartBrowser
.\Browser_Repair_Toolkit.ps1 -Browser Chrome -ClearCache
.\Browser_Repair_Toolkit.ps1 -ResetProxy
.\Browser_Repair_Toolkit.ps1 -FlushDns
```

## What the repair does

- Closes and restarts Microsoft Edge or Google Chrome when selected.
- Clears cache, code-cache and GPU-cache folders for the selected browser profile.
- Resets WinHTTP proxy configuration and disables the current user’s manual proxy.
- Flushes the Windows DNS resolver cache.
- Captures browser-process, proxy and DNS state before and after repair.
- Supports `-DryRun`, confirmation prompts, logs and clear exit codes.

## Privacy and safety

The tool does not read or delete browsing history, passwords, cookies, bookmarks or saved form data. Cache clearing closes the selected browser and can discard unsaved form content.

## Author

Dewald Pretorius — L2 IT Support Engineer
