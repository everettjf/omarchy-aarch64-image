# Omarchy AArch64 Image for EZVM

This project builds and publishes a sparse AArch64 Omarchy disk image exclusively
for [EZVM](https://github.com/everettjf/ezvm) and Apple's
Virtualization.framework. It does not publish a general-purpose disk image or a
bundle for another virtual-machine frontend.

The image runs natively on Apple silicon: the guest CPU architecture is ARM64,
so EZVM virtualizes it without cross-architecture CPU emulation.

## Release pipeline

This repository is one part of a three-repository AArch64 release pipeline:

- [`riverscn/omarchy-aarch64`](https://github.com/riverscn/omarchy-aarch64)
  maintains the AArch64 runtime adaptation of Omarchy.
- [`riverscn/omarchy-pkgs-aarch64`](https://github.com/riverscn/omarchy-pkgs-aarch64)
  builds and publishes the signed stable AArch64 pacman repository.
- This repository assembles the EZVM disk image from Arch Linux ARM and that
  signed repository.

The builder downloads the latest package Release manifest and public key on
every build. It rejects the snapshot unless:

- the manifest uses the expected stable AArch64 schema;
- its signing fingerprint matches the fingerprint pinned in `sources.env`;
- every selected package is present;
- the published `omarchy` package matches the pinned source commit; and
- pacman verifies the signed database and packages.

The installed image keeps the signed repository enabled, so Arch Linux ARM and
Omarchy update together:

```bash
sudo pacman -Syu
```

## Image contents

The EZVM image contains:

- Arch Linux ARM's generic AArch64 root filesystem and kernel;
- a 1 GiB EFI System Partition and Btrfs root with `@`, `@home`, `@log`,
  and `@pkg` subvolumes;
- Limine, an AArch64 UKI, branded boot menu, factory snapshot, and recovery
  entries;
- VirtIO graphics, block storage, networking, entropy, input, and audio devices
  supported by Virtualization.framework;
- PipeWire audio and its PulseAudio, ALSA, JACK, and GStreamer compatibility
  layers;
- an interactive first-boot wizard for owner credentials, keyboard, Git
  identity, hostname, and timezone;
- an idempotent service that expands the root partition and Btrfs filesystem
  when the virtual disk grows; and
- a built-in Omarchy thumbnail for the EZVM library.

The profile intentionally excludes host-specific physical hardware services and
guest components that are unavailable through EZVM.

The distributed image is intentionally unencrypted. A reusable image cannot
safely contain a shared disk-encryption key; per-machine encryption requires a
future installer that creates a unique container during import.

## One-command installation

Requirements:

- Apple silicon Mac;
- macOS 26 or newer;
- Homebrew; and
- at least 15 GiB available on the destination volume.

The recommended command installs or updates EZVM, verifies the published
Omarchy installer, downloads and verifies every image part, and imports a new
machine:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/everettjf/ezvm/main/scripts/install-omarchy.sh)"
```

If EZVM 1.0.0 or newer is already installed, the image-only installer is:

```bash
/bin/bash -o pipefail -c 'curl -fsSL https://github.com/everettjf/omarchy-aarch64-image/releases/latest/download/install-Omarchy-ezvm.command | /bin/bash'
```

The installer treats `ezvm-release-manifest.json` as its sole metadata source.
It verifies:

- every numbered part's byte length and SHA-256;
- the complete compressed stream SHA-256;
- the decoded raw disk's virtual size and SHA-256;
- the thumbnail's byte length and SHA-256; and
- the minimum supported EZVM version.

The portable sparse stream records only allocated extents and recreates them at
their exact disk offsets on macOS. The logical disk is 64 GiB while physical
host usage stays close to the guest's used data. EZVM creates fresh machine,
NVRAM, and host configuration identities during import.

## Release assets

Each Release contains only the EZVM installation path:

- `install-Omarchy-ezvm.command`;
- `ezvm-release-manifest.json`;
- numbered `Omarchy-ezvm.sparse.gz.part-*` files;
- `Omarchy-thumbnail.png`;
- `SHA256SUMS`;
- image provenance; and
- exact package inventories.

GitHub limits each asset to 2 GiB, so the encoded sparse stream is compressed
and split into parts of at most 1,900 MiB. The workflow validates local
checksums, uploads a draft Release, verifies GitHub's digest for every asset,
and publishes only after all checks succeed.

## Build

Image assembly executes AArch64 target commands in a chroot and requires a
native AArch64 Arch Linux ARM host. Docker, Git, and the standard image tools
are required.

Build the image:

```bash
./bin/build-image-container
```

Useful options:

```bash
./bin/build-image-container --size 80G --force
./bin/build-image-container --refresh --force
./bin/build-image-container \
  --omarchy-source ../omarchy-aarch64 \
  --omarchy-repository ../omarchy-pkgs-aarch64/pkgs.omarchy.org/stable/aarch64 \
  --force
```

The default output is:

```text
build/omarchy-aarch64-ezvm.raw
build/omarchy-aarch64-ezvm.raw.sha256
```

A successful build also emits package inventories and
`build/image-provenance.txt`, including the pinned EZVM Guest Agent source
revision and the digest of the exact binary installed into the image.

Package a local EZVM Release layout:

```bash
./bin/package-ezvm-release \
  --tag v4.0.1-ezvm.1 \
  --output build/release-assets
```

## Tests

Run the static contract and release-packager suite with the adapted Omarchy
source as a sibling checkout:

```bash
OMARCHY_TEST_SOURCE=../omarchy-aarch64 ./tests/run
```

The suite verifies script syntax, package boundaries, signed repository
provenance, boot configuration, sparse output invariants, EZVM manifest and
installer behavior, split-part checksums, workflow constraints, and the absence
of removed runtime integrations.

A complete release additionally requires a native AArch64 image build, checksum
verification, EZVM import, boot, first-run provisioning, shutdown, restart, and
forced-stop recovery testing.

See [`docs/RELEASE_VALIDATION.md`](docs/RELEASE_VALIDATION.md) for the complete
publish, public-download, recovery, and end-to-end acceptance procedure.

## License

MIT. See [LICENSE](LICENSE).
