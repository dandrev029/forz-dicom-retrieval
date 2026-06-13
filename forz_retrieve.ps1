# FORZ Patient DICOM Retrieval - Shinagawa Healthcare
# Modified: Added body part / study type filter

# --- Config ---
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PythonScript = Join-Path $ScriptDir "scan_dicom.py"

function Show-Banner {
    Clear-Host
    Write-Host ("="*60) -ForegroundColor Cyan
    Write-Host "  FORZ PATIENT DICOM RETRIEVAL TOOL" -ForegroundColor Cyan
    Write-Host "  Shinagawa Healthcare Solutions Corp" -ForegroundColor Cyan
    Write-Host ("="*60) -ForegroundColor Cyan
    Write-Host ""
}
Show-Banner

# --- STEP 1: NAS ---
Write-Host "STEP 1: Which NAS?" -ForegroundColor Yellow
Write-Host "  [1] NAS #1 - 192.168.72.18"
Write-Host "  [2] NAS #2 - 192.168.72.28"
Write-Host "  [3] Custom path"
$c = Read-Host "Enter (1-3)"
if ($c -eq "1") { $p = "\\192.168.72.18\ExcelCreateBackups\FORZ2FILE"; $n = "NAS#1" }
elseif ($c -eq "2") {
  Write-Host ""
  Write-Host "  [a] 2024 FILES  [b] 2025 FILES  [c] 2026 FILES  [d] Manual"
  $y = Read-Host "Year (a-d)"
  switch ($y.ToLower()) {
    "a" { $yf = "2024 FILES" }
    "b" { $yf = "2025 FILES" }
    "c" { $yf = "2026 FILES" }
    default { $yf = Read-Host "Enter year folder" }
  }
  $m = Read-Host "Month (e.g., MAY, JUN)"
  $p = "\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\$yf\$m"
  $n = "NAS#2\$yf\$m"
}
else { $p = Read-Host "Enter full NAS path"; $n = "Custom" }

# --- STEP 2: Date ---
Write-Host ""
Write-Host "STEP 2: Date" -ForegroundColor Yellow
$d = Read-Host "MMDDYYYY (e.g., 06052026)"
$fp = "$p\$d"
Write-Host "  Path: $fp"

# --- STEP 3: Body Part (NEW) ---
Write-Host ""
Write-Host "STEP 3: Body Part / Study Type" -ForegroundColor Yellow
Write-Host "  (Press Enter to skip — find ALL body parts)"
Write-Host "  Common options:"
Write-Host "    [1] CHEST              [2] ABDOMEN"
Write-Host "    [3] HEAD               [4] LUMBAR SPINE"
Write-Host "    [5] CERVICAL SPINE     [6] THORACIC SPINE"
Write-Host "    [7] KNEE               [8] PELVIS"
Write-Host "    [9] WHOLE BODY         [0] Type custom"
$bp_choice = Read-Host "Enter (0-9, or Enter to skip)"
switch ($bp_choice) {
  "1"  { $bp = "CHEST" }
  "2"  { $bp = "ABDOMEN" }
  "3"  { $bp = "HEAD" }
  "4"  { $bp = "LUMBAR SPINE" }
  "5"  { $bp = "CERVICAL SPINE" }
  "6"  { $bp = "THORACIC SPINE" }
  "7"  { $bp = "KNEE" }
  "8"  { $bp = "PELVIS" }
  "9"  { $bp = "WHOLE BODY" }
  "0"  { $bp = Read-Host "Enter body part/study name" }
  default { $bp = "" }
}
if ($bp) { Write-Host "  Filtering by: $bp" -ForegroundColor Green }
else { Write-Host "  No filter — will find ALL body parts" -ForegroundColor Yellow }

# --- STEP 4: Patient ---
Write-Host ""
Write-Host "STEP 4: Patient" -ForegroundColor Yellow
$pt = (Read-Host "Name or ID (required)").Trim()
if ([string]::IsNullOrWhiteSpace($pt)) { Write-Host "Required!" -ForegroundColor Red; Read-Host; exit }

# --- STEP 5: Output ---
Write-Host ""
Write-Host "STEP 5: Output folder" -ForegroundColor Yellow
$df = Read-Host "Enter for default (C:\FORZEXTRACT)"
if ([string]::IsNullOrWhiteSpace($df)) { $df = "C:\FORZEXTRACT" }
if (-not (Test-Path $df)) { New-Item -ItemType Directory -Path $df -Force | Out-Null }

