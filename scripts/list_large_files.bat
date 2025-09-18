@echo off
setlocal

if "%~1"=="" (
    echo Usage: %~nx0 ^<path_or_drive^>
    exit /b 1
)

set "TARGET=%~1"

for %%I in ("%TARGET%") do set "RESOLVED=%%~fI"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& { param([string]$target)" ^
  "    try {" ^
  "        if (-not (Test-Path -LiteralPath $target)) {" ^
  "            Write-Error \"The specified path '$target' does not exist.\"; exit 1" ^
  "        }" ^
  "        $limit = 2GB;" ^
  "        $files = Get-ChildItem -LiteralPath $target -File -Recurse -ErrorAction Stop |" ^
  "                 Where-Object { $_.Length -ge $limit } |" ^
  "                 ForEach-Object {" ^
  "                     [PSCustomObject]@{" ^
  "                         DirectoryPath = $_.DirectoryName;" ^
  "                         DirectoryCreationTime = $_.Directory.CreationTime;" ^
  "                         FullPath = $_.FullName;" ^
  "                         SizeBytes = $_.Length;" ^
  "                         CreationTime = $_.CreationTime;" ^
  "                         LastWriteTime = $_.LastWriteTime" ^
  "                     }" ^
  "                 } |" ^
  "                 Sort-Object DirectoryCreationTime, CreationTime, @{ Expression = { $_.SizeBytes }; Descending = $true };" ^
  "        if (-not $files) {" ^
  "            Write-Host \"No files larger than 2 GB were found in $target.\";" ^
  "            exit 0" ^
  "        }" ^
  "        $files | Select-Object FullPath," ^
  "                          @{ Name = 'Size (GB)'; Expression = { '{0:N2}' -f ($_.SizeBytes / 1GB) } }," ^
  "                          @{ Name = 'Creation Time'; Expression = { $_.CreationTime } }," ^
  "                          @{ Name = 'Last Modified'; Expression = { $_.LastWriteTime } } |" ^
  "                 Format-Table -AutoSize" ^
  "    } catch {" ^
  "        Write-Error $_;" ^
  "        exit 1" ^
  "    }" ^
  "  }" -args "%RESOLVED%"
set "ERR=%ERRORLEVEL%"
endlocal & exit /b %ERR%
