# FORZ Patient DICOM Retrieval - Shinagawa Healthcare
# v2.1 - Preview ALL studies, manually pick which to copy

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

# --- STEP 3: Patient ---
Write-Host ""
Write-Host "STEP 3: Patient" -ForegroundColor Yellow
$pt = (Read-Host "Name or ID (required)").Trim()
if ([string]::IsNullOrWhiteSpace($pt)) { Write-Host "Required!" -ForegroundColor Red; Read-Host; exit }

# --- STEP 4: Output ---
Write-Host ""
Write-Host "STEP 4: Output folder" -ForegroundColor Yellow
$df = Read-Host "Enter for default (C:\FORZEXTRACT)"
if ([string]::IsNullOrWhiteSpace($df)) { $df = "C:\FORZEXTRACT" }
if (-not (Test-Path $df)) { New-Item -ItemType Directory -Path $df -Force | Out-Null }

# --- Check Python script ---
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
Write-Host "  Output:   $df"
Write-Host "  Script:   $script"
Write-Host ""

# --- Scan (NO filter - show ALL studies for patient) ---
$count = (Get-ChildItem $fp -Directory).Count
Write-Host "Scanning $count folders for patient '$pt'..."
Write-Host ""

$out = py $script $fp $pt 2>&1 | Out-String
Write-Host $out

# --- Parse JSON output from Python (machine-readable section) ---
$jsonStart = $out.IndexOf("---JSON-START---")
$jsonEnd   = $out.IndexOf("---JSON-END---")
$allStudies = @()

if ($jsonStart -ge 0 -and $jsonEnd -gt $jsonStart) {
  $jsonRaw = $out.Substring($jsonStart + 16, $jsonEnd - $jsonStart - 16).Trim()
  try {
    $allStudies = $jsonRaw | ConvertFrom-Json
  } catch {
    Write-Host "Warning: Could not parse JSON results" -ForegroundColor Yellow
  }
}

if ($allStudies.Count -eq 0) {
  Write-Host "No studies found for '$pt' on this date." -ForegroundColor Red
  Write-Host "Try a different date or NAS." -ForegroundColor Yellow
  Read-Host; exit
}

# --- Show study picker ---
Write-Host ("="*60) -ForegroundColor Cyan
Write-Host "  STUDIES FOUND FOR: $pt" -ForegroundColor Cyan
Write-Host ("="*60) -ForegroundColor Cyan
Write-Host ""

$i = 1
$studyMap = @{}
foreach ($s in $allStudies) {
  $num = $i.ToString("00")
  $fn  = $s.folder
  $desc = $s.study_description -replace "null|N/A", "-"
  $bp   = $s.body_part -replace "null|N/A", "-"
  $sz   = if ($s.size_mb) { $s.size_mb.ToString("F1") + " MB" } else { "?" }

  Write-Host ("  [{0}] Folder {1}" -f $num, $fn) -ForegroundColor Yellow
  Write-Host ("      Study: {0}" -f $desc)
  Write-Host ("      Body:  {0}" -f $bp)
  Write-Host ("      Size:  {0}" -f $sz)
  Write-Host ""

  $studyMap[$num] = $fn
  $i++
}

# --- Ask which to copy ---
Write-Host "Which folders to copy?" -ForegroundColor Yellow
Write-Host "  Examples: 01,03,05  or  01-05  or  ALL"
$pick = Read-Host "Enter choices"

# Parse selection
$selected = @()
if ($pick.ToUpper() -eq "ALL") {
  $selected = $studyMap.Values | ForEach-Object { $_ }
} else {
  # Support comma-separated and ranges (01-05)
  $pick -split "," | ForEach-Object {
    $part = $_.Trim()
    if ($part -match "^(\d+)-(\d+)$") {
      $start = [int]$matches[1]
      $end   = [int]$matches[2]
      for ($n = $start; $n -le $end; $n++) {
        $key = $n.ToString("00")
        if ($studyMap.ContainsKey($key)) { $selected += $studyMap[$key] }
      }
    } else {
      $key = $part.PadLeft(2, "0")
      if ($studyMap.ContainsKey($key)) { $selected += $studyMap[$key] }
    }
  }
}

$selected = $selected | Select-Object -Unique
if ($selected.Count -eq 0) {
  Write-Host "No valid selections. Exiting." -ForegroundColor Red
  Read-Host; exit
}

Write-Host ("Selected " + $selected.Count + " folder(s): " + ($selected -join ", ")) -ForegroundColor Green
Write-Host ""

# --- COPY ---
Write-Host ("-"*60)
Write-Host "COPYING..." -ForegroundColor Yellow
Write-Host ("-"*60)
$lg = "$env:USERPROFILE\Desktop\FORZ_Log.txt"
"FORZ Patient Retrieval" | Out-File $lg
"Date: "+(Get-Date) | Out-File $lg -Append
"Patient: "+$pt | Out-File $lg -Append
"" | Out-File $lg -Append

$ts=[long]0; $cp=0
foreach ($fn in $selected) {
  $src = "$fp\$fn"
  $dst = "$df\${fn}_${pt}"
  if (Test-Path $dst) {
    Write-Host ("  Skip $fn (exists)") -ForegroundColor Yellow
    continue
  }
  Write-Host ("  Copying $fn...") -NoNewline
  robocopy $src $dst /E /R:2 /W:3 /NP /NDL /NJH /NJS /LOG+:$lg > $null
  $sz = [long](Get-ChildItem $dst -Recurse -File | Measure-Object -Property Length -Sum).Sum
  $ts+=$sz; $cp++
  Write-Host (" OK "+[math]::Round($sz/1MB,1)+" MB") -ForegroundColor Green
}

Write-Host ""
Write-Host ("="*60) -ForegroundColor Cyan
Write-Host "  RESULTS" -ForegroundColor Cyan
Write-Host ("="*60) -ForegroundColor Cyan
Write-Host "  Patient:   $pt"
Write-Host "  Copied:    $cp folder(s)"
Write-Host "  Total:     "+[math]::Round($ts/1MB,2)+" MB"
Write-Host "  Saved to:  $df"
Write-Host "  Log:       $lg" -ForegroundColor Yellow
Write-Host ""

Get-ChildItem $df -Directory | Where-Object { $_.Name -match $pt } | ForEach-Object {
  $s = [long](Get-ChildItem $_.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum
  Write-Host ("  "+$_.Name+" - "+[math]::Round($s/1MB,1)+" MB")
}
Write-Host ""
Write-Host "  COMPLETE!" -ForegroundColor Green
Read-Host
