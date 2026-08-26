# Omarchy AArch64 Image

This workspace builds a generic AArch64 UEFI disk image for QEMU-compatible
virtual machines. It does not use Asahi Linux, Apple hardware packages, SBSA,
GRUB, or a custom Omarchy binary repository at runtime.

The current release has exactly one image profile: `aarch64-virt`. It targets
QEMU's `virt` machine (including UTM's QEMU backend); it does not claim support
for SBSA, Apple hardware, or physical AArch64 boards.

This repository owns image orchestration and the `aarch64-virt` policy. The
target runtime is maintained separately in
[`riverscn/omarchy-aarch64`](https://github.com/riverscn/omarchy-aarch64), based
on the official Omarchy 4.0.1 release. A normal build fetches the exact source
commit pinned in `sources.env`; no nested Git checkout is required.

For development, keeping the two repositories as siblings is convenient:

```text
workspace/
├── omarchy-aarch64/
└── omarchy-aarch64-image/
```

## What the image contains

- Arch Linux ARM's generic AArch64 root filesystem and `linux-aarch64` kernel.
- GPT with a 1 GiB EFI System Partition and a Btrfs root using `@`, `@home`,
  `@log`, and `@pkg` subvolumes. Snapper owns `/.snapshots` itself.
- Limine at the standard AArch64 fallback path `EFI/BOOT/BOOTAA64.EFI`, plus
  native AArch64 kernel/initramfs entries and Limine configuration. UKIs are
  disabled because mkinitcpio's UKI mode is currently x86-64-only.
- VirtIO graphics, disk, network, RNG, QEMU guest-agent, and SPICE guest support.
- `omarchy-spice-guest-tools`, providing per-user Wayland clipboard sharing and
  dynamic SPICE display resizing when the hypervisor exposes a SPICE agent
  channel. Its globally attached user services bootstrap automatically at the
  owner's first graphical login. The stock `spice-vdagent` udev rule activates
  its system socket when the SPICE virtio port is present.
- A complete PipeWire guest audio stack with PulseAudio, ALSA, JACK, and
  GStreamer compatibility. The virtual-machine profile keeps the printing stack.
- A virtual-machine desktop that omits LibreOffice, Kdenlive, Moonlight, Night
  Light, and GPU screen recording. Night Light and Screen Recording are also
  removed from the initial top-bar indicator set.
- Fork-specific and boot packages built from source, plus checksum-pinned
  generic AArch64 application packages from `omarchy-pkgs-aarch64`, all baked
  into the image. No custom pacman repository is required at runtime.
- No `linux-firmware`, split `linux-firmware-*`, `sof-firmware`, or `haveged`
  package in the finished VM image.
- No Arch Linux ARM Generic rootfs leftovers for the superseded DHCP/network
  stacks or console editors: NetworkManager replaces `dhcpcd` and `netctl`,
  modern networking tools replace `net-tools`, and Neovim replaces Nano and
  the Vim compatibility package chain.
- No Bluetooth, Thunderbolt, DDC/backlight, wireless-regulatory, or physical
  power-profile stack in the `aarch64-virt` profile.
- A deferred first-boot wizard on tty1. The owner chooses keyboard layout,
  username/password, name/email, hostname, and timezone before SDDM starts.
- A read-only `@factory` snapshot and an idempotent root-partition grow service.

The first image format is intentionally unencrypted. A distributable image
cannot contain a shared LUKS master key safely; per-machine encryption belongs
in a later installer flow that creates a fresh LUKS container for each VM.

## Build

The package builder can produce AArch64 packages through Docker on either an
x86-64 or AArch64 Arch Linux host. Its orchestration still inspects packages on
the host, so `docker`, `git`, `curl`, `pacman`, `repo-add`, and the usual core
shell tools must be installed there. Image assembly currently requires a native
AArch64 host because it executes target commands in a chroot. The recommended
wrapper performs the privileged disk and chroot work in the existing AArch64
package-builder container, so it does not install image tooling on the host.

The pinned package recipes keep their upstream Gradle dependency unchanged.
Because Arch Linux ARM does not currently publish that build dependency, the
builder creates a checksum-pinned Gradle bootstrap package in its private build
repository. That bootstrap package is filtered out of the image artifacts.

Generic packages already published by `omarchy-mac/omarchy-pkgs-aarch64` are
listed by exact filename and SHA-256 in
`config/prebuilt-packages.aarch64`. The release is unsigned and its `edge` tag
is mutable, so it is only a build-time input: downloads that differ from the
pinned digest are rejected, and its repository is never added to the guest.
Packages absent from that manifest—including the fork's `omarchy` and
`omarchy-settings` packages, `omarchy-spice-guest-tools`, and the patched Limine
stack—are built from pinned recipes. The guest-tools recipe consumes its v0.1.0
release archive and verifies the release SHA-256 before packaging.

```bash
./bin/build-packages
./bin/build-image-container
```

Those commands fetch the locked Omarchy source and record the selected inputs,
but they are not bit-for-bit reproducible builds. Arch Linux ARM's rootfs and
package repositories, as well as the selected Node.js `latest` directory, are
rolling inputs. Their verified versions and digests are captured in the build
provenance. To test local source changes before pushing them, opt in explicitly:

```bash
./bin/build-packages --omarchy-source ../omarchy-aarch64
./bin/build-image-container --omarchy-source ../omarchy-aarch64
```

The container wrapper mounts that checkout read-only. Package and image
provenance record the actual commit and dirty state, and image assembly refuses
to combine packages with a different source checkout.

On an Arch Linux ARM host with the required tools installed, the equivalent
native command is `sudo ./bin/build-image`. Options accepted by
`bin/build-image` can also be passed through the container wrapper, for example
`./bin/build-image-container --size 80G --format both`. The default artifact is
`build/omarchy-aarch64-virt.qcow2`. Default outputs are written below `build/`.
The root filesystem download is verified with the Arch Linux ARM signing key
and the expected signer fingerprint. Node.js is verified against its published
SHA-256 list.

Useful image options:

```bash
sudo ./bin/build-image --size 80G --format both
sudo ./bin/build-image --rootfs /path/to/ArchLinuxARM-aarch64-latest.tar.gz
sudo ./bin/build-image --package-dir /path/to/aarch64/packages
sudo ./bin/build-image --refresh --force
```

Cached rootfs, keyring, and Node.js downloads are reused by default. `--refresh`
downloads those rolling inputs again; target packages are still resolved from
the current Arch Linux ARM repositories during every image build.

Existing outputs are never overwritten unless `--force` is supplied. Even with
`--force`, image conversion is staged in a `.part` file and the previous image
is retained until its replacement is ready. A successful default build
publishes these files:

- `omarchy-aarch64-virt.qcow2` and its `.qcow2.sha256` checksum.
- `omarchy-aarch64-virt.all-packages.txt`, containing every installed package.
- `omarchy-aarch64-virt.explicit-packages.txt`, containing explicitly installed
  packages.
- `omarchy-aarch64-virt.packages.tsv`, containing package names, installed
  sizes, dependencies, required-by relationships, and descriptions.
- `omarchy-aarch64-virt.orphans.txt`, containing orphaned packages, if any.
- `image-provenance.txt`, containing the selected source commits and verified
  rolling-input digests. Package-build provenance remains under
  `build/packages/aarch64/provenance.txt` and is also embedded in the image.

## Run with QEMU

Install QEMU with both `qemu-system-aarch64` and `qemu-img`, plus an AArch64 EDK2
firmware package, then run:

```bash
./bin/run-image build/omarchy-aarch64-virt.qcow2
```

The helper prints actionable errors if it cannot find either QEMU command or an
AArch64 UEFI firmware image. It is a basic GTK boot and SSH-forwarding helper;
it does not currently create a SPICE server or agent channel, so SPICE clipboard
sharing and dynamic display resizing are not exercised by this command.

UTM can import the same QCOW2 image as an ARM64 virtual machine using UEFI,
VirtIO disk/network, a VirtIO GPU, and a SPICE agent channel. The last item is
required for the guest clipboard and dynamic display integration.

The virtual disk is sparse and defaults to 64 GiB. If it is enlarged later,
the guest expands partition 2 and the Btrfs filesystem once at boot.

## Updates

Arch Linux ARM packages continue to update normally with `pacman`. Local image
artifacts are refreshed when producing a new image. Fork and boot packages are
built when their source or version changes; up-to-date artifacts can be reused
and are hashed into package provenance. Reusable application packages are
updated by reviewing the rolling release and changing their filename and digest
in the manifest.
`sources.env` pins both the Omarchy AArch64 source and the package recipe
repository. Updating either commit, reviewing the prebuilt manifest, and
building a fresh image are explicit release boundaries.

In the source repository, `origin` is `riverscn/omarchy-aarch64`, `upstream`
is the original `basecamp/omarchy`, and `omarchy-mac` remains available only as
an implementation reference. Start an update from the desired official release
tag, reapply/review the AArch64 commits, then update `OMARCHY_AARCH64_REF` and
`OMARCHY_AARCH64_VERSION` here:

```bash
git -C ../omarchy-aarch64 fetch --all --prune
git -C ../omarchy-aarch64 rebase <reviewed-upstream-release>
```

After resolving profile-sensitive conflicts, run both repositories' tests,
push the reviewed source commit and its AArch64 release tag, then update the
locked commit here and build a new image. `OMARCHY_AARCH64_REF` must be reachable
from `OMARCHY_AARCH64_URL` before the image project is published; otherwise a
normal build cannot clone the pinned source. Existing images receive Arch Linux
ARM repository updates through `pacman`, but source-built Omarchy packages
change only in a new image until this project deliberately publishes a signed
package repository.

## Image profiles

The generic builder contains no package-specific deletion rules. Everything
that distinguishes the current target lives under `profiles/aarch64-virt/`:
image defaults, packages to add/exclude/replace/remove, VM shell defaults, and
the root filesystem overlay. Package removal is performed by
`pacman` while assembling the image, so package ownership and dependencies stay
consistent; it is not implemented by deleting firmware files manually.

This boundary lets a future target add its own directory without changing or
silently inheriting `aarch64-virt` policy. Adding another directory is a future
release decision; only `aarch64-virt` is present and tested today.

## Tests

```bash
OMARCHY_TEST_SOURCE=../omarchy-aarch64 ./tests/run
```

The test suite performs shell/static contract checks without partitioning disks
or requiring root. When the repositories are siblings, the environment variable
can be omitted. A full image build and QEMU boot test remain release checks.
