# Packaging

[Русская версия](README.ru.md)

Scripts that assemble the working application folder with the bundled runtimes. Archives and the assembled folder are never committed.

## What it does

- `runtimes.json` pins each runtime archive: name, version, https URL, file name, size, SHA-256 and what to unpack.
- `build-app.ps1` makes sure every archive is in `cache/build/runtimes/` with the pinned size and SHA-256 (downloading it when missing; preserving and rejecting a damaged cached file), unpacks the selected parts through a staging folder inside `build/`, rejects archive entries that would land outside the target folder, and replaces `build/app/` as a whole:
  - `runtime/python/` — embeddable Python 3.12; its launcher `python.exe` is renamed to `djarvis-core.exe`, `pythonw.exe` is left out;
  - `runtime/pgsql/` — PostgreSQL `bin`, `lib` and `share` only, without StackBuilder, development files, tests and documentation (see `exclude` in the manifest); three pinned x64 release Visual C++ DLLs are added to `bin` from the Microsoft package;
  - `licenses/<runtime>/` — license files taken from the archives;
  - the Windows UI (`Djarvis.exe` and its files) when `ui/build/windows/x64/runner/Release` exists; otherwise this part is skipped with a message.
- `smoke-runtimes.ps1` runs `djarvis-core.exe -I`, `postgres --version`, `initdb --version` and `pg_ctl --version` from `build/app` with `PATH` reduced to the Windows system folder and checks the versions against the manifest. It creates no database cluster.

## Running

```powershell
powershell -File packaging/build-app.ps1        # -Offline: use the cache only
powershell -File packaging/smoke-runtimes.ps1
powershell -File scripts/check.ps1 -Build -Runtimes   # everything, as in CI
```

`scripts/check.ps1` without `-Runtimes` does not download anything. The first build downloads about 0.40 GB; later builds reuse the cache.

## Updating a runtime

1. Change `version`, `url`, `file` and `size` in `runtimes.json`.
2. Python: take the SHA-256 from the Sigstore bundle published next to the archive on python.org and check that the file's MD5 matches the release page. PostgreSQL: the vendor publishes no checksum, so download the archive twice with separate requests and pin the hash only if both results match.
3. Update `sha256` and `sha256_source`, then run the build and the smoke test. A mismatch stops the build before anything is unpacked.

The Microsoft Visual Studio catalog identifies the CRT VSIX by its pinned URL and SHA-256, but records a size of 3,394,118 bytes. Two separate downloads from the same Microsoft source had the same catalog SHA-256 and a size of 3,380,682 bytes, which is the enforced size. Only `msvcp140.dll`, `vcruntime140.dll`, and `vcruntime140_1.dll` from `Contents/VC/Redist/MSVC/14.52.37025/x64/Microsoft.VC145.CRT/` are extracted. Their SHA-256 values are pinned and checked; the VSIX is cached but not included in the application. No `debug_nonredist` files are used. The smoke test requires these local DLLs, but is not a substitute for testing on clean Windows.

Redistribution of these unmodified DLLs is restricted to licensed Visual Studio users and subject to its license terms; see Microsoft's [Visual Studio 2026 redistribution list](https://learn.microsoft.com/en-us/visualstudio/releases/2026/redistribution) and [Visual C++ redistribution guidance](https://learn.microsoft.com/en-us/cpp/windows/redistributing-visual-cpp-files). Verify the applicable license and distribution conditions before release. The VSIX contains no license text; the Microsoft terms govern these DLLs.
