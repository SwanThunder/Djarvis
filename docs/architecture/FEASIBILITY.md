# Feasibility checks — 2026-11-04

[Русская версия](FEASIBILITY.ru.md) · [Decisions](DECISIONS.md) · [Status](../STATUS.md)

Status: measurements from PLAN-021 and PLAN-022 (section 4), run with owner approval on the owner's development PC. These are early evidence for architecture choices, not acceptance results for the 8 GiB target. No product code was written. Working files stay in the ignored `cache/feasibility/` folder.

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

## 4. Speech recognition, wake phrase, Vosk 0.9 and phonemizer (PLAN-022)

Same machine, CPU only. The test corpus is synthetic: 12 Russian phrases × 3 Vosk TTS voices × 2 model versions and 6 English phrases × 3 Kokoro voices. Each phrase is clean and with 10 dB pink noise, 180 recordings in total at 16 kHz. Half of the phrases start with a persona name, half have no name and contain similar words ("новую" (new, accusative), "новости" (news), "вольт" (volt), "Эдуард" (Eduard), "Edwin", "volts"). Scripts and results are in `cache/feasibility/` (`asr_*.py`, `wake_*.py`, `results/`).

### 4.1 Utterance recognition

WER is the share of wrong words; numbers are normalized to words. Real-time factor (RTF) is processing time divided by audio duration.

| Engine | Process memory | WER ru (voices 0.9 / 0.7) | WER en | RTF |
| --- | --- | --- | --- | --- |
| Vosk small ru 0.22 / en 0.15, streaming in 250 ms chunks | ≈ 0.18–0.23 GB | 5.1–5.5 % / 11–14 % | 2–8 % | ≈ 0.16–0.24 |
| Whisper base int8 | ≈ 0.2 GB, peak 0.35 | 9.7 % / 22 % | 0–6 % | ≈ 0.12 |
| Whisper small int8 | ≈ 0.4 GB, peak 0.73 | 4.6–5.9 % / 16–17 % | 0–2 % | ≈ 0.28–0.36 |

Vosk 0.7 voices are less intelligible than 0.9, so the "0.7" column evaluates the synthesis more than the recognition. 10 dB noise degrades the result only slightly. Whisper gives no streaming partial results and confuses "Нова" (Nova) with "Ново" (a different word).

### 4.2 Wake phrase

| Method | ru: found / false | en: found / false | RTF |
| --- | --- | --- | --- |
| Vosk small, grammar of names only | 72/72 / 68/72 | 18/18 / 6/18 | ≈ 0.016 |
| Vosk small, full vocabulary, name as a separate word | 55/72 / 2/72 | 15/18 / 0/18 | ≈ 0.16 |
| **Vosk small, grammar of names and decoy words** | **68/72 / 3/72** | **18/18 / 1/18** | **≈ 0.018** |

All remaining false triggers are a name in the middle of a phrase ("…напомни Эдвард" (remind Edward)). They are filtered out by the rule "a name counts only at the start of an utterance after a pause". The misses are "Нова" (Nova) heard as "ново" in one voice. The recognizer's confidence does not separate false triggers: it is also about 1.0 for them. Some decoys were chosen for this corpus, so the numbers are optimistic. A user's own phrase works if its words are in the model's vocabulary; this can be checked at input time.

### 4.3 Vosk TTS 0.9 versus 0.7

| Model | Load | Memory, peak | RTF | Characters «» |
| --- | --- | --- | --- | --- |
| 0.7 multi (129 MB) | ≈ 7 s | 0.75 GB | ≈ 0.05 | crashes (KeyError) |
| 0.9 multi (746 MB, 894 MB unpacked) | ≈ 124 s | 1.48 GB, peak 1.84 | ≈ 0.22–0.25 | crashes (KeyError) |

For 0.9 almost all of the load time goes into creating the onnxruntime session for the main model (171 MB). Disabling optimizations and a pre-saved optimized graph do not help; converting the model to `.ort` format failed. Samples for listening: `cache/feasibility/samples/vosk09_ru_spk0…4_*.wav` next to `vosk07_ru_spk0…4_*.wav`.

### 4.4 English phonemizer without GPL

misaki 0.9.4 (Apache-2.0) with dictionaries and spaCy `en_core_web_sm`, without the espeak-ng fallback (`fallback=None`). The espeak and phonemizer modules were not loaded. Ordinary words are fully covered. Unfamiliar names (Tavily, Kubernetes, Djarvis) and times such as "3:45" were left without phonemes. Kokoro accepted phonemes directly (`is_phonemes=True`): Whisper small recognized four check phrases with no semantic errors. Samples: `samples/kokoro_misaki_noespeak_*.wav`.

### 4.5 Findings

9. **Recognition:** Vosk small for both languages. One loaded model serves both the wake phrase (grammar with decoys) and the utterance (full vocabulary, streaming); together ≈ 0.2 GB. Whisper small is suitable as a second, more accurate pass only in profiles with spare memory; Whisper base is unsuitable for Russian.
10. **Wake phrase:** a grammar with decoys plus the rule "only at the start of an utterance". After wake-up the utterance still goes through full recognition; an empty or meaningless utterance silently returns to waiting.
11. **Vosk 0.9 is not for 8 GiB:** twice the memory, 5 times slower, about 2 minutes to load. 0.7 stays, with mandatory text cleaning; 0.9 is a possible higher-quality voice for 16 GiB machines if the owner likes the sound and loading can be sped up.
12. **GPL is removed:** the English misaki → Kokoro chain works without espeak-ng. It needs an own dictionary of terms (persona names, service names), normalization of numbers and times before synthesis, and spelling out for unfamiliar words. The kokoro-onnx package (MIT) pulls in `espeakng-loader` as a dependency; the product uses a thin own wrapper around the ONNX model or installs the package without that dependency.

## 5. Not covered yet

A live microphone and a real room (`cache/feasibility/mic_wake_test.py` is prepared: audio stays in memory only and is not written to disk); a real 8 GiB CPU-only machine; Flutter UI memory; installer and signing; database migrations; long-session stability; echo of the assistant's own voice.
