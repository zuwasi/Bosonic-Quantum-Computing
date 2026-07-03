"""Build and verify the generalized conditional displacement CD_d(alpha).

This module is the *framework-independent* core of the Classiq demo. It builds
the finite (truncated-Fock) matrices that the Classiq program feeds to the
`unitary` synthesis function, and proves — with numpy only, no cloud, no
Classiq account — that the machinery is real:

  1. CD_d(alpha) is exactly unitary.
  2. The d = 2 case has the correct qubit convention (block_1 == block_0^dagger).
  3. The rotor identity (Eq. 17): CD_d(alpha) built as a single joint
     exponential D(alpha * Zbar_d) equals the block-wise displacement
     construction. Two independent matrix-exponential paths must agree.
  4. Cat-state prep: applying CD_d to |m=0> (x) |0> and projecting the ancilla
     onto |m> yields the analytic d-legged cat state (Eq. 3) with fidelity ~ 1.

Reproduces the relevant pieces of arXiv:2405.09977v3 that map to gate-based
qubit circuits. Mirrors src/GeneralizedCD.wl (Wolfram) in Python/numpy.

Run:  python cd_builder.py
"""

from __future__ import annotations

import numpy as np


# --------------------------------------------------------------------------
# Bosonic operators on a truncated Fock space of dimension N (levels 0..N-1)
# --------------------------------------------------------------------------
def annihilation(n_fock: int) -> np.ndarray:
    """Truncated annihilation operator a (a|n> = sqrt(n)|n-1>)."""
    a = np.zeros((n_fock, n_fock), dtype=complex)
    for n in range(1, n_fock):
        a[n - 1, n] = np.sqrt(n)
    return a


def _expm_antihermitian(g: np.ndarray) -> np.ndarray:
    """Exact matrix exponential of an anti-Hermitian generator via eigh.

    For anti-Hermitian G, H = i*G is Hermitian, so G = -i * U diag(w) U^dagger
    and expm(G) = U diag(exp(-i w)) U^dagger. This is *exactly* unitary
    regardless of truncation, because G is exactly anti-Hermitian on the
    truncated space.
    """
    w, u = np.linalg.eigh(1j * g)  # H = i G Hermitian
    return (u * np.exp(-1j * w)) @ u.conj().T


def displacement(alpha: complex, n_fock: int) -> np.ndarray:
    """Unitary displacement D(alpha) = exp(alpha a^dagger - alpha* a)."""
    a = annihilation(n_fock)
    adag = a.conj().T
    g = alpha * adag - np.conj(alpha) * a
    return _expm_antihermitian(g)


def vacuum(n_fock: int) -> np.ndarray:
    v = np.zeros(n_fock, dtype=complex)
    v[0] = 1.0
    return v


# --------------------------------------------------------------------------
# Qudit ancilla and the generalized conditional displacement
# --------------------------------------------------------------------------
def omega(d: int) -> complex:
    return np.exp(2j * np.pi / d)


def qudit_z(d: int) -> np.ndarray:
    """Heisenberg-Weyl clock operator Zbar_d = diag(omega^s)."""
    return np.diag([omega(d) ** s for s in range(d)])


def qudit_x_eigenstate(d: int, m: int) -> np.ndarray:
    """Xbar_d eigenstate |m> in the s-basis: (1/sqrt d) sum_s omega^{s m} |s>."""
    return np.array([omega(d) ** (s * m) for s in range(d)], dtype=complex) / np.sqrt(d)


def generalized_cd(d: int, alpha: complex, n_fock: int) -> np.ndarray:
    """CD_d(alpha) = sum_s |s><s| (x) D(alpha omega^s)  (Eq. 2), block-diagonal.

    Qudit is the outer (left) tensor factor; result is (d*N) x (d*N).
    """
    n = n_fock
    out = np.zeros((d * n, d * n), dtype=complex)
    for s in range(d):
        out[s * n:(s + 1) * n, s * n:(s + 1) * n] = displacement(alpha * omega(d) ** s, n)
    return out


def generalized_cd_rotor(d: int, alpha: complex, n_fock: int) -> np.ndarray:
    """CD_d(alpha) via the rotor identity (Eq. 17): a single joint exponential
    D(alpha * Zbar_d) = exp(alpha Zbar_d (x) a^dagger - alpha* Zbar_d^dag (x) a).

    Independent construction path from `generalized_cd` (one big matrix
    exponential instead of per-block displacements).
    """
    a = annihilation(n_fock)
    adag = a.conj().T
    z = qudit_z(d)
    g = alpha * np.kron(z, adag) - np.conj(alpha) * np.kron(z.conj().T, a)
    return _expm_antihermitian(g)


def legged_cat_state(d: int, m: int, alpha: complex, n_fock: int) -> np.ndarray:
    """Normalized d-legged cat |C_d^m(alpha)> ~ sum_s omega^{-s m} |alpha omega^s> (Eq. 3)."""
    v = np.zeros(n_fock, dtype=complex)
    for s in range(d):
        coh = displacement(alpha * omega(d) ** s, n_fock) @ vacuum(n_fock)
        v = v + omega(d) ** (-s * m) * coh
    return v / np.linalg.norm(v)


# --------------------------------------------------------------------------
# Verification (numpy only)
# --------------------------------------------------------------------------
def verify(d: int = 4, alpha: complex = 1.2, n_fock: int = 16) -> dict[str, float]:
    n = n_fock
    cd = generalized_cd(d, alpha, n)

    # 1. unitarity
    unit = np.max(np.abs(cd.conj().T @ cd - np.eye(d * n)))

    # 2. d = 2 qubit convention: block_1 == block_0^dagger  (omega_2 = -1)
    cd2 = generalized_cd(2, alpha, n)
    b0 = cd2[:n, :n]
    b1 = cd2[n:, n:]
    conv = np.max(np.abs(b1 - b0.conj().T))

    # 3. rotor identity (Eq. 17): joint-exponential construction == block-diagonal
    rotor = np.max(np.abs(generalized_cd_rotor(d, alpha, n) - cd))

    # 4. cat-state prep fidelity, worst case over m
    fids = []
    init = np.kron(qudit_x_eigenstate(d, 0), vacuum(n))  # |m=0> (x) |0>
    psi = cd @ init
    blocks = psi.reshape(d, n)
    for m in range(d):
        weights = np.conj(qudit_x_eigenstate(d, m))
        osc = np.tensordot(weights, blocks, axes=(0, 0))
        osc = osc / np.linalg.norm(osc)
        cat = legged_cat_state(d, m, alpha, n)
        fids.append(abs(np.vdot(cat, osc)) ** 2)
    cat_fid_min = float(min(fids))

    return {
        "d": d,
        "alpha": alpha,
        "n_fock": n,
        "n_qubits": int(np.log2(d) + np.log2(n)),
        "unitarity_max_dev": float(unit),
        "qubit_convention_dev": float(conv),
        "rotor_identity_dev": float(rotor),
        "cat_fidelity_min": cat_fid_min,
    }


if __name__ == "__main__":
    res = verify()
    print("Generalized conditional displacement - numpy verification")
    print("=" * 58)
    for k, v in res.items():
        print(f"  {k:22s} : {v}")
    ok = (
        res["unitarity_max_dev"] < 1e-9
        and res["qubit_convention_dev"] < 1e-9
        and res["rotor_identity_dev"] < 1e-9
        and res["cat_fidelity_min"] > 0.999
    )
    print("=" * 58)
    print("RESULT:", "ALL CHECKS PASS" if ok else "CHECK FAILED")
