## Install on macOS with UTM

Requirements: a current UTM installation and at least 12 GB of free disk space
while the bundle is downloaded and unpacked.

1. Download **`Install-Omarchy-virt.zip`** from the Assets section below.
2. Extract it and run **`install-Omarchy-virt.command`**.
3. Wait while the installer downloads every image part, verifies each SHA-256
   digest, reconstructs the UTM bundle, and opens it in UTM.
4. Complete Omarchy's first-boot owner, keyboard, Git, hostname, and timezone
   setup inside the VM.

Do not download the numbered `Omarchy-virt.utm.zip.part-*` assets manually.
They are below GitHub's per-file size limit and are fetched automatically by
the small installer.

The VM is installed as `~/Downloads/Omarchy-virt.utm` by default. To choose a
different parent directory, run the installer in Terminal with that directory
as its only argument:

```bash
./install-Omarchy-virt.command "/path/for/virtual-machines"
```

If macOS blocks the downloaded command, Control-click it, choose **Open**, and
confirm once. The script itself is readable in this Release and verifies all
downloaded payloads before installation.

Each installation receives a new VM UUID, drive UUID, and locally administered
MAC address. EFI variable storage is deliberately absent from the Release; UTM
creates a clean copy on first launch, so no builder firmware state or boot
entries are reused.

## Host directory sharing

With the VM stopped, select a shared directory in UTM and use **VirtFS**. After
the first-boot owner setup, it appears inside Omarchy as `~/Hostshare` with the
guest user's UID/GID mapped automatically. `/mnt/hostshare` remains the raw 9p
mount for diagnostics.

## Verification and inventory

`SHA256SUMS` covers every Release asset. `release-manifest.json` records the
source commit, complete archive digest, image digest and ordered part list.
`image-provenance.txt` records verified build inputs, while
`image-package-inventory.zip` contains the exact explicit/all package lists,
size/dependency table, and orphan list from the image.
