# Package management

HUTOS currently ships a lightweight apt-shaped shell client over BusyBox `dpkg`.
It can refresh a Debian package index, resolve simple dependencies, download
packages, install/remove packages, and record installed status in `/var/lib/dpkg`.
The root filesystem must be on persistent ext4 for changes to survive reboot.

## Commands

```sh
sudo apt update
sudo apt install tree
sudo apt remove tree
sudo apt upgrade
apt list --installed
```

The configured feed is Debian 13 (trixie), amd64, main. HUTOS uses glibc and
amd64, so Alpine's musl repositories are not ABI compatible. HUTOS does not
claim compatibility with Alpine or Ubuntu repositories.

## Download and verification model

Downloads use bundled `curl` with TLS certificate and hostname checks enabled.
The package client's source list rejects non-HTTPS URLs. Every downloaded
`.deb` must match the SHA256 digest in the package index before `dpkg` sees it.

**Repository metadata signatures are not yet verified.** The `Packages` index
is authenticated by the HTTPS connection to the configured mirror; HUTOS does
not currently verify Debian's signed `InRelease` metadata with `gpgv`. This
does not meet the requested signed repository trust model and should be treated
as experimental for non-lab systems. Do not add third-party feeds.

The resolver handles basic comma-separated dependencies and chooses the first
alternative. It is not a full implementation of Debian's apt semantics,
version constraints, conflicts, triggers, or maintainer-script environment.
`dpkg` errors stop the operation, but files already unpacked by `dpkg` may need
manual repair. Packages that require systemd or services are not expected to
work on this BusyBox init system.

## Build integration

`scripts/bundle-userland-tools.sh` bundles the host's x86_64 sudo, sudoers
plugin, PAM Unix authentication module, verified HTTPS client, and runtime
libraries. The build host needs GCC, curl, upstream sudo with its sudoers
plugin, PAM modules, and the CA bundle. `scripts/build-disk.sh` uses fakeroot
so system files are root-owned in the ext4 image.

Package indexes and downloaded archives live in `/var/lib/apt` and
`/var/cache/apt`; both persist on an installed ext4 root. The initramfs live
environment is temporary.
