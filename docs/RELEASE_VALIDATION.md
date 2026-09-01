# EZVM image release and validation

This document records the evidence required before an Omarchy image becomes
the public EZVM `latest` release. A successful build alone is not sufficient.

## Canonical artifacts

The GitHub Release manifest is the canonical installation metadata. It records
the disk's logical size and SHA-256, the complete compressed-stream SHA-256,
and the size and SHA-256 of every numbered part and the thumbnail.

Keep the local raw image until a release has passed the complete download and
installation audit. If a local raw image is removed afterwards, reconstruct it
from the numbered assets using `install-Omarchy-ezvm.command`; do not substitute
an older raw image that happens to have the same product version.

The packager also copies available build evidence into the release layout:

- `image-provenance.txt` records source URLs, commits, signatures, and hashes;
- `*.raw.sha256` identifies the exact raw disk;
- `*.all-packages.txt` and `*.packages.tsv` inventory the installed system; and
- `*.explicit-packages.txt` and `*.orphans.txt` record package state.

## Release procedure

1. Build and boot the native AArch64 raw image.
2. Complete first boot and verify keyboard, mouse, scrolling, modifier keys,
   window resizing, full screen, shutdown, restart, NAT, DNS, HTTPS, and package
   repository access.
3. Package the exact tested raw image:

   ```bash
   ./bin/package-ezvm-release \
     --tag <release-tag> \
     --image build/<tested-image>.raw \
     --output build/release-assets
   ```

4. Run `sha256sum --check SHA256SUMS` in the release directory.
5. Decode the numbered parts into a new sparse raw file and verify that its
   SHA-256 equals `.disk.sha256` in `ezvm-release-manifest.json`.
6. Upload a draft GitHub Release. Compare every GitHub-reported asset digest
   and size with the local files before publishing it as `latest`.
7. Download every asset from the public GitHub Release into an empty directory.
   Check `SHA256SUMS`, reconstruct the disk again, and verify its SHA-256.
8. Run the published installer and inspect the imported EZVM configuration and
   disk. Boot this installed copy before declaring the release complete.

## v4.0.1-ezvm.13 acceptance record

`v4.0.1-ezvm.13` is the first release produced from the final end-to-end QA
disk after the EZVM input and display work. Its raw disk is 64 GiB logical,
sparse on APFS, and has SHA-256:

```text
88d4fa72b7cafbef5cda3ea5e7306a14cdd75e9f57fadc97f00bc31951394c2b
```

The exact disk passed first-boot setup, Hyprland login, responsive input,
modifier shortcuts, scrolling, dynamic window/full-screen sizing, NAT, DNS,
HTTPS, live package checks, shutdown, and restart. The public Release assets
were downloaded into an empty directory, verified, decoded, and imported with
the published installer. The imported disk retained the same SHA-256 and sparse
layout. The generated VM uses 6 CPUs, 6 GiB memory, VirtIO display, raw block
storage, and NAT networking.

Release URL:

<https://github.com/everettjf/omarchy-aarch64-image/releases/tag/v4.0.1-ezvm.13>
