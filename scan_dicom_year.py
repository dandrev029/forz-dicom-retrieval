import os, sys
import pydicom
from pathlib import Path

def scan_year_folder(year_path, search_term):
    """Scan all month/day folders under a year folder to find a patient by name."""
    root = Path(year_path)
    print(f"Scanning year folder: {root}")
    print(f"Searching for: {search_term}\n")

    # Get all month folders (JAN, FEB, etc.)
    month_folders = sorted([d for d in root.iterdir() if d.is_dir()])
    print(f"Found {len(month_folders)} month folders\n")

    found = []
    total_scanned = 0

    for month_dir in month_folders:
        print(f"\n--- Scanning {month_dir.name} ---")
        # Get all day folders inside the month
        day_folders = sorted([d for d in month_dir.iterdir() if d.is_dir()])
        print(f"  {len(day_folders)} day folders")

        for day_dir in day_folders:
            # Get patient subfolders inside the day folder
            patient_folders = sorted([d for d in day_dir.iterdir() if d.is_dir()])
            for pf in patient_folders:
                files = sorted([f for f in pf.iterdir() if f.is_file()])
                if not files:
                    continue
                for f in files:
                    try:
                        ds = pydicom.dcmread(f, stop_before_pixels=True)
                        name = str(ds.get("PatientName", "N/A"))
                        pid = str(ds.get("PatientID", "N/A"))
                        date = str(ds.get("StudyDate", "N/A"))
                        total_scanned += 1

                        # Search match (case-insensitive)
                        target = search_term.upper()
                        if target in name.upper() or target in pid.upper():
                            found.append((month_dir.name, day_dir.name, pf.name, name, pid, date))
                            print(f"  *** FOUND in {month_dir.name}/{day_dir.name}/{pf.name}: {name} (ID: {pid}, Date: {date})")
                        break
                    except:
                        continue

    print(f"\n{'='*70}")
    print(f"Search complete. Scanned {total_scanned} patient records.")
    print(f"Found {len(found)} match(es) for '{search_term}'")
    print(f"{'='*70}")

    if found:
        print(f"\n{'Month':<6} {'Day':<10} {'Folder':<10} {'Patient Name':<35} {'ID':<10} {'Date':<12}")
        print(f"{'-'*83}")
        for month, day, folder, name, pid, date in found:
            print(f"{month:<6} {day:<10} {folder:<10} {name:<35} {pid:<10} {date:<12}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: py scan_dicom_year.py <year_folder_path> <patient_name>")
        print('Example: py scan_dicom_year.py "\\\\192.168.72.28\\ExcelCreates\\NAS 1 FORZ BACKUP\\FORZ2FILE\\2025 FILES" BAUTISTA')
        print()
        print("This script scans ALL month/day folders in a year to find a patient.")
        print("Use this when you don't know the exact date of the procedure.")
        print("For known dates, use scan_dicom.py with the specific day folder instead.")
    else:
        scan_year_folder(sys.argv[1], sys.argv[2])
