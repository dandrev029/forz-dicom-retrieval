# FORZ DICOM Retrieval Tool

A Python utility for scanning and retrieving patient DICOM images from Shinagawa Healthcare's NAS backup storage used by the FORZ PACS system.

## Background

FORZ PACS stores mammography and other DICOM study images on NAS#1 (`\\192.168.72.18\ExcelCreateBackups\FORZ2FILE\`) with automatic daily backups. NAS#2 (`\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\`) holds a manual copy with a different folder hierarchy.

The folder structure is:

```
NAS (hierarchical):
└── YYYY FILES/
    └── MMM/           (JAN, FEB, MAR, ...)
        └── MMDDYYYY/  (e.g., 05022025)
            └── XXXX/  (patient subfolder, e.g., 1339)
                └── *.dcm files

NAS (flat — NAS#1 auto-backup):
└── MMDDYYYY/          (e.g., 05022025)
    └── XXXX/          (patient subfolder)
        └── *.dcm files
```

## Features

- **Scan** any FORZ NAS folder and list all patients with metadata
- **Search** by patient ID or name
- **Progress indicator** for large folder sets (100+ subfolders)
- Uses `pydicom` to read DICOM headers without loading pixel data (fast)

## Requirements

- Python 3.8+
- `pydicom` (`pip install pydicom`)
- Network access to the NAS shares

## Usage

### Scan all patients in a daily folder

```powershell
py scan_dicom.py "\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\2025 FILES\MAY\05022025"
```

### Search for a specific patient

```powershell
py scan_dicom.py "\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\2025 FILES\MAY\05022025" 006710
```

### Example output

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

## Network Context

| Device | IP | Share |
|--------|-----|-------|
| NAS#1 | 192.168.72.18 | `\\192.168.72.18\ExcelCreateBackups\FORZ2FILE\` |
| NAS#2 | 192.168.72.28 | `\\192.168.72.28\ExcelCreates\NAS 1 FORZ BACKUP\FORZ2FILE\` |
| FORZ PACS VM | 192.168.72.6 | D:\FORZ\Images (migration source) |

## DICOM Workflow

1. **Scan** NAS folder with this tool to locate patient images
2. **Verify** images in MicroDicom Viewer
3. **Restore** to FORZ PACS
4. **Approval Export** to DAIDAI system

## License

Internal use — Shinagawa Healthcare Solutions Corporation
