# Classiq demo — generalized conditional displacement as a qubit circuit

This folder ports the **unitary core** of arXiv:2405.09977v3 to
[Classiq](https://github.com/Classiq/classiq-library) (Qmod), proving the
machinery is real and runnable on gate-based qubit hardware:

- **`CD_d(α)`** (Eq. 2) — synthesized to a gate circuit via Classiq's core
  `unitary` function.
- **d-legged cat‑state prep** — ancilla in `|m=0>`, apply `CD_d`, herald.
- **rotor identity (Eq. 17)** — `CD_d` is *built* as the qudit‑controlled
  displacement `D(α · Z̄_d)` (see `generalized_cd_rotor`), and cross‑checked
  against the block‑diagonal definition.

> Scope: Classiq is a discrete‑variable (qubit) platform with no native
> bosonic/CV modes, so this demonstrates the **operator and states** on a
> truncated Fock space, **not** the paper's GKP stabilization‑efficiency
> result (that needs the measurement + feedback loop). See `../docs/` and the
> repository `README.md` for the full continuous‑variable reproduction in
> Wolfram Language.

## Encoding (small, so it actually synthesizes)

```
qudit d = 4   ->  2 qubits
Fock  N = 8   ->  3 qubits
total         ->  5 qubits  (a 32×32 unitary)
```

## Files

| File | What it is |
|---|---|
| `cd_builder.py` | numpy construction + **verification** of `CD_d(α)` (shared by both demos, no cloud) |
| `classiq_cd_demo.py` | Qmod models for the CD operator and cat prep; writes `.qmod`, synthesizes if on a paid plan |
| `qiskit_cd_demo.py` | **free, local** gate circuit from the CD unitary: transpile + statevector run + QASM export |
| `generalized_cd.qmod` | generated Qmod source for the bare `CD_d` circuit |
| `generalized_cd_cat.qmod` | generated Qmod source for cat prep |
| `generalized_cd_qiskit.qasm` | OpenQASM 3 of the transpiled `CD_d` circuit (runs on any backend) |
| `requirements.txt` | `numpy`, `classiq`, `qiskit` |

## Two backends, one core

Both demos import the same verified `CD_d(α)` from `cd_builder.py`:

- **Classiq** (`classiq_cd_demo.py`) — high‑level Qmod synthesis. `synthesize()`
  requires a Classiq plan that permits synthesis (the free plan does **not**;
  it returns `403 User is not authorized`). The `.qmod` files are ready for when
  you have access.
- **Qiskit** (`qiskit_cd_demo.py`) — **free and fully local**. Decomposes the
  same unitary into gates, runs it on the statevector simulator, and proves the
  circuit reproduces the d‑legged cat. No account, no cloud.

## What runs where

| Step | Where | Account needed? |
|---|---|---|
| numpy verification (`cd_builder.py`) | local | no |
| build Qmod models + write `.qmod` | local | no |
| `synthesize()` → gate circuit | **Classiq cloud** | **yes** (`classiq.authenticate()`) |
| `execute()` → run/sample | Classiq cloud / hardware | yes |

## Run

```bash
# Python 3.10–3.12 (Classiq does not support 3.13+ yet)
pip install -r requirements.txt

# 1) framework-independent proof (prints ~1e-15 deviations, cat fidelity ~1.0)
python cd_builder.py

# 2) build Qmod + synthesize
python -c "import classiq; classiq.authenticate()"   # one-time browser login
python classiq_cd_demo.py
```

## Verified locally (no account)

```
unitarity_max_dev      : ~1e-15   (CD_d is exactly unitary)
qubit_convention_dev   : ~1e-15   (d=2 reduces to the standard qubit CD)
rotor_identity_dev     : ~1e-16   (Eq. 17: D(α Z̄_d) == block-diagonal CD_d)
cat_fidelity_min       : ~1.0     (projected state == analytic d-legged cat)
```

`classiq_cd_demo.py` builds both Qmod models and writes valid `.qmod` files
offline; only `synthesize()` needs the Classiq cloud (it returns
`401 Not authenticated` until you run `classiq.authenticate()`, and
`403 not authorized` on the free plan).

## Qiskit demo (free, local — no account)

```bash
pip install qiskit
python qiskit_cd_demo.py
```

Produces a real, runnable gate circuit and verifies it end‑to‑end:

```
transpile CD_d -> {cx, u}: depth 215, gates {u:184, cx:112} (total 296)
ordering cross-check max|sv - CD.init| : 5.55e-17
cat fidelity per m (0..3)             : [1.0, 1.0, 1.0, 1.0]
RESULT: REAL + RUNNABLE - circuit reproduces the cat
```

It also writes `generalized_cd_qiskit.qasm` (OpenQASM 3), so the circuit can run
on essentially any simulator or hardware backend.
