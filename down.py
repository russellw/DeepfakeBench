import os
import sys
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DATA = ROOT / "datasets"
DATA.mkdir(exist_ok=True)

def run(cmd):
    print(f"\n$ {' '.join(cmd)}")
    proc = subprocess.run(cmd, shell=False)
    if proc.returncode != 0:
        print(f"[WARN] Command failed: {' '.join(cmd)}")
    return proc.returncode

def unzip_all(archive_dir, dest_dir):
    archive_dir = Path(archive_dir)
    dest_dir = Path(dest_dir)
    for z in archive_dir.glob("*.zip"):
        print(f"Unzipping {z.name} -> {dest_dir}")
        with zipfile.ZipFile(z, 'r') as zip_ref:
            zip_ref.extractall(dest_dir)

def ensure_dirs():
    # Create typical DeepfakeBench layout buckets
    (DATA / "DFDC").mkdir(parents=True, exist_ok=True)
    (DATA / "UADFV").mkdir(parents=True, exist_ok=True)
    (DATA / "FaceForensics++").mkdir(parents=True, exist_ok=True)
    (DATA / "Celeb-DF-v2").mkdir(parents=True, exist_ok=True)

def have_kaggle():
    try:
        return run(["kaggle", "--version"]) == 0
    except FileNotFoundError:
        return False

def download_dfdc():
    """
    Deepfake Detection Challenge (full/parts) via Kaggle competitions API.
    You must be logged in with kaggle.json and have accepted the competition rules:
    https://www.kaggle.com/competitions/deepfake-detection-challenge/data
    """
    dest = DATA / "DFDC"
    dest.mkdir(exist_ok=True)
    if not have_kaggle():
        print("[INFO] Kaggle CLI not found. Skipping DFDC.")
        print("       Install with: pip install kaggle")
        return
    # This pulls the available zip parts into dest. It’s huge; expect hundreds of GB if you grab all.
    code = run(["kaggle", "competitions", "download", "-c", "deepfake-detection-challenge", "-p", str(dest)])
    if code == 0:
        unzip_all(dest, dest)
    else:
        print("[WARN] DFDC download did not complete. Make sure you accepted the rules on Kaggle.")

def download_uadfv():
    """
    UADFV via Kaggle dataset.
    Page: https://www.kaggle.com/datasets/adityakeshri9234/uadfv-dataset
    """
    dest = DATA / "UADFV"
    dest.mkdir(exist_ok=True)
    if not have_kaggle():
        print("[INFO] Kaggle CLI not found. Skipping UADFV.")
        return
    code = run(["kaggle", "datasets", "download", "-d", "adityakeshri9234/uadfv-dataset", "-p", str(dest)])
    if code == 0:
        unzip_all(dest, dest)
    else:
        print("[WARN] UADFV download failed.")

def info_faceforensics():
    """
    FaceForensics++ requires an access request. Once you’re approved they email you a link
    to their download script (covers FF++ and includes the Google/Jigsaw DeepFakeDetection set).
    """
    print("\n[Action Required] FaceForensics++ (FF++)")
    print("  Access request form (official):")
    print("   - https://github.com/ondyari/FaceForensics  (see Access section)")
    print("   - Direct form link is referenced there; submit and wait for approval.")
    print("  After approval you'll receive a download script; run it and place data under:")
    print(f"   - {DATA / 'FaceForensics++'}")
    print("  The FF++ page also notes it hosts Google/Jigsaw 'Deep Fake Detection' dataset as part of the bundle.\n")

    print("[Optional helper] If you receive Google Drive links/files and prefer gdown, you can use:")
    print("   gdown <FILE_ID> -O datasets/FaceForensics++\n")

def info_celebdf():
    """
    Celeb-DF v2 also requires filling a request form; link sent after approval.
    """
    print("\n[Action Required] Celeb-DF (v2)")
    print("  Request access via the project GitHub / website:")
    print("   - https://github.com/yuezunli/celeb-deepfakeforensics")
    print("   - https://cse.buffalo.edu/~siweilyu/celeb-deepfakeforensics.html")
    print("  After approval you’ll get download links. Put the files under:")
    print(f"   - {DATA / 'Celeb-DF-v2'}")
    print("\n[Optional helper] To fetch from Google Drive with gdown once you have IDs:")
    print("   gdown <FILE_ID> -O datasets/Celeb-DF-v2\n")

def main():
    print("=== DeepfakeBench dataset bootstrap ===")
    ensure_dirs()
    download_dfdc()
    download_uadfv()
    info_faceforensics()
    info_celebdf()
    print("\nDone. Next: place FF++ and Celeb-DF after access is granted, then proceed with any preprocessing your pipeline expects.")

if __name__ == "__main__":
    main()

