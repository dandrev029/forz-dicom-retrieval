# FORZ DICOM Retrieval Tool

A Python utility for scanning and retrieving patient DICOM images from Shinagawa Healthcare's NAS backup storage used by the FORZ PACS system.

## Quick Start (First-Time Setup)

Follow these steps **once per PC** to get the tool running.

### Step 1 — Install Python

Check if Python is already installed:

```powershell
py --version
```

If it shows **Python 3.8 or higher**, skip to **Step 2**.

If you get an error, download and install Python from:
https://www.python.org/downloads/

> ⚠️ During installation, check the box **"Add python.exe to PATH"** before clicking Install.

After installing, **close and reopen PowerShell**, then verify:

```powershell
py --version
```

### Step 2 — Install pydicom

```powershell
py -m pip install pydicom
```

> ⚠️ Use `py -m pip` — do NOT use bare `pip` (it may not be in PATH).

### Step 3 — Download the Script

Open PowerShell and run these commands **one at a time**:

```powershell
cd "$env:USERPROFILE\Desktop"
```

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/dandrev029/forz-dicom-retrieval/main/scan_dicom.py" -OutFile "scan_dicom.py"
```

This saves `scan_dicom.py` to your **Desktop**.

### Step 4 — Verify It Works

```powershell
cd "$env:USERPROFILE\Desktop"
py scan_dicom.py
```

You should see:

```
Usage: py scan_dicom.py <NAS_folder_path> [patient_id_or_name]
```

✅ **Setup complete!** You're ready to scan NAS folders.

---

## Usage

### Scan All Patients in a Daily Folder

```powershell
py scan_dicom.py "\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\2025 FILES\MAY\05022025"
```

### Search for a Specific Patient by ID or Name

```powershell
py scan_dicom.py "\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\2025 FILES\MAY\05022025" 006710
```

> 💡 You can search by **patient ID** (e.g., `006710`) or **patient name** (e.g., `MONCADA`).

### Example Output

```
Scanning: \\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\2025 FILES\MAY\05022025
Found 132 subfolders to check

Progress: 0/132 folders checked...
Progress: 10/132 folders checked...
...

======================================================================
Scanned: \\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\2025 FILES\MAY\05022025
Folders with patient data: 132 / 132
======================================================================
Subfolder   Patient Name                        ID         Date         Time
----------------------------------------------------------------------
1339        MONCADA^FRANCO^^BELLA               006710     20250502     13393
======================================================================
```

---

## Common NAS Paths

### NAS#2 (Manual Backup — Hierarchical)

```
\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\
```

| Year | Path Example |
|------|-------------|
| 2025 | `\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\2025 FILES\MAY\05022025` |
| 2024 | `\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\2024 FILES\JUL\07242024` |
| 2023 | `\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\2023 FILES\JAN\01152023` |

### NAS#1 (Auto-Backup — Flat)

```
\\192.168.72.18\ExcelCreateBackups\FORZ2FILE\
```

NAS#1 uses flat `MMDDYYYY` folders directly (no year/month hierarchy).

---

## How It Works

The tool reads DICOM file headers **without loading pixel data**, so it's fast even on large folders. For each patient subfolder, it reads the first `.dcm` file and extracts:

- **Patient Name** (as stored in the DICOM header — use `^` separators)
- **Patient ID**
- **Study Date**
- **Study Time**

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `can't open file 'scan_dicom.py'` | You're not in the Desktop folder. Run `cd "$env:USERPROFILE\Desktop"` first |
| `No module named 'pydicom'` | Run `py -m pip install pydicom` |
| `'py' is not recognized` | Python isn't installed or not in PATH. Reinstall Python with "Add to PATH" checked |
| `Access is denied` on NAS path | Make sure you're connected to the Shinagawa network (on-site or VPN) |
| Script hangs on large folders | Normal for 200+ subfolders — wait for the progress indicator to finish |

---

## Network Reference

| Device | IP | Share Path |
|--------|-----|-----------|
| NAS#1 | 192.168.72.18 | `\\192.168.72.18\ExcelCreateBackups\FORZ2FILE\` |
| NAS#2 | 192.168.72.28 | `\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\` |
| FORZ PACS VM | 192.168.72.6 | `D:\FORZ\Images` (migration source) |

---

## DICOM Workflow

1. **Scan** — Run this tool to locate patient images on the NAS
2. **Verify** — Open the patient subfolder in MicroDicom Viewer
3. **Restore** — Restore the images into FORZ PACS
4. **Export** — Approval Export to DAIDAI system

---

## License

Internal use — Shinagawa Healthcare Solutions Corporation
