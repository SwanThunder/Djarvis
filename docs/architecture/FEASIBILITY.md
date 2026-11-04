# Feasibility checks — 2026-11-04

[Русская версия](FEASIBILITY.ru.md) · [Decisions](DECISIONS.md) · [Status](../STATUS.md)

Status: measurements from PLAN-021, run with owner approval on the owner's development PC. These are early evidence for architecture choices, not acceptance results for the 8 GiB target. No product code was written. Working files stay in the ignored `cache/feasibility/` folder.

## 1. Test machine

Intel Core i5-12400F (6 cores / 12 threads), 31.8 GiB RAM, NVIDIA RTX 5060 Ti, Windows 11, Python 3.12.10. The GPU was excluded from model tests; memory figures are reported so they can be compared with the 8 GiB target. A typical 8 GiB laptop CPU will be slower than this desktop CPU.

## 2. Results

| Check | Setup | Result |
| --- | --- | --- |
| Local language model on CPU | Existing `djarvis-qwen3.5-4b` (Q4_K_M) via the installed local runtime, `num_gpu=0`, 6 threads, context 4096, two Russian prompts | Prompt ≈ 56 tokens/s; generation ≈ 11 tokens/s; load ≈ 5 s; resident size ≈ 3.0 GB, 0 bytes in GPU memory |
| Russian speech | Vosk TTS 0.3.61, model `vosk-model-tts-ru-0.7-multi` (129 MB download), speakers 0–4 | Real-time factor ≈ 0.05 (about 20× faster than playback); model load ≈ 6.3 s; process memory ≈ 0.73 GB |
| English speech | kokoro-onnx 0.6.1, `kokoro-v1.0.int8.onnx` (88 MB) + voices (27 MB); bm_george, bm_lewis, am_michael, af_nicole, bf_emma | Real-time factor 0.27–0.41; load ≈ 1.2 s; both engines together ≈ 1.05 GB |
| Private PostgreSQL | PostgreSQL 18.6 Windows zip binaries, `initdb` with SCRAM password, 127.0.0.1 only, own port, no service, no administrator rights | Works; ready ≈ 1.2 s after launch; stop ≈ 0.4 s; idle ≈ 175 MB working set (≈ 40 MB private); empty data folder 40 MB; required `bin`+`lib`+`share` ≈ 141 MB of the 328 MB archive (pgAdmin, docs and headers not needed); connection without password is refused |
| Embedded Python | Official 3.12.10 embeddable package | 21.5 MB unpacked; runs isolated (`-I`) with ssl, sqlite3, ctypes, asyncio; third-party packages load through the `._pth` file; ≈ 21 MB memory at start |

Speech samples for listening: `cache/feasibility/samples/` (`vosk_ru_spk0…4_*.wav`, `kokoro_<persona>_<voice>_*.wav`).

## 3. Findings that affect the design

1. **Memory on 8 GiB is tight.** Model ≈ 3.0 GB + both speech engines ≈ 1.05 GB + PostgreSQL ≈ 0.2 GB + core and UI + Windows leaves little or no margin; speech recognition is not yet measured. The 8 GiB profile should load only the current language's speech engine, unload the model after idle, and keep a smaller-model option.
2. **Generation speed.** About 11 tokens/s on this CPU suggests roughly 5–8 tokens/s on weaker laptops; answers should be streamed to speech sentence by sentence.
3. **Text normalization before speech.** Vosk 0.7 crashes on characters outside its phoneme map (for example «»). A normalizer must clean text before synthesis, and synthesis errors must never stop the dialogue.
4. **GPL dependency.** kokoro-onnx installs `espeakng-loader`, which ships espeak-ng (GPL). Review how it is shipped, or use a non-GPL English phonemizer.
5. **Vosk model version.** 0.7 is marked obsolete; the current 0.9 multi model is 746 MB. Quality versus size needs a listening test.
6. **Process control.** `pg_ctl start` keeps inherited output handles open; a host that waits on piped output hangs. The core must start PostgreSQL with output redirected to files and check readiness separately (as `pg_isready` does).
7. **Data folder permissions.** A data folder created on drive F: inherited access for the local Users group. Initialization must set an explicit owner-only ACL (ADR-014).
8. **Model runtime independence.** Calling the installed runtime's CLI started its desktop app. The product must ship and control its own model runtime and must not depend on, or start, a runtime the user installed separately.

## 4. Not covered yet

Speech recognition and wake-phrase detection; a real 8 GiB / CPU-only machine; Flutter UI memory; installer and signing; database migrations; long-session stability.
