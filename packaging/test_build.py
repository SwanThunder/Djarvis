"""Isolated packaging regression tests; no network or repository build data."""
import hashlib
import json
import os
import shutil
import subprocess
import tempfile
import unittest
import zipfile
from pathlib import Path

SCRIPT = Path(__file__).with_name("build-app.ps1")


class BuildTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="djarvis-packaging-test-")
        self.root = Path(self.temp.name).resolve()
        (self.root / "packaging").mkdir()
        self.cache = self.root / "cache" / "build" / "runtimes"
        self.cache.mkdir(parents=True)
        shutil.copy2(SCRIPT, self.root / "packaging" / SCRIPT.name)

    def tearDown(self):
        self.temp.cleanup()

    def run_build(self, entries, url="https://www.python.org/test.zip", bad_hash=False, required="ok.txt"):
        archive = self.cache / "test.zip"
        with zipfile.ZipFile(archive, "w") as z:
            for name, content in entries:
                if name == "symlink":
                    entry = zipfile.ZipInfo(name)
                    entry.create_system = 3
                    entry.external_attr = 0o120777 << 16
                    z.writestr(entry, content)
                else:
                    z.writestr(name, content)
        data = archive.read_bytes()
        manifest = {"schema": 1, "runtimes": [{"name": "test", "version": "1", "url": url,
            "file": "test.zip", "size": len(data), "sha256": ("0" * 64 if bad_hash else hashlib.sha256(data).hexdigest()),
            "extract": {"root": "", "target": "runtime/test", "include": ["*"],
                "exclude": [], "rename": [], "required": [required]}, "licenses": ["LICENSE"]}]}
        (self.root / "packaging" / "runtimes.json").write_text(json.dumps(manifest), encoding="utf-8")
        return subprocess.run(["powershell", "-NoProfile", "-File", str(self.root / "packaging" / SCRIPT.name), "-Offline"],
                              capture_output=True, text=True, timeout=30)

    def test_rebuild_preserves_previous_application(self):
        app = self.root / "build" / "app"
        app.mkdir(parents=True)
        (app / "previous.txt").write_text("preserved")
        result = self.run_build([("ok.txt", "ok"), ("LICENSE", "license")])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((app / "runtime" / "test" / "ok.txt").read_text(), "ok")
        backups = list((self.root / "build").glob(".app-backup-*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / "previous.txt").read_text(), "preserved")

    def test_unsafe_entries_leave_existing_application_untouched(self):
        for bad in ("../escape", "a/../escape", "CON.txt", "a./bad", "x:y", "a/child", "symlink"):
            with self.subTest(bad=bad):
                app = self.root / "build" / "app"
                app.mkdir(parents=True, exist_ok=True)
                (app / "previous.txt").write_text("preserved")
                entries = [("ok.txt", "ok"), ("LICENSE", "license"), (bad, "bad")]
                if bad == "a/child":
                    entries.append(("a", "file"))
                result = self.run_build(entries)
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertEqual((app / "previous.txt").read_text(), "preserved")
                self.assertFalse((self.root / "escape").exists())

    def test_bad_hash_and_missing_entry_preserve_application(self):
        app = self.root / "build" / "app"
        app.mkdir(parents=True)
        (app / "previous.txt").write_text("preserved")
        for options in ({"bad_hash": True}, {"required": "missing.dll"}):
            with self.subTest(options=options):
                result = self.run_build([("ok.txt", "ok"), ("LICENSE", "license")], **options)
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertEqual((app / "previous.txt").read_text(), "preserved")

    def test_crt_extracts_only_pinned_files_and_rejects_missing(self):
        original = json.loads(SCRIPT.with_name("runtimes.json").read_text(encoding="utf-8"))
        item = next(x for x in original["runtimes"] if x["name"] == "vc-crt")
        root = item["extract"]["root"]
        names = item["extract"]["include"]
        archive = self.cache / item["file"]
        for missing in (None, names[0], "bad-hash"):
            with self.subTest(missing=missing):
                with zipfile.ZipFile(archive, "w") as z:
                    for name in names:
                        if name != missing:
                            z.writestr(f"{root}/{name}", name)
                    z.writestr(f"{root}/unwanted.dll", "unwanted")
                    z.writestr("Contents/VC/Redist/MSVC/14.52.37025/debug_nonredist/debug.dll", "debug")
                data = archive.read_bytes()
                item["size"] = len(data)
                item["sha256"] = hashlib.sha256(data).hexdigest()
                item["extract"]["sha256"] = {name: hashlib.sha256(name.encode()).hexdigest() for name in names}
                if missing == "bad-hash":
                    item["extract"]["sha256"][names[0]] = "0" * 64
                (self.root / "packaging" / "runtimes.json").write_text(json.dumps({"schema": 1, "runtimes": [item]}), encoding="utf-8")
                result = subprocess.run(["powershell", "-NoProfile", "-File", str(self.root / "packaging" / SCRIPT.name), "-Offline"], capture_output=True, text=True, timeout=30)
                app = self.root / "build" / "app"
                if missing is None:
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual({p.name for p in (app / "runtime" / "pgsql" / "bin").iterdir()}, set(names))
                else:
                    self.assertNotEqual(result.returncode, 0, result.stdout)
                    self.assertEqual({p.name for p in (app / "runtime" / "pgsql" / "bin").iterdir()}, set(names))

    def test_unapproved_host_rejected_offline(self):
        result = self.run_build([("ok.txt", "ok"), ("LICENSE", "license")], "https://example.com/test.zip")
        self.assertNotEqual(result.returncode, 0, result.stdout)

    def test_smoke_checks_files_before_any_launch(self):
        app = self.root / "app"
        python_dir = app / "runtime" / "python"
        pg_dir = app / "runtime" / "pgsql" / "bin"
        python_dir.mkdir(parents=True)
        pg_dir.mkdir(parents=True)
        source = self.root / "sentinel.cs"
        source.write_text('class Sentinel { static void Main() { System.IO.File.WriteAllText(System.Environment.GetEnvironmentVariable("DJARVIS_TEST_SENTINEL"), "started"); } }', encoding="utf-8")
        executable = self.root / "sentinel.exe"
        compiler = Path(os.environ["WINDIR"]) / "Microsoft.NET" / "Framework64" / "v4.0.30319" / "csc.exe"
        subprocess.run([str(compiler), "/nologo", f"/out:{executable}", str(source)], check=True, capture_output=True)
        for path in [python_dir / "djarvis-core.exe", *(pg_dir / name for name in ("postgres.exe", "initdb.exe", "pg_ctl.exe"))]:
            shutil.copyfile(executable, path)
        for name in ("vcruntime140.dll", "vcruntime140_1.dll"):
            (python_dir / name).write_bytes(b"python crt")
        names = ("msvcp140.dll", "vcruntime140.dll", "vcruntime140_1.dll")
        for name in names:
            (pg_dir / name).write_bytes(name.encode())
        manifest = {"runtimes": [
            {"name": "python", "version": "1"}, {"name": "postgresql", "version": "1"},
            {"name": "vc-crt", "extract": {"sha256": {name: hashlib.sha256(name.encode()).hexdigest() for name in names}}},
        ]}
        manifest_path = self.root / "manifest.json"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        sentinel = self.root / "started.txt"
        env = dict(os.environ, DJARVIS_TEST_SENTINEL=str(sentinel))
        command = ["powershell", "-NoProfile", "-File", str(SCRIPT.with_name("smoke-runtimes.ps1")), "-AppDir", str(app), "-Manifest", str(manifest_path)]
        (pg_dir / names[0]).write_bytes(b"tampered")
        result = subprocess.run(command, capture_output=True, text=True, timeout=30, env=env)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("SHA-256 mismatch", result.stdout)
        self.assertFalse(sentinel.exists())
        (pg_dir / names[0]).write_bytes(names[0].encode())
        (pg_dir / "pg_ctl.exe").unlink()
        result = subprocess.run(command, capture_output=True, text=True, timeout=30, env=env)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Required executable missing", result.stdout)
        self.assertFalse(sentinel.exists())
        shutil.copyfile(executable, pg_dir / "pg_ctl.exe")
        subprocess.run(command, capture_output=True, text=True, timeout=30, env=env)
        self.assertTrue(sentinel.exists(), "positive control must start a runtime process")


if __name__ == "__main__":
    unittest.main()
