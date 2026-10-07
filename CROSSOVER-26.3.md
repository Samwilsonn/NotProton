# CrossOver 26.3 experimental support

This fork adds the exact Apple Silicon Rosetta build **26.3.0.39832** to NotProton 1.0.3. macOS 26 or later is required by the upstream app; the experimental app was opened successfully on macOS 27.0.1 (26A434).

The implementation pins the Wine loader, both original ntdll files, both patch payloads, and both patched outputs by SHA-256. Unknown or modified inputs remain rejected. The 32-bit stable loader uses argument flag mask 1 rather than Preview's mask 2; the WINE_MODREF flag remains 2. Existing Preview entries and CrossOver licence verification remain intact.

## Verification

- 371 Swift tests across 49 suites passed with the upstream 1.0.3 payload staged, including actual 26.3 patch output checks and corrupted-input rejection.
- Two resolver integration tests passed against the installed 26.3 binaries.
- Both patches rebuilt to their pinned hashes.
- An isolated copy of CrossOver launched a Windows command executable.
- 32-bit and 64-bit smoke executables loaded Steam client DLLs, loaded the NotProton bridge, and successfully called a redirected Breakpad_SteamSetSteamID export. This is a bridge stub test, not a full Steam session or game test.
- The packaged experimental app opened and displayed CrossOver 26.3 on macOS 27.0.1. Its framework search path is included, and the bundle passes code-signature verification.

**Game compatibility and FPS have not been validated.** Treat this as an experimental fork, not upstream-supported compatibility. No proprietary CrossOver or Steam files are committed here.

## Build and test

Follow the upstream README for full prerequisites and payload builds. Build the app with `make app`; its packaging target includes the required Sparkle framework search path. For the supplied experimental build, the official 1.0.3 payload was staged and the Swift app rebuilt in Debug mode, which disables automatic updater scheduling. The bundle has a separate experimental identity and no update feed.

```sh
CX_ROOT=/Applications/CrossOver.app/Contents/SharedSupport/CrossOver ntdll-patch/build-ntdll.sh
python3 -m unittest discover -s ntdll-patch/tests -v
swift test --package-path app --no-parallel
```

The integration tests can use a different installation via `CROSSOVER263_ROOT`; absent binaries produce explicit skips. Resolver tests need capstone. Patch builds need mingw-w64 and the upstream toolchain.

For `steam_bridge_smoke.c`, use the matching mingw compiler with `-Os -ffreestanding -fno-stack-protector -nostdlib`, kernel32 linkage, and entry `mainCRTStartup` (x64) or `_mainCRTStartup` (i386). Run only in an isolated patched runtime with the matching Steam client and companion DLLs beside the executable.

## Existing macSteam installations

NotProton's upstream installer refuses a foreign Steam dylib, including macSteam. The experimental app retains this check. Do not click Repair Steam merely to bypass it: that restores Steam and can remove the existing macSteam modification. Combining both installers is outside this fork's tested scope. The CrossOver and Steam installations used for verification were preserved.
