"""Qiskit local demo: the generalized conditional displacement CD_d(alpha) as a
real, runnable gate circuit - no cloud, no paid plan.

This is the free/local counterpart of classiq_cd_demo.py. It reuses the exact
same CD_d(alpha) unitary from cd_builder.py and:

  1. builds a gate circuit from the CD_d unitary (UnitaryGate),
  2. transpiles it to basis gates and reports gate counts + depth,
  3. runs it on Qiskit's local statevector simulator: prepare |m=0> (x) |0>,
     apply CD_d, and verify the output equals the analytic d-legged cat (Eq. 3)
     with fidelity ~ 1,
  4. exports OpenQASM 3 so the circuit runs on essentially any backend.

Encoding (matches the Classiq demo):
  qudit d = 4  -> 2 qubits   (ancilla)
  Fock  N = 8  -> 3 qubits   (oscillator)
  total        -> 5 qubits, a 32x32 unitary.

Qubit ordering: CD_d is built with the qudit as the outer (most-significant)
tensor factor: matrix index = q * N + f. Qiskit is little-endian, so the
oscillator qubits are the low-order qubits [0..n_osc-1] and the ancilla qubits
are the high-order qubits. The code asserts the circuit statevector equals the
numpy reference CD @ init, so the ordering is verified, not assumed.

Run:
  pip install qiskit
  python qiskit_cd_demo.py
"""

import os

import numpy as np
from qiskit import QuantumCircuit, transpile
from qiskit.qasm3 import dumps as qasm3_dumps
from qiskit.quantum_info import Statevector

from cd_builder import (
    generalized_cd,
    legged_cat_state,
    qudit_x_eigenstate,
    vacuum,
)

# ---- demo parameters (match classiq_cd_demo.py) ----
D = 4
N_FOCK = 8
ALPHA = 1.0
N_ANC = int(round(np.log2(D)))       # 2
N_OSC = int(round(np.log2(N_FOCK)))  # 3
N_QUBITS = N_ANC + N_OSC             # 5

OSC_QUBITS = list(range(N_OSC))                       # [0,1,2]  low-order (LSB)
ANC_QUBITS = list(range(N_OSC, N_OSC + N_ANC))        # [3,4]    high-order (MSB)

CD = generalized_cd(D, ALPHA, N_FOCK)
OUT_DIR = os.path.dirname(os.path.abspath(__file__))


def cd_circuit():
    """Bare CD_d(alpha) as a single UnitaryGate on N_QUBITS qubits."""
    qc = QuantumCircuit(N_QUBITS, name="CD_d")
    qc.unitary(CD, OSC_QUBITS + ANC_QUBITS, label="CD_d")
    return qc


def cat_prep_circuit():
    """Prepare |m=0> (x) |vacuum>, then apply CD_d(alpha)."""
    qc = QuantumCircuit(N_QUBITS, name="cat_prep")
    for q in ANC_QUBITS:          # |m=0> = uniform superposition (Xbar_d eigenstate)
        qc.h(q)
    # oscillator qubits stay in |0..0> = Fock vacuum
    qc.unitary(CD, OSC_QUBITS + ANC_QUBITS, label="CD_d")
    return qc


def report_transpile():
    print("2) transpile CD_d to basis gates {cx, u} (optimization_level=3):")
    t = transpile(cd_circuit(), basis_gates=["cx", "u"], optimization_level=3)
    ops = dict(t.count_ops())
    print(f"   qubits : {t.num_qubits}")
    print(f"   depth  : {t.depth()}")
    print(f"   gates  : {ops}  (total {sum(ops.values())})")
    return t


def verify_on_simulator():
    print("3) statevector simulation - does the circuit produce the cat?")
    qc = cat_prep_circuit()
    sv = Statevector(qc).data  # index = q*N + f (matches cd_builder ordering)

    # ordering cross-check: circuit output == numpy CD @ init
    init = np.kron(qudit_x_eigenstate(D, 0), vacuum(N_FOCK))
    ref = CD @ init
    ordering_dev = float(np.max(np.abs(sv - ref)))

    # herald each outcome m and compare oscillator state to the analytic cat
    blocks = sv.reshape(D, N_FOCK)
    fids = []
    for m in range(D):
        weights = np.conj(qudit_x_eigenstate(D, m))
        osc = np.tensordot(weights, blocks, axes=(0, 0))
        osc = osc / np.linalg.norm(osc)
        cat = legged_cat_state(D, m, ALPHA, N_FOCK)
        fids.append(abs(np.vdot(cat, osc)) ** 2)

    print(f"   ordering cross-check max|sv - CD.init| : {ordering_dev:.2e}")
    print(f"   cat fidelity per m (0..{D-1})          : {[round(f, 6) for f in fids]}")
    print(f"   cat fidelity (min)                     : {min(fids):.6f}")
    return ordering_dev, float(min(fids))


def export_qasm(transpiled):
    path = os.path.join(OUT_DIR, "generalized_cd_qiskit.qasm")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(qasm3_dumps(transpiled))
    print(f"4) wrote OpenQASM 3 -> {os.path.basename(path)}")


def main():
    print("Qiskit local demo - generalized conditional displacement")
    print("=" * 58)
    print(f"1) encoding: d={D} ({N_ANC} qubits) x Fock N={N_FOCK} ({N_OSC} qubits)"
          f" = {N_QUBITS} qubits, {D*N_FOCK}x{D*N_FOCK} unitary")
    t = report_transpile()
    ordering_dev, cat_min = verify_on_simulator()
    export_qasm(t)
    print("=" * 58)
    ok = ordering_dev < 1e-9 and cat_min > 0.999
    print("RESULT:", "REAL + RUNNABLE - circuit reproduces the cat" if ok else "CHECK FAILED")


if __name__ == "__main__":
    main()
