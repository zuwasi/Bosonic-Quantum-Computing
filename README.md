# Generalized Conditional Displacement — Wolfram Language reproduction

A Wolfram Language / Mathematica reproduction of

> S. Even-Haim, A. A. Diringer, R. Ruimy, G. Baranes, A. Gorlach,
> S. Hacohen-Gourgy, I. Kaminer,
> **"Generalized Conditional Displacement"**, arXiv:2405.09977v3
> (Technion – Israel Institute of Technology / MIT).

The project builds the generalized conditional-displacement operator
`CD_d(α)` conditioned on a *d*-level qudit ancilla, creates the *d*-legged
cat states, verifies the qudit GKP stabilizer Kraus operators (Eqs. 8–11),
runs the qudit sharpen–trim GKP stabilization, and checks the ideal rotor
implementation (Eq. 17). Bosonic operators are cross-validated against the
official **Wolfram Quantum Framework** (`SecondQuantization`) paclet from
<https://resources.wolframcloud.com/PacletRepository/resources/Wolfram/QuantumFramework/>.

## Layout

```
Bosonic Quantum Computing/
├── GeneralizedCD.nb            interactive notebook (the main deliverable)
├── 2405.09977v3.pdf           source paper (reference only; see docs/references.md)
├── src/
│   └── GeneralizedCD.wl        reusable package (all algebra lives here)
├── build_project.wls           regenerates every figure + report in exports/
├── proof_audit.wls             48 independent numerical checks
├── exports/                    generated figures, CSV, JSON, reports
├── docs/
│   ├── plain_english_proof.md  derivations in plain English
│   └── references.md           citations
├── classiq/                    Classiq (Qmod) port of the unitary core
│   ├── cd_builder.py           numpy build + verification of CD_d(α)
│   ├── classiq_cd_demo.py      Qmod models (CD_d, cat prep) + synthesis
│   └── README.md               scope, run steps, what runs local vs cloud
├── AMP_ACTIONS_LOG.md          full log of Amp actions from prompt to results
└── LICENSE                     MIT
```

A gate-based **Classiq** port of the unitary core (`CD_d(α)`, cat-state prep,
rotor identity) lives in [`classiq/`](classiq/README.md). It proves the
machinery compiles to real qubit circuits; it is not a reproduction of the
continuous-variable GKP stabilization result (see that folder's README).

## Requirements

- Wolfram Language 13+ / `wolframscript`
- Paclet **`Wolfram/QuantumFramework`** (tested with 1.6.5):
  ```
  PacletInstall["Wolfram/QuantumFramework"]
  ```

## How to run

**Interactive:** open `GeneralizedCD.nb` in the Wolfram front end and
evaluate the cells top to bottom (`Evaluation ▸ Evaluate Notebook`).
The first cell loads `src/GeneralizedCD.wl` and the Quantum Framework.

**Regenerate all exports (figures, CSV, JSON, reports):**
```
wolframscript -file build_project.wls
```

**Run the full audit (48 checks):**
```
wolframscript -file proof_audit.wls
```

## What is verified

- `CD_d(α)` is unitary to `< 1e-15` and reduces to Eq. 1 for `d = 2` (residual 0).
- *d*-legged cat creation fidelity `= 1` (to `< 1e-6`) for `d = 2, 4`, `m = 0..3`.
- Eq. 8 `=` Eq. 9 `=` Eq. 10 exactly; POVM completeness exact; the `|j⟩`
  basis are exact eigenvectors of the Eq. 11 Hermitian observable.
- The qudit sharpen–trim protocol converges to `⟨S_x⟩ ≈ ⟨S_z⟩ ≈ 0.80`
  with bounded photon number `⟨n⟩ ≈ 15`, reaching a target `⟨S⟩` at fewer
  CD operations than the qubit protocol.
- Ideal rotor implementation `D(α Z̄_d) = CD_d(α)` exactly (residual 0).
- Package displacement matches Wolfram QF `DisplacementOperator[α, "Ordering" -> "Weak"]`
  (deviation 0).

## Notes on conventions

- The physical, unitary displacement operator is
  `D(α) = Exp[α a† − α* a]`, which corresponds to the Quantum Framework's
  `DisplacementOperator[α, "Ordering" -> "Weak"]` (the paclet default,
  `"Normal"` ordering, is **not** the unitary operator used here).
- Wigner functions are computed via the displaced-parity form
  `W(x,p) = (2/π) ⟨ψ| D†(β) Π D(β) |ψ⟩`, `β = (x + i p)/√2`.
- Fock-space truncation defaults to 60; use ~70–80 for publication-quality
  stabilization curves.
- Figure 2d is shown as two panels: (A) the full qudit sharpen+trim
  convergence and (B) an apples-to-apples sharpen-only qudit-vs-qubit
  comparison per CD operation. The exact qubit finite-energy *trim*
  protocol is underdetermined from the paper text, so an honest sharpen-only
  comparison is used instead of a misleading single-panel one.
