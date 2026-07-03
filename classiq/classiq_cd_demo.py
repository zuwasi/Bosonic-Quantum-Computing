"""Classiq (Qmod) demo: the generalized conditional displacement CD_d(alpha)
as a synthesizable gate-based qubit circuit.

This is the "machinery is real and runnable" demonstration for
arXiv:2405.09977v3, restricted to the parts that map onto Classiq's
discrete-variable (qubit) model:

  * CD_d(alpha)       -> a real gate circuit via the core `unitary` function.
  * d-legged cat prep -> prepare the ancilla in |m=0>, apply CD_d, (herald).
  * rotor identity (Eq. 17) -> CD_d is *built* as the qudit-controlled
    displacement D(alpha * Zbar_d); see cd_builder.generalized_cd_rotor and the
    numpy cross-check in cd_builder.verify().

Encoding (truncated, for a runnable demo):
  qudit d = 4      -> 2 qubits
  Fock  N = 8      -> 3 qubits
  total            -> 5 qubits, a 32x32 unitary.

The finite CD_d matrix is proven exact and unitary by cd_builder.verify()
(numpy only, no cloud). Classiq then decomposes that unitary into gates.

WHAT RUNS WHERE
  * numpy verification + building the Qmod model + writing .qmod : LOCAL, no account.
  * synthesize() / execute()                                    : Classiq CLOUD,
    requires `classiq.authenticate()` (a browser login you do yourself).

Run:
  pip install -U classiq        # Python 3.10-3.12
  python classiq_cd_demo.py     # writes .qmod locally; synthesizes if authenticated

NOTE: do not add `from __future__ import annotations` here - Classiq relies on
runtime evaluation of the quantum type annotations.
"""

import os

import numpy as np

from cd_builder import generalized_cd, verify

# ---- demo parameters (small enough to synthesize) ----
D = 4          # qudit levels  -> 2 qubits
N_FOCK = 8     # Fock levels   -> 3 qubits
ALPHA = 1.0
N_ANC = int(round(np.log2(D)))       # 2
N_OSC = int(round(np.log2(N_FOCK)))  # 3
N_QUBITS = N_ANC + N_OSC             # 5

# CD_d(alpha) built via the rotor identity (qudit-controlled displacement).
CD_LIST = generalized_cd(D, ALPHA, N_FOCK).tolist()

OUT_DIR = os.path.dirname(os.path.abspath(__file__))


def model_cd():
    """Bare CD_d(alpha) applied to |0...0>; proves the operator compiles."""
    from classiq import Output, QArray, QBit, allocate, create_model, qfunc, unitary

    @qfunc
    def main(reg: Output[QArray[QBit]]):
        allocate(N_QUBITS, reg)
        unitary(CD_LIST, reg)

    return create_model(main)


def model_cat():
    """d-legged cat prep: ancilla in |m=0>, then CD_d on ancilla (x) oscillator.

    |m=0> (the Xbar_d eigenstate) is the uniform superposition, i.e.
    hadamard_transform on the ancilla qubits. CD_d is built with the qudit as
    the outer (most-significant) tensor factor, so the ancilla is bound first.
    If an execution herald disagrees with cd_builder's reference cat, swap the
    bind order to [osc, anc].
    """
    from classiq import (
        Output,
        QArray,
        QBit,
        allocate,
        bind,
        create_model,
        hadamard_transform,
        qfunc,
        unitary,
    )

    @qfunc
    def main(anc: Output[QArray[QBit]], osc: Output[QArray[QBit]]):
        allocate(N_ANC, anc)
        allocate(N_OSC, osc)
        hadamard_transform(anc)          # prepare |m = 0>
        combined = QArray("combined")
        bind([anc, osc], combined)
        unitary(CD_LIST, combined)       # CD_d(alpha)
        bind(combined, [anc, osc])
        # To herald a specific cat, measure `anc` at execution and post-select m.

    return create_model(main)


def main():
    # 1) LOCAL proof that the finite CD_d machinery is exact.
    res = verify(D, ALPHA, N_FOCK)
    print("numpy verification (no cloud):")
    for k in ("unitarity_max_dev", "qubit_convention_dev", "rotor_identity_dev", "cat_fidelity_min"):
        print(f"  {k:22s} : {res[k]}")
    print(f"  qubits                 : {N_QUBITS}  (d={D} -> {N_ANC}, N={N_FOCK} -> {N_OSC})")

    # 2) LOCAL: build the Qmod models and write .qmod source files.
    from classiq import write_qmod

    models = {"generalized_cd": model_cd(), "generalized_cd_cat": model_cat()}
    for name, model in models.items():
        write_qmod(model, os.path.join(OUT_DIR, name))
        print(f"wrote {name}.qmod")

    # 3) CLOUD: synthesize to gate circuits (requires classiq.authenticate()).
    try:
        from classiq import synthesize

        for name, model in models.items():
            qprog = synthesize(model)
            print(f"synthesized {name} (cloud) OK")
            try:
                qprog.save_to_file(os.path.join(OUT_DIR, f"{name}.qprog"))
                print(f"  saved {name}.qprog")
            except Exception:
                pass
    except Exception as exc:  # not authenticated / offline
        print("\nsynthesis skipped (Classiq cloud):", type(exc).__name__)
        print('Run:  python -c "import classiq; classiq.authenticate()"   once, then rerun.')


if __name__ == "__main__":
    main()
