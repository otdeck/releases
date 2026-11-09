# Installs an OTDeck NSIS installer silently, checks the files, the version
# and the shortcut, talks to otdeck-mcp, starts OTDeck for 20 s (screenshot),
# then uninstalls silently. Usage:
#   windows.ps1 -Setup <setup.exe> -Want <version> -Tools <n> -Shot <png> [-Dir <install folder>]
# Without -Dir the installer's default folder is used; with it (/D=) e.g. a
# folder with Cyrillic letters, and the app directory is Cyrillic too, so
# paths must stay Unicode end to end.
param([string]$Setup, [string]$Want, [string]$Tools = "", [string]$Shot, [string]$Dir = "")
$ErrorActionPreference = "Stop"

$args_ = @('/S'); if ($Dir) { $args_ += "/D=$Dir" }
$p = Start-Process $Setup -ArgumentList $args_ -Wait -PassThru
if ($p.ExitCode -ne 0) { throw "installer exit code $($p.ExitCode)" }
if ($Dir) { $exe = Get-Item (Join-Path $Dir "OTDeck.exe") -ErrorAction SilentlyContinue }
else {
  $exe = Get-ChildItem -Recurse -Filter OTDeck.exe -Path "$env:ProgramFiles\AKStudio","$env:LOCALAPPDATA\Programs\OTDeck" -ErrorAction SilentlyContinue | Select-Object -First 1
}
if (-not $exe) { throw "OTDeck.exe not found after install" }
$dir = $exe.DirectoryName
"installed into $dir"
Get-ChildItem $dir | Format-Table Name, Length | Out-String | Write-Host
foreach ($f in 'OTDeck.exe','otdeck-mcp.exe','uninstall.exe') { if (-not (Test-Path (Join-Path $dir $f))) { throw "$f missing" } }
$lnk = Get-ChildItem "$env:ProgramData\Microsoft\Windows\Start Menu\Programs","$env:APPDATA\Microsoft\Windows\Start Menu\Programs" -Filter 'OTDeck.lnk' -ErrorAction SilentlyContinue
if (-not $lnk) { throw "Start menu shortcut missing" }

# The version: the uninstall entry (what Settings > Apps shows) must be the
# release; the exe's resource is read the way Explorer shows it.
$v = ""
foreach ($k in 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\AKStudioOTDeck',
               'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\AKStudioOTDeck') {
  $x = (Get-ItemProperty $k -ErrorAction SilentlyContinue).DisplayVersion
  if ($x) { $v = $x; break }
}
$item = (New-Object -ComObject Shell.Application).Namespace($dir).ParseName("OTDeck.exe")
$pv = $item.ExtendedProperty('System.Software.ProductVersion')
"uninstall entry DisplayVersion '$v'; OTDeck.exe ProductVersion '$pv' (FileVersionInfo '$($exe.VersionInfo.ProductVersion)')"
if ($v -notlike "$Want*") { throw "installed version '$v', expected $Want" }
$mv = & (Join-Path $dir "otdeck-mcp.exe") -version
"otdeck-mcp -version: $mv"
if ($mv -notmatch [regex]::Escape($Want)) { throw "otdeck-mcp is not version $Want" }
if ($mv -notmatch 'licence=on') { throw "otdeck-mcp was built without the licence check" }

# A fresh app directory with no licence: the Free plan.
$app = if ($Dir) { Join-Path $env:RUNNER_TEMP "Данные OTDeck" } else { Join-Path $env:RUNNER_TEMP "otdeck-app" }
New-Item -ItemType Directory -Force $app | Out-Null
python "$PSScriptRoot\mcp-check.py" (Join-Path $dir "otdeck-mcp.exe") $app $Tools
if ($LASTEXITCODE -ne 0) { throw "otdeck-mcp check failed" }

$kd = Start-Process $exe.FullName -PassThru
Start-Sleep 20
if ($kd.HasExited) {
  Get-ChildItem -Recurse "$env:APPDATA\OTDeck" -Filter *.log -ErrorAction SilentlyContinue | ForEach-Object { "== $($_.FullName)"; Get-Content $_.FullName -Tail 60 }
  throw "OTDeck exited with code $($kd.ExitCode)"
}
$kd.Refresh()
"window: '$($kd.MainWindowTitle)', memory: $([math]::Round($kd.WorkingSet64/1MB)) MB"
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
[System.Drawing.Graphics]::FromImage($bmp).CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
$bmp.Save($Shot)
Get-ChildItem -Recurse "$env:APPDATA\OTDeck" -Filter *.log -ErrorAction SilentlyContinue | ForEach-Object { "== $($_.FullName)"; Get-Content $_.FullName -Tail 15 }
Get-Process OTDeck, otdeck-mcp -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 3

Start-Process (Join-Path $dir "uninstall.exe") -ArgumentList '/S' -Wait | Out-Null
Start-Sleep 5  # the NSIS uninstaller re-launches itself from %TEMP%
if (Test-Path (Join-Path $dir "OTDeck.exe")) { throw "OTDeck.exe still present after uninstall" }
if (Test-Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\OTDeck.lnk") { throw "Start menu shortcut left after uninstall" }
"uninstalled"