# --- Check Python script (bundled copy first, then Desktop fallback) ---
$script = $PythonScript
if (-not (Test-Path $script)) {
  $script = "$env:USERPROFILE\Desktop\scan_dicom.py"
}
if (-not (Test-Path $script)) {
  Write-Host "`nERROR: scan_dicom.py not found!" -ForegroundColor Red
  Write-Host "Expected at: $PythonScript" -ForegroundColor Yellow
  Write-Host "Or at: $env:USERPROFILE\Desktop\scan_dicom.py" -ForegroundColor Yellow
  Write-Host "Download:" -ForegroundColor Yellow
  Write-Host "https://raw.githubusercontent.com/dandrev029/forz-dicom-retrieval/main/scan_dicom.py"
  Read-Host; exit
}
if (-not (Test-Path $fp)) {
  Write-Host "`nERROR: Date folder not found!" -ForegroundColor Red
  Write-Host "  $fp" -ForegroundColor Yellow
  Write-Host "Check folder exists on the NAS." -ForegroundColor Yellow
  Read-Host; exit
}

# --- Summary ---
Show-Banner
Write-Host "  NAS:      $n"
Write-Host "  Path:     $fp"
Write-Host "  Patient:  $pt"
if ($bp) { Write-Host "  Body Part:$bp" }
Write-Host "  Output:   $df"
Write-Host "  Script:   $script"
Write-Host ""

# --- Scan ---
$count = (Get-ChildItem $fp -Directory).Count
Write-Host "Scanning $count folders..."
Write-Host ""

# Build arguments: path, patient, [body_part]
$py_args = @($fp, $pt)
if ($bp) { $py_args += $bp }
$out = py $script @py_args 2>&1 | Out-String
Write-Host $out

# --- Parse FOUND results (from text output, backward-compatible) ---
$folds = @()
$out -split "`n" | ForEach-Object {
  if ($_ -match "FOUND in folder (\d+):") {
    $fn = $matches[1]
    if ($fn -notin $folds) { $folds += $fn }
  }
}

if ($folds.Count -eq 0) {
  Write-Host "No results for '$pt'" -ForegroundColor Red
  if ($bp) { Write-Host "  with body part filter: $bp" -ForegroundColor Yellow }
  Write-Host "Try a different date, NAS, or remove the body part filter." -ForegroundColor Yellow
  Read-Host; exit
}

Write-Host ("Found " + $folds.Count + " matching folder(s): " + ($folds -join ", ")) -ForegroundColor Green
Write-Host ""

# --- COPY ---
Write-Host ("-"*60)
Write-Host "COPYING..." -ForegroundColor Yellow
Write-Host ("-"*60)
$lg = "$env:USERPROFILE\Desktop\FORZ_Log.txt"
"FORZ Patient Retrieval" | Out-File $lg
"Date: "+(Get-Date) | Out-File $lg -Append
"Patient: "+$pt | Out-File $lg -Append
if ($bp) { "Body Part Filter: "+$bp | Out-File $lg -Append }
"" | Out-File $lg -Append

$ts=0; $cp=0
foreach ($fn in $folds) {
  $src = "$fp\$fn"
  $dst = "$df\${fn}_${pt}"
  if ($bp) { $dst = "$df\${fn}_${pt}_${bp}" }
  if (Test-Path $dst) {
    Write-Host ("  Skip $fn (exists)") -ForegroundColor Yellow
    continue
  }
  Write-Host ("  Copying $fn...") -NoNewline
  robocopy $src $dst /E /R:2 /W:3 /NP /NDL /NJH /NJS /LOG+:$lg > $null
  $sz = (Get-ChildItem $dst -Recurse -File | Measure-Object -Property Length -Sum).Sum
  $ts+=$sz; $cp++
  Write-Host (" OK "+[math]::Round($sz/1MB,1)+" MB") -ForegroundColor Green
}

Write-Host ""
Write-Host ("="*60) -ForegroundColor Cyan
Write-Host "  RESULTS" -ForegroundColor Cyan
Write-Host ("="*60) -ForegroundColor Cyan
Write-Host "  Patient:   $pt"
if ($bp) { Write-Host "  Body Part: $bp" }
Write-Host "  Copied:    $cp folder(s)"
Write-Host "  Total:     "+[math]::Round($ts/1MB,2)+" MB"
Write-Host "  Saved to:  $df"
Write-Host "  Log:       $lg" -ForegroundColor Yellow
Write-Host ""

Get-ChildItem $df -Directory | Where-Object { $_.Name -match $pt } | ForEach-Object {
  $s = (Get-ChildItem $_.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum
  Write-Host ("  "+$_.Name+" - "+[math]::Round($s/1MB,1)+" MB")
}
Write-Host ""
Write-Host "  COMPLETE!" -ForegroundColor Green
Read-Host
