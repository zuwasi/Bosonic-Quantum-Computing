# Validation Report - Generalized Conditional Displacement

arXiv:2405.09977v3 reproduction. Fock truncation = 80.

| Check | Paper ref | Result | Status |
|---|---|---|---|
| CD_d unitarity | Eq. 2 | 0 (exact, < 1e-9) | PASS |
| CD_d reduces to CD_2 | Eq. 1,2 | 0 (exact, < 1e-9) | PASS |
| Kraus Eq. 9 = Eq. 10 | Eq. 9,10 | 0 (exact, < 1e-9) | PASS |
| POVM completeness | Eq. 9 | 0 (exact, < 1e-9) | PASS |
| Eq. 11 eigenvectors = |j> | Eq. 8,11 | 0 (exact, < 1e-9) | PASS |
| Cat creation fidelity (min) | Eq. 5,6 | 1. | PASS |
| Rotor identity D(aZ)=CD_d | Eq. 17 | 0 (exact, < 1e-9) | PASS |
| Wolfram QF DisplacementOperator match | resources.wolframcloud.com | 0 (exact, < 1e-9) | PASS |

## GKP stabilization (Fig. 2d)

Qudit d=4 sharpen-trim from vacuum converges to <S_x>=<S_z> = 0.7984 with mean photon number 15.23 after 70 CD operations (monotone, bounded energy).

Apples-to-apples sharpen comparison, CD operations to first reach <S> = 0.5:
- qudit d=4 sharpen (1 CD/round, both quadratures): 6 CD operations
- qubit d=2 sharpen (2 CD/round): 10 CD operations

The qudit addresses both quadratures per CD, so a full stabilization round costs
2 CD operations for the qudit vs 4 for the qubit, and it reaches a target <S> at
fewer CD operations in the rising regime.

Note: the exact finite-energy qubit *trim* feedback is specified in the paper's
supplementary material, which is not included in this PDF. The sharpen feedback and
the qudit trim were reconstructed from the main text and verified by convergence.
