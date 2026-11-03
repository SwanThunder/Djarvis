# Local model evaluation

[Русская версия](LOCAL_MODEL.ru.md)

Date: 2026-11-03. Status: downloaded, checksum verified, registered, and initial inference checks passed. This prepares an evaluation environment and does not select the final application architecture or approve programming.

## Candidate and provenance

- Base model: Qwen3.5 4B.
- Quantization: Unsloth GGUF, Q4_K_M.
- Quantization repository: `unsloth/Qwen3.5-4B-GGUF`.
- Pinned revision: `e87f176479d0855a907a41277aca2f8ee7a09523`.
- Artifact: `Qwen3.5-4B-Q4_K_M.gguf`, 2,740,937,888 bytes.
- Verified SHA-256: `00fe7986ff5f6b463e62455821146049db6f9313603938a70800d1fb69ef11a4`.
- The upstream model and quantization repository identify the license as Apache-2.0. The upstream license was included in the local runtime model metadata. Product distribution still needs appropriate notices and a review of the full dependency bundle.

## Local environment

- Existing runtime: Ollama 0.40.13; no additional inference engine installed.
- Local model name: `djarvis-qwen3.5-4b:latest`.
- Evaluation context: 4,096 tokens; temperature 0.3 in local model configuration.
- Development machine: Intel Core i5-12400F, approximately 32 GiB RAM, NVIDIA RTX 5060 Ti with 8 GiB VRAM.
- Model loaded entirely into GPU memory according to the local runtime; reported allocation approximately 3.0 GB at a 4,096-token context.

The 4B candidate was chosen to leave memory headroom on this development machine. These observations are not minimum customer requirements or a promise of performance on other computers.

## Download and storage

The standard registry pull failed with a TLS error. The fallback downloaded a pinned GGUF over verified HTTPS from the quantizer's Hugging Face repository, verified size and SHA-256 against repository metadata, and imported it using the installed runtime. TLS certificate verification was not disabled.

The downloaded file and local evaluation configuration are under `cache/model-downloads/`, which is excluded from Git. The runtime also stores its imported model outside the project. Existing models were preserved. No weights, voice samples, credentials, hardware serial numbers, or device-trial identifiers are included in the documentation commit.

## Checks

Metadata reports the `qwen35` family, Q4_K_M quantization, and completion, thinking, and tool capabilities. The local model metadata contains the Apache-2.0 license. Three synthetic checks passed with thinking disabled and a 4,096-token context:

| Check | Observed result | Total request time | Generation time |
| --- | --- | --- | --- |
| Russian conversation, first initialization | Coherent Russian sentence about planning | 85.49 s | 1.59 s |
| English conversation, warm model | Coherent English sentence about planning | 0.38 s | 0.26 s |
| Russian task proposal, warm model | One `propose_task` call with `Купить молоко`, `2026-11-04`, and `18:00` | 1.34 s | 0.59 s |

No real tool was executed. The synthetic tool arguments matched the requested title, date, and time. These short checks do not establish broad language quality or reliable autonomous execution. The large first-initialization delay needs investigation before product performance targets can be set. Raw synthetic responses remain in ignored cache. The candidate was unloaded after evaluation to release GPU memory; it remains installed on disk.

All evaluation inference requests targeted the loopback runtime API at `127.0.0.1:11434`; no cloud inference endpoint was requested. Downloads required internet access. No real user task or file was changed by the synthetic tests. This records the requests made, not a full network-isolation audit of the installed runtime.

## Reuse and limits

Run the installed candidate with `ollama run djarvis-qwen3.5-4b`.

This language model does not install speech recognition, speech synthesis, a wake-word engine, weather/search connectors, subscription protection, or an application interface. Those remain separate design items. Broader multilingual quality, tool reliability, latency, memory use alongside voice models, and low-end hardware performance require evaluation before final selection.

## Sources

- [Upstream model card](https://huggingface.co/Qwen/Qwen3.5-4B).
- [Upstream license](https://huggingface.co/Qwen/Qwen3.5-4B/blob/main/LICENSE).
- [Pinned quantization files](https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/tree/e87f176479d0855a907a41277aca2f8ee7a09523).
- [Runtime GGUF import documentation](https://docs.ollama.com/modelfile).
