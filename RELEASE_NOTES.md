## Quick install with EZVM

Install EZVM 5.0.0 or newer, then run:

```bash
/bin/bash -o pipefail -c 'curl -fsSL https://github.com/everettjf/omarchy-aarch64-image/releases/latest/download/install-Omarchy-ezvm.command | /bin/bash'
```

The installer downloads and verifies every split raw-image payload, verifies
the reconstructed disk, and asks EZVM to create a new `.ezvm` machine with a
fresh machine identifier and EFI variable store. No firmware state or host
identity is distributed in the image.

## Quick install with UTM

Requirements: a current UTM installation and at least 12 GB of free disk space
while the bundle is downloaded and unpacked.

Open Terminal and run:

```bash
/bin/bash -o pipefail -c 'curl -fsSL https://github.com/everettjf/omarchy-aarch64-image/releases/latest/download/install-Omarchy-virt.command | /bin/bash'
```

The command fetches the small installer from the latest Release. It then
downloads every image part, verifies each SHA-256 digest, reconstructs the UTM
bundle, installs it as `~/Downloads/Omarchy-virt.utm`, and opens it in UTM.
Complete Omarchy's owner, keyboard, Git, hostname, and timezone setup inside
the VM.

To choose a different parent directory:

```bash
/bin/bash -o pipefail -c 'curl -fsSL https://github.com/everettjf/omarchy-aarch64-image/releases/latest/download/install-Omarchy-virt.command | /bin/bash -s -- "$1"' _ "/path/for/virtual-machines"
```

For a GUI-oriented alternative, download **`Install-Omarchy-virt.zip`** from
the Assets section, extract it, and run **`install-Omarchy-virt.command`**. If
macOS blocks the downloaded command, Control-click it, choose **Open**, and
confirm once.

Do not download the numbered `Omarchy-virt.utm.zip.part-*` assets manually.
They are below GitHub's per-file size limit and are fetched automatically by
the small installer.

The script itself is readable in this Release and verifies all downloaded
payloads before installation.

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
