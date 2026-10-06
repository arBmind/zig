# GitHub release build

The **Linux x86_64 release** GitHub Actions workflow runs on pushes, pull
requests, and manually from the Actions tab. Download its artifact to obtain
`zig-x86_64-linux-<version>.tar.xz` and a SHA-256 checksum file.

It builds the checked-out source, including this fork's patches, with the same
Linux target and compiler settings used by upstream release CI: baseline
`x86_64-linux-musl`, static LLVM, `ReleaseFast`, and stripped debug information.
The archive uses Zig's upstream distribution layout (`-Dflat`), with `zig`,
`lib/`, `doc/langref.html`, `LICENSE`, and `README.md` inside one directory.
Packaging reuses the CMake-built release executable and installs the library
files and documentation with `-Dlib-files-only`.
Extract it anywhere and run `./zig version` from that directory.

The filename uses the compiler's actual Git-derived version. This checkout
is based on 0.18.0 development sources, so its patched builds are not labeled
as the official `0.17.0` release and are not expected to match its bytes.

The workflow verifies the archive after extraction away from the source tree,
checks that the compiler has no dynamic loader or shared library dependencies,
compiles and runs C and Zig smoke programs (including LLVM), and runs the
shared-libc++ exception regression with the packaged compiler. It uploads an
Actions artifact; it does not publish a GitHub Release.

The bootstrap development kit and its checksum are pinned to the toolchain
used by `ci/x86_64-linux-release.sh`. Update both workflow values when changing
that toolchain. Builds use two parallel jobs and 16 GiB of additional swap to
accommodate the bootstrap on smaller GitHub-hosted runners.
