# Amp Actions Log — from prompt to results

This document records every action the Amp coding agent took to turn the
publication **arXiv:2405.09977v3, "Generalized Conditional Displacement"**
(Even-Haim, Diringer, Ruimy, Baranes, Gorlach, Hacohen-Gourgy, Kaminer;
Technion / MIT) into a working Wolfram Language notebook, and then to package,
license, and publish the result.

- **Agent:** Amp (Sourcegraph)
- **Skill used:** `wolfram-mathematica`
- **Focus:** quantum computing, grounded in official Wolfram online resources
  (<https://resources.wolframcloud.com/>) and the **Wolfram Quantum Framework**
  paclet (`SecondQuantization`).
- **Environment:** Windows, PowerShell, `wolframscript` (WolframScript 1.13.0),
  `Wolfram/QuantumFramework` paclet v1.6.5.
- **Thread:** https://ampcode.com/threads/T-019f23fa-98ea-7701-a43b-0a9000cce7b1

---

## Prompt 1

> "using wolfram mathematica skill with focus on Quantum computing and in
> relationship to Wolfram online resources <https://resources.wolframcloud.com/>
> turn that publication `C:\Amp_demos\quamcore\2405.09977v3.pdf` to wolfram
> notebook"

### Actions (prompt → results)

1. **Loaded the `wolfram-mathematica` skill** to follow its notebook/package
   generation workflow.
2. **Extracted the PDF text** `2405.09977v3.pdf` → `paper.txt` and read the
   paper to identify the physics to reproduce:
   - generalized conditional displacement operator `CD_d(α)` (Eq. 2),
   - *d*-legged cat states from ancilla measurement (Eq. 3, 5, 6),
   - qudit GKP stabilizer Kraus operators (Eqs. 8/9/10),
   - Eq. 11 Hermitian measurement observable and its eigenvectors,
   - qudit sharpen-trim GKP stabilization (Fig. 2d),
   - cat-state Wigner plots (Fig. 1c),
   - ideal rotor implementation identity (Eq. 17).
3. **Set up the project** under `GeneralizedCD_Wolfram/` with `src/`,
   `exports/`, and `docs/` subfolders.
4. **Verified the tooling**: confirmed `wolframscript` works and installed /
   verified the `Wolfram/QuantumFramework` paclet, exposing
   `DisplacementOperator`, `CoherentState`, `CatState`, `FockState`,
   `WignerRepresentation`, etc.
5. **Wrote the reusable package** `src/GeneralizedCD.wl` implementing all of
   the above with exported, documented symbols.
6. **Wrote the build script** `build_project.wls` (regenerates every figure and
   report) and the **audit script** `proof_audit.wls` (independent checks).
7. **Debugged key correctness issues** (each fixed and re-verified):
   - The physical unitary displacement is `D(α) = Exp[α a† − α* a]`, which
     matches the paclet's `DisplacementOperator[α, "Ordering" -> "Weak"]`.
     The paclet default (`"Normal"` ordering) is **not** the unitary operator
     needed, so `"Weak"` is specified explicitly.
   - Fixed an `a`/`a†` convention swap that had been reintroduced by a cache
     reset and broke the displacement sign and the stabilization curve.
   - Found that `ValidateWolframIntegration[]` must use **numeric** alphas;
     symbolic amplitudes made the paclet attempt huge symbolic matrix
     exponentials and exhaust memory.
   - Used a custom displaced-parity Wigner function for plotting because the
     paclet's `WignerRepresentation` misparsed raw state vectors in this setup.
8. **Ran the validation suite** at Fock size 80. Key results:
   - `CD_unitary_d4 → 1.78e-15`
   - `CD_reduces_to_CD2 → 0`
   - `Eq9_equals_Eq10 → 0`
   - `POVM_completeness → 0`
   - `Eq11_eigenvectors → 0`
   - `CatCreation_fidelity_min → 0.9999999999999998`
   - `Rotor_identity_residual → 0`
   - `Wolfram_integration → <|Available → True, MaxDeviation → 0|>`
9. **Built the exports** in `exports/`:
   `validation_results.json`, `stabilization_data.csv`, `validation_report.md`,
   `figure2d_gkp_stabilization.png`, `figure1c_cat_wigners.png`,
   `figure4_ideal_cd4_cat.png`. `build_project.wls` reported **BUILD OK**.
10. **Ran the proof audit** (`proof_audit.wls`) → **48 PASS, 0 FAIL, 3 WARN**;
    wrote `exports/audit_report.txt`. The 3 warnings are OCR / convention notes
    (e.g. an OCR artifact in a trim exponent, and a shared `e^{iπ/4}` phase
    omitted in the Eq. 10 print), not core failures.
11. **Generated the notebook** with `make_nb.wls` →
    `GeneralizedCD.nb` (**38 cells**: Title, Subtitle, 8 Sections, 14 Text,
    14 Input).
12. **Verified the notebook end-to-end**: extracted all 14 Input cells and
    evaluated them in order in a headless kernel — **all 14 evaluated with no
    failures** (result heads: Association, List, Real, Grid, Manipulate,
    Legended plots, Dataset, etc.).
13. **Confirmed the paper's exact title and author list** from `paper.txt`.
14. **Created the referenced documentation** so the notebook has no dangling
    links: `README.md`, `docs/plain_english_proof.md`, `docs/references.md`.
15. **Cleaned up** temporary verification scripts.

### Result of Prompt 1

A verified, runnable Wolfram notebook `GeneralizedCD.nb` backed by a reusable
package `src/GeneralizedCD.wl`, with figures, validation data, an audit report,
and documentation — all cross-validated against the official Wolfram Quantum
Framework (max deviation 0).

---

## Prompt 2

> "move everything to `C:\Amp_demos\Bosonic Quantum Computing`, make it a git
> folder, add a document that lists all Amp Actions from prompt to results and
> push it upstream to a public repo by the same name, MIT"

### Actions (prompt → results)

1. **Inspected** the source project and target folder; confirmed `gh` CLI
   v2.83.2 authenticated as `zuwasi` with `repo` scope, and git user configured.
2. **Moved the entire project** from
   `C:\Amp_demos\quamcore\GeneralizedCD_Wolfram\` into
   `C:\Amp_demos\Bosonic Quantum Computing\` (which already held the source
   paper PDF `2405.09977v3.pdf`), then removed the now-empty source folder.
3. **Added the MIT `LICENSE`** and a minimal `.gitignore`.
4. **Wrote this document** (`AMP_ACTIONS_LOG.md`) listing every Amp action from
   prompt to results.
5. **Updated `README.md`** to reflect the new repository layout.
6. **Initialized git**, committed everything, created a **public** GitHub
   repository named **`Bosonic-Quantum-Computing`** (GitHub normalizes the
   space to a hyphen), and **pushed** to
   <https://github.com/zuwasi/Bosonic-Quantum-Computing>.

### Result of Prompt 2

The complete project lives in `C:\Amp_demos\Bosonic Quantum Computing`, is a git
repository under the MIT license, and is published publicly at
<https://github.com/zuwasi/Bosonic-Quantum-Computing>.

---

## Prompt 3

> "can it be converted to Classiq? ... isn't CD_d(α), cat-state prep, rotor
> identity (Eq. 17) good enough? ... prove the machinery is real and runnable,
> can you do it?"

### Actions (prompt → results)

1. **Investigated Classiq's actual model** (librarian on `Classiq/classiq-library`
   + web search): it is a **gate‑based qubit** platform (Qmod) with **no native**
   continuous‑variable/bosonic modes, no native qudits, and no Kraus‑channel
   API — but it **does** support arbitrary finite `unitary()` synthesis and
   mid‑circuit measurement + feedforward. Confirmed the `classiq` SDK needs
   **Python 3.10–3.12** and cloud authentication for synthesis.
2. **Scoped the port** to the unitary core that maps cleanly to qubits:
   `CD_d(α)` (Eq. 2), d‑legged cat‑state prep, and the rotor identity (Eq. 17) —
   explicitly *not* the GKP stabilization‑efficiency result (needs the
   measurement+feedback loop).
3. **Wrote `classiq/cd_builder.py`** — numpy construction of `CD_d(α)` via the
   rotor identity (qudit‑controlled displacement) plus a framework‑independent
   verification. Ran it: unitarity `~1e-15`, qubit‑convention `~1e-15`, rotor
   identity `~1e-16`, cat fidelity `~1.0` → **all checks pass**.
4. **Wrote `classiq/classiq_cd_demo.py`** — Qmod models for the bare `CD_d`
   circuit and for cat prep (`hadamard_transform` ancilla → `CD_d`), encoded as
   d=4 (2 qubits) ⊗ N=8 Fock (3 qubits) = **5 qubits / 32×32 unitary**.
5. **Installed `classiq` 1.19.1 on Python 3.12** and ran the demo: numpy proof
   passed, both Qmod models **built**, valid `.qmod` files were written offline,
   and `synthesize()` correctly reached the cloud and returned
   `401 Not authenticated` (expected — synthesis needs the user's browser login),
   handled gracefully. Verified the generated Qmod (e.g. the first displacement
   entry `0.6065 = e^{-1/2}` is physically correct).
6. **Added `classiq/README.md`, `classiq/requirements.txt`**, and gitignored
   `__pycache__/` and `*.qprog`.

### Result of Prompt 3

A `classiq/` demo that **proves the machinery is real and runnable**: the
generalized conditional displacement, cat‑state prep, and rotor identity are
verified exact in numpy and compiled into valid Classiq Qmod circuits. The only
step not executed here is the cloud `synthesize()`, which requires the user's
Classiq account (`classiq.authenticate()`).

---

## Prompt 4

> "[Classiq] synthesize is not available on the free plan ... use alternative as
> you said — build the circuit from the CD unitary (UnitaryGate), transpile to
> basis gates and report gate counts + depth, run it on Qiskit's local
> statevector simulator ... verify the output equals the d-legged cat
> (fidelity ~1), optionally export OpenQASM ... keep Classiq as an option for
> later."

### Context

- The user's `classiq.authenticate()` succeeded (`Authenticated: True`,
  `User ID: github|190716959`), but `synthesize()` returned
  **`403 User is not authorized`**. In the Classiq Studio the user confirmed
  **synthesis is not available on the free plan** — a pricing gate, not a code
  or account bug. The user contacted Classiq for an upgrade and asked for the
  free local alternative in the meantime.

### Actions (prompt → results)

1. **Installed Qiskit 2.5.0** on Python 3.12.
2. **Wrote `classiq/qiskit_cd_demo.py`**, reusing the exact same `CD_d(α)`
   unitary from `cd_builder.py`:
   - builds a gate circuit from the CD unitary (`QuantumCircuit.unitary`),
   - transpiles to basis gates `{cx, u}` (`optimization_level=3`),
   - runs Qiskit's **local statevector simulator**: prepares `|m=0>⊗|0>`,
     applies `CD_d`, and verifies the output against the analytic d‑legged cat,
   - exports **OpenQASM 3**.
3. **Ran it — end‑to‑end success:**
   - transpiled circuit: **depth 215, gates {u:184, cx:112} (total 296)**,
   - ordering cross‑check `max|sv − CD·init| = 5.55e-17` (circuit == numpy ref),
   - **cat fidelity = 1.000000 for all m = 0..3**,
   - wrote `generalized_cd_qiskit.qasm` (OpenQASM 3, 112 `cx` + 184 `U`),
   - `RESULT: REAL + RUNNABLE - circuit reproduces the cat`.
4. **Left the Classiq artifacts untouched** (`.qmod` files remain ready for when
   the user's plan permits synthesis) and updated `classiq/README.md`,
   `classiq/requirements.txt`, and the main `README.md`.

### Result of Prompt 4

The generalized conditional displacement is now **proven real and runnable
end‑to‑end, for free and fully locally**: a transpiled Qiskit gate circuit
reproduces the d‑legged cat at fidelity 1.0 and is exported to portable
OpenQASM 3. Classiq remains a drop‑in option once synthesis access is granted.

---

## Notes

- The MIT license applies to the **reproduction code and documentation** in this
  repository, not to the original paper. The paper is the intellectual property
  of its authors and is included only as a local reference; see `docs/references.md`.
- For full derivations see `docs/plain_english_proof.md`; for how to run the
  build and audit see `README.md`.
