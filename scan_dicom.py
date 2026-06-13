#!/usr/bin/env python3
"""
FORZ DICOM Scanner - Shinagawa Healthcare Solutions Corp
Scans FORZ2FILE folders and finds patient studies by name/ID and/or body part.

Usage:
  py scan_dicom.py <folder_path> [patient_id_or_name] [body_part]

Examples:
  py scan_dicom.py "\\NAS\FORZ2FILE\06052026" VALDEZ
  py scan_dicom.py "\\NAS\FORZ2FILE\06052026" VALDEZ CHEST
  py scan_dicom.py "\\NAS\FORZ2FILE\06052026" "" CHEST
"""

import os, sys, json
import pydicom
from pathlib import Path

def scan_folder(root_path, target_patient="", target_bodypart=""):
    root = Path(root_path)
    print(f"Scanning: {root}")
    bodypart = target_bodypart.strip().upper()

    # Only look at immediate subdirectories (numbered folders like 0750, 0831...)
    subfolders = sorted([d for d in root.iterdir() if d.is_dir()])
    total = len(subfolders)
    print(f"Found {total} subfolders to check\n")

    found_results = []

    for i, folder in enumerate(subfolders):
        # Progress indicator every 20 folders
        if i % 20 == 0 and total > 50:
            print(f"Progress: {i}/{total} folders checked...")

        files = sorted([f for f in folder.iterdir() if f.is_file()])
        if not files:
            continue

        # Read only the FIRST valid DICOM file per folder
        for f in files:
            try:
                ds = pydicom.dcmread(f, stop_before_pixels=True)
                name = str(ds.get("PatientName", "N/A"))
                pid  = str(ds.get("PatientID", "N/A"))
                date = str(ds.get("StudyDate", "N/A"))
                time = str(ds.get("StudyTime", "N/A"))[:5]

                # --- NEW: Body Part fields ---
                bp   = str(ds.get((0x0018, 0x0015), "N/A"))  # BodyPartExamined
                desc = str(ds.get((0x0008, 0x1030), "N/A"))    # StudyDescription

                # Combine: prefer BodyPartExamined, fallback to StudyDescription
                bp_display = bp if bp != "N/A" else desc

                # Filter by body part (if specified)
                bp_match = True
                if bodypart:
                    bp_upper = bp.upper()
                    desc_upper = desc.upper()
                    bodypart_upper = bodypart.upper()
                    bp_match = (bodypart_upper in bp_upper) or (bodypart_upper in desc_upper)

                # Filter by patient (if specified)
                patient_match = True
                if target_patient:
                    t = target_patient.upper()
                    patient_match = (t in pid.upper()) or (t in name.upper())

                if patient_match and bp_match:
                    found_results.append((folder.name, name, pid, date, time, bp_display))

                break  # First file only per folder
            except:
                continue

    # Always print full scan summary
    print(f"\n{'='*75}")
    print(f"Scanned: {root}")
    print(f"Folders with patient data: {len(found_results)} / {total}")
    if bodypart:
        print(f"Body part filter: {target_bodypart}")
    print(f"{'='*75}")
    print(f"{'Folder':<10} {'Patient Name':<30} {'ID':<10} {'Date':<12} {'Time':<8} {'Body Part':<20}")
    print(f"{'-'*75}")
    seen = set()
    for folder, name, pid, date, time, bp in found_results:
        key = (folder, pid)
        if key not in seen:
            seen.add(key)
            print(f"{folder:<10} {name:<30} {pid:<10} {date:<12} {time:<8} {bp:<20}")
    print(f"{'='*75}\n")

    # Print FOUND lines for PS1 parsing (patient match only, or patient+bodypart)
    if target_patient:
        t = target_patient.upper()
        print(f"\nSearching for patient: {target_patient}", end="")
        if bodypart:
            print(f"  +  Body Part: {target_bodypart}")
        else:
            print()
        hit_count = 0
        for folder, name, pid, date, time, bp in found_results:
            if (t in pid.upper()) or (t in name.upper()):
                print(f"   FOUND in folder {folder}: {name} (ID: {pid})  Body Part: {bp}")
                hit_count += 1
        if hit_count == 0:
            print(f"   No matching studies found.")

    # Print body part summary (useful when no patient specified)
    if not target_patient and bodypart:
        print(f"\nFiltered by body part '{target_bodypart}': {len(found_results)} folder(s)")

    # Always emit a machine-readable JSON line at the end for optional PS1 parsing
    json_out = []
    for folder, name, pid, date, time, bp in found_results:
        json_out.append({
            "folder": folder,
            "patient_name": name,
            "patient_id": pid,
            "study_date": date,
            "study_time": time,
            "body_part": bp
        })
    print(f"\n---JSON-START---")
    print(json.dumps(json_out, indent=2))
    print(f"---JSON-END---")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: py scan_dicom.py <NAS_folder_path> [patient_id_or_name] [body_part]")
        print('Example: py scan_dicom.py "\\\\NAS\\FORZ2FILE\\06052026" 006710')
        print('Example: py scan_dicom.py "\\\\NAS\\FORZ2FILE\\06052026" VALDEZ CHEST')
        print('Example: py scan_dicom.py "\\\\NAS\\FORZ2FILE\\06052026" "" "LUMBAR SPINE"')
    else:
        patient = sys.argv[2] if len(sys.argv) > 2 else ""
        bodypart = sys.argv[3] if len(sys.argv) > 3 else ""
        scan_folder(sys.argv[1], patient, bodypart)
