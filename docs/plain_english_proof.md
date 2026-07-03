# Plain-English derivations

This document explains, in words, what each reproduced equation of
arXiv:2405.09977v3 means and why the corresponding Wolfram Language function
in `src/GeneralizedCD.wl` is correct. Every claim here is backed by a numeric
check in `proof_audit.wls` and by `RunValidationSuite[]`.

## 1. Qubit conditional displacement (Eq. 1)

The standard conditional displacement uses a two-level ancilla:

```
CD_2(α) = D(αZ) = |0⟩⟨0| ⊗ D(α) + |1⟩⟨1| ⊗ D(−α)
```

with the unitary displacement `D(α) = exp(α a† − α* a)`. Function:
`GeneralizedCD[2, α]`. It is block-diagonal: the ancilla is left alone
while the oscillator is pushed by `+α` or `−α` depending on the ancilla bit.

## 2. Generalized conditional displacement (Eq. 2)

Replace the qubit by a *d*-level qudit and the Pauli `Z` by the
Heisenberg–Weyl clock operator `Z̄_d = Σ_s ω_d^s |s⟩⟨s|`, `ω_d = e^{i 2π/d}`:

```
CD_d(α) = Σ_{s=0}^{d-1} |s⟩⟨s| ⊗ D(α ω_d^s)
```

Function: `GeneralizedCD[d, α]`. This is unitary because each block
`D(α ω_d^s)` is unitary and the blocks act on orthogonal ancilla states.
**Check:** `CD_d(α)† CD_d(α) = I` to `< 1e-15`, and `GeneralizedCD[2, α]`
equals the Eq. 1 block form exactly.

## 3. d-legged cat states (Eq. 3)

Start from ancilla `|m⟩` (an eigenstate of the qudit `X̄_d`, built by
`QuditXEigenstate[d, m]`) tensored with the oscillator vacuum, apply
`CD_d(α)`, and measure the ancilla back in the `X̄_d` basis. The oscillator
collapses to the normalized *d*-legged cat

```
|C_d^m(α)⟩ ∝ Σ_{s=0}^{d-1} ω_d^{-s m} |α ω_d^s⟩
```

a superposition of `d` coherent states equally spaced around a circle of
radius `|α|`. Function: `LeggedCatState[d, m, α]`, with normalization
`CatNormalization[d, m, α]` (Eq. 3). Their Wigner functions
(`WignerFunction`) show *d*-fold rotational symmetry with the characteristic
quantum-interference fringes between the legs.

## 4. Cat creation by measurement (Eqs. 5, 6)

Projecting the ancilla onto `|m⟩` after `CD_d(α)` applies the Kraus
operator `⟨m| CD_d(α) |m=0⟩` (`CatCreationKraus[d, m, α]`) to the vacuum
and yields exactly `|C_d^m(α)⟩`. **Check:** the fidelity between the
projected oscillator state and `LeggedCatState` is `1` (to `< 1e-6`) for all
tested `d` and `m`.

## 5. Qudit GKP stabilizer Kraus operators (Eqs. 8–11)

For `d = 4` the paper defines a measurement basis `|j⟩` (`QuditMeasBasis[j, β]`)
and the stabilizer Kraus operator

```
M_j(β) = ⟨j| CD_4(e^{iπ/4} √2 β) |m=0⟩        (Eq. 8)
```

`QuditStabilizerKraus[j, β]` implements Eq. 9, and
`QuditStabilizerKrausEq10[j]` implements the equivalent closed form Eq. 10 at
`β = √(π/2)`. **Checks:**
- **Eq. 9 = Eq. 10** exactly (max difference `0` after `Chop`).
- **POVM completeness:** `Σ_j M_j† M_j = I` exactly.
- **Eq. 11:** `QuditHermitianObservable[]` is Hermitian, and the `|j⟩`
  vectors are its eigenvectors (residuals `0`). This is the observable whose
  measurement realizes the four-outcome stabilizer readout.

Because a single `CD_4` addresses **both** GKP quadratures at once, one qudit
stabilizer round costs fewer CD operations than the qubit protocol, which must
treat the `q` and `p` stabilizers separately.

## 6. GKP stabilization from vacuum (Fig. 2d)

The sharpen–trim channel is applied repeatedly to `ρ`, starting from the
vacuum, using `applyChannel[ρ, {M_j}]`. Sharpening increases the GKP
stabilizer expectations `⟨S_x⟩, ⟨S_z⟩` (`StabilizerExpectations`) toward the
code manifold while trimming keeps the photon number bounded.
`RunQuditStabilization[rounds]` returns the convergence trajectory; it reaches
`⟨S_x⟩ ≈ ⟨S_z⟩ ≈ 0.80` with `⟨n⟩ ≈ 15`. `RunQuditSharpen` vs
`RunQubitSharpen` gives the per-CD-operation comparison: the qudit reaches a
target `⟨S⟩` in fewer CD operations.

> **Honesty note.** The exact qubit finite-energy *trim* protocol is not fully
> determined by the paper's main text, so the head-to-head plot uses a
> sharpen-only comparison (identical protocol on both sides) rather than a
> qudit-with-trim vs qubit-without-trim comparison that would flatter the
> qudit unfairly.

## 7. Ideal implementation: planar rotor (Eq. 17)

Encode the qudit in a planar rotor with logical states at angles
`θ = 2π s / d`. The phase operator `e^{iθ}` then acts exactly as the clock
operator `Z̄_d`, so a rotor conditional displacement `D(α e^{iθ})` equals
`CD_d(α)`. **Check:** `RotorCDIdentityResidual[d, α] = Max|D(α Z̄_d) − CD_d(α)|`
is `0` for `d ∈ {2, 3, 4, 6}`. The harmonic-oscillator cat-code (beam-splitter,
Eq. 19) and spin / Tavis–Cummings (Eq. 22) realizations approximate `CD_d`
with fidelity approaching `1` as the encoding grows (Fig. 4).

## 8. Cross-check against the Wolfram Quantum Framework

`ValidateWolframIntegration[]` loads `Wolfram/QuantumFramework` and compares
the package's `Displacement[α]` against the paclet's
`DisplacementOperator[α, "Ordering" -> "Weak"]` on numeric test amplitudes.
The maximum deviation is `0`, confirming that the reproduction is built on the
same physical operator as Wolfram's official quantum-computing tooling. (The
paclet's default `"Normal"` ordering is *not* the unitary operator required
here, which is why `"Weak"` is specified explicitly.)
