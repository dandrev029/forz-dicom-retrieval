import os, sys
import pydicom
from pathlib import Path

def scan_folder(root_path):
    root = Path(root_path)
    print(f"Scanning: {root}")

    # Only look at immediate subdirectories (the numbered folders like 0750, 0831...)
    subfolders = sorted([d for d in root.iterdir() if d.is_dir()])
    print(f"Found {len(subfolders)} subfolders to check\n")

    found = 0
    results = []

    for i, folder in enumerate(subfolders):
        # Progress indicator every 10 folders
        if i % 10 == 0:
            print(f"Progress: {i}/{len(subfolders)} folders checked...")

        # List files in this subfolder
        files = sorted([f for f in folder.iterdir() if f.is_file()])
        if not files:
            continue

        # Read only the FIRST valid DICOM file to get patient info
        for f in files:
            try:
                ds = pydicom.dcmread(f, stop_before_pixels=True)
                name = str(ds.get("PatientName", "N/A"))
                pid  = str(ds.get("PatientID", "N/A"))
                date = str(ds.get("StudyDate", "N/A"))
                time = str(ds.get("StudyTime", "N/A"))[:5]
                results.append((folder.name, name, pid, date, time))
                found += 1
                break  # Found patient info, move to next folder
            except:
                continue

    # Print results table
    print(f"\n{'='*70}")
    print(f"Scanned: {root}")
    print(f"Folders with patient data: {found} / {len(subfolders)}")
    print(f"{'='*70}")
    print(f"{'Subfolder':<10} {'Patient Name':<35} {'ID':<10} {'Date':<12} {'Time':<8}")
    print(f"{'-'*70}")
    seen = set()
    for folder, name, pid, date, time in results:
        key = (folder, pid)
        if key not in seen:
            seen.add(key)
            print(f"{folder:<10} {name:<35} {pid:<10} {date:<12} {time:<8}")
    print(f"{'='*70}\n")

    # Search mode: find specific patient
    if len(sys.argv) > 2:
        target = sys.argv[2].upper()
        print(f"\nSearching for: {target}")
        for folder, name, pid, date, time in results:
            if target in pid.upper() or target in name.upper():
                print(f"   FOUND in folder {folder}: {name} (ID: {pid})")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: py scan_dicom.py <NAS_folder_path> [patient_id_or_name]")
        print('Example: py scan_dicom.py "\\\\192.168.72.28\\ExcelCreates\\NAS 1 FORZ BACKUP\\FORZ2FILE\\2024 FILES\\JUL\\07192024" 006710')
    else:
        scan_folder(sys.argv[1])