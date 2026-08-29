## Omarchy for EZVM

This Release contains only the verified sparse AArch64 Omarchy image for EZVM.
It is designed for Apple silicon and Apple's Virtualization.framework.

## Quick install

Install or update EZVM and import Omarchy with one command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/everettjf/ezvm/main/scripts/install-omarchy.sh)"
```

Requirements:

- Apple silicon Mac;
- macOS 26 or newer;
- Homebrew; and
- at least 15 GiB free.

If EZVM 1.0.0 or newer is already installed, run the image-only installer:

```bash
/bin/bash -o pipefail -c 'curl -fsSL https://github.com/everettjf/omarchy-aarch64-image/releases/latest/download/install-Omarchy-ezvm.command | /bin/bash'
```

The installer verifies the manifest, every split part, the complete compressed
stream, the reconstructed raw disk, and the bundled thumbnail before asking
EZVM to create a new machine with fresh identity and NVRAM storage.

Do not download the numbered image parts manually. The installer streams,
verifies, decodes, and imports them in the required order.

## Release integrity

The Release is published only after:

- the native AArch64 build and package contracts pass;
- the sparse raw image checksum passes;
- the EZVM release packager verifies its output;
- no asset exceeds GitHub's 2 GiB limit;
- every local Release asset has a valid SHA-256; and
- GitHub reports the same digest for every uploaded asset.

The image remains sparse after import, so its 64 GiB logical disk does not
consume 64 GiB of physical host storage.

The build records provenance and exact package inventories during workflow
verification of the Arch Linux ARM and signed Omarchy inputs.
