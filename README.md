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

## Usage

### Step 1 — Scan All Patients in a Daily Folder

Before searching, run a full scan to see all patients in the folder:

```powershell
py scan_dicom.py "\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\2025 FILES\MAY\05022025"
```

### Step 2 — Search for a Specific Patient

The tool supports **flexible search** — you can search by **patient ID**, **patient name**, or **partial matches** of either. The search is **case-insensitive** and works as a **substring match**, so you don't need the exact full value.

#### 🔍 How Search Works

```
py scan_dicom.py "<NAS_PATH>" <search_term>
```

- The second argument (`<search_term>`) is searched against **both** Patient ID **and** Patient Name
- **Partial matches work** — you can type just part of the ID or name
- **Case doesn't matter** — `moncada`, `MONCADA`, and `Moncada` all work the same
- **Multiple results** — if the search term matches multiple patients, all matches are shown

---

#### 📋 Search Examples

**By Full Patient ID:**
```powershell
py scan_dicom.py "\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\2025 FILES\MAY\05022025" 006710
```
→ Finds: `MONCADA^FRANCO^^BELLA` (ID: 006710)

**By Partial Patient ID:**
```powershell
py scan_dicom.py "\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\2025 FILES\MAY\05022025" 0149
```
→ Finds: ALL patients whose ID contains `0149` (e.g., 014948, 014952, 014946, etc.)

**By Last Name:**
```powershell
py scan_dicom.py "\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\2025 FILES\MAY\05022025" DELOS REYES
```
→ Finds: all patients with "DELOS REYES" in their name

**By Partial Name:**
```powershell
py scan_dicom.py "\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\2025 FILES\MAY\05022025" MONC
```
→ Finds: `MONCADA` (partial match works)

**By First Name:**
```powershell
py scan_dicom.py "\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\2025 FILES\MAY\05022025" MARK
```
→ Finds: all patients named MARK (e.g., ABUYUAN^MARK)

**By Any Name Fragment:**
```powershell
py scan_dicom.py "\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\2025 FILES\MAY\05022025" SONYA
```
→ Finds: `VASQUEZ^-^RODRIGUEZ^^SONIA` (SONIA matches SONYA? No — exact substring only)
→ Actually: finds nothing if SONYA isn't in the DICOM header. Use `SONIA` instead.

---

#### ⚡ Quick Reference Table

| What you know | What to type | Example |
|---------------|-------------|---------|
| Full Patient ID | The complete ID | `006710` |
| Partial Patient ID | Any part of the ID | `0149` or `6710` |
| Last name | The last name | `MONCADA` |
| First name | The first name | `MARK` |
| Full name | Last + First | `MONCADA MARK` |
| Partial name | Any fragment | `MONC` or `DELOS` |

---

#### 💡 Pro Tips

1. **If you don't know the date**, scan a broader range — check the year folder first:
   ```powershell
   py scan_dicom.py "\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\2025 FILES\MAY"
   ```

2. **If you get too many results**, add more characters to narrow it down:
   - `0149` → many results
   - `01494` → fewer results
   - `014948` → exact match

3. **DICOM names use `^` separators**: `LAST^FIRST^MIDDLE^SUFFIX`. When searching, ignore the `^` — just type the name naturally.

---

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
