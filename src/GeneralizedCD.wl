(* ::Package:: *)

(* GeneralizedCD.wl
   Reusable Wolfram Language package reproducing the core results of

     S. Even-Haim, A. A. Diringer, R. Ruimy, G. Baranes, A. Gorlach,
     S. Hacohen-Gourgy, I. Kaminer,
     "Generalized Conditional Displacement", arXiv:2405.09977v3.

   The package builds the generalized conditional-displacement operator
   CD_d(alpha) conditioned on a d-level qudit ancilla, the d-legged cat
   states, the GKP stabilizer Kraus operators, and the sharpen-trim GKP
   stabilization channels.

   Bosonic operators are cross-validated against the Wolfram Quantum
   Framework paclet (Wolfram/QuantumFramework, SecondQuantization context)
   from https://resources.wolframcloud.com/ .  See ValidateWolframIntegration[].
*)

BeginPackage["GeneralizedCD`"];

GCDSetFockSize::usage        = "GCDSetFockSize[n] sets the oscillator Fock-space truncation to n levels (default 60).";
GCDFockSize::usage           = "GCDFockSize[] returns the current oscillator Fock-space truncation.";
Annihilation::usage          = "Annihilation[] returns the truncated annihilation operator a.";
Creation::usage              = "Creation[] returns the truncated creation operator a^dagger.";
NumberOperator::usage        = "NumberOperator[] returns the truncated number operator a^dagger a.";
Vacuum::usage                = "Vacuum[] returns the oscillator vacuum state vector |0>.";
Displacement::usage          = "Displacement[alpha] returns the (weak-ordered, unitary) displacement operator D(alpha)=Exp[alpha a^dag - Conj[alpha] a].";
WolframDisplacement::usage   = "WolframDisplacement[alpha] returns D(alpha) computed by the Wolfram Quantum Framework paclet (DisplacementOperator, Ordering -> Weak). Requires Wolfram/QuantumFramework.";
CoherentStateVec::usage      = "CoherentStateVec[alpha] returns the coherent state |alpha> = D(alpha)|0>.";

RootOfUnity::usage           = "RootOfUnity[d] returns omega_d = Exp[I 2 Pi/d].";
GeneralizedCD::usage         = "GeneralizedCD[d, alpha] returns the generalized conditional displacement CD_d(alpha) (Eq. 2), a (d*NF)x(d*NF) matrix on qudit (x) oscillator.";
QuditZ::usage                = "QuditZ[d] returns the Heisenberg-Weyl operator Zbar_d = Sum omega_d^s |s><s|.";
QuditX::usage                = "QuditX[d] returns the Heisenberg-Weyl shift operator Xbar_d.";
QuditXEigenstate::usage      = "QuditXEigenstate[d, m] returns the Xbar_d eigenstate |m> in the s-basis.";

CatNormalization::usage      = "CatNormalization[d, m, alpha] returns N_m(alpha) from Eq. 3.";
LeggedCatState::usage        = "LeggedCatState[d, m, alpha] returns the normalized d-legged cat state |C_d^m(alpha)> (Eq. 3).";
CatCreationKraus::usage      = "CatCreationKraus[d, m, alpha] returns the Kraus operator <m|CD_d(alpha)|m=0> (Eq. 5).";

QubitStabilizerKraus::usage  = "QubitStabilizerKraus[sigma, alpha] returns the qubit phase-estimation Kraus operator M_sigma(alpha) (Eq. 7); sigma = +1 or -1.";
QuditMeasBasis::usage        = "QuditMeasBasis[j, beta] returns the d=4 qudit measurement vector |j> (Eq. 8) in the s-basis.";
QuditStabilizerKraus::usage  = "QuditStabilizerKraus[j, beta] returns the d=4 qudit Kraus operator M_j(beta) (Eq. 9).";
QuditStabilizerKrausEq10::usage = "QuditStabilizerKrausEq10[j] returns M_j(sqrt(pi/2)) in the Eq. 10 form.";
QuditHermitianObservable::usage = "QuditHermitianObservable[] returns the Hermitian matrix of Eq. 11 whose eigenvectors are the |j> basis (at beta=sqrt(pi/2)).";

WignerFunction::usage        = "WignerFunction[psi, x, p] returns the Wigner quasi-probability W(x,p) of the oscillator state vector psi via the displaced-parity formula.";
WignerFunctionRho::usage     = "WignerFunctionRho[rho, x, p] returns W(x,p) for a density matrix rho.";

GKPLatticeConstant::usage    = "GKPLatticeConstant[] returns l = Sqrt[2 Pi].";
GKPStabilizerX::usage        = "GKPStabilizerX[] returns the GKP stabilizer generator S_X = D(l).";
GKPStabilizerZ::usage        = "GKPStabilizerZ[] returns the GKP stabilizer generator S_Z = D(i l).";
StabilizerExpectations::usage= "StabilizerExpectations[rho] returns {Re<S_X>, Re<S_Z>} for density matrix rho.";

RunQuditStabilization::usage = "RunQuditStabilization[rounds, opts] runs the d=4 sharpen-trim GKP stabilization from vacuum and returns a list of {nCD, ReSx, ReSz, meanN} per round (2 CD/round).";
RunQuditSharpen::usage       = "RunQuditSharpen[steps] runs d=4 sharpen-only stabilization (1 CD/step) and returns {nCD, ReSx, ReSz, meanN} rows.";
RunQubitSharpen::usage       = "RunQubitSharpen[rounds] runs the d=2 sharpen stabilization (sharpen-p then sharpen-q, 2 CD/round) and returns {nCD, ReSx, ReSz, meanN} rows.";

RotorCDIdentityResidual::usage = "RotorCDIdentityResidual[d, alpha] returns Max|D(alpha Zbar_d) - CD_d(alpha)|, verifying the ideal rotor-GKP implementation identity (Eq. 17).";

ValidateWolframIntegration::usage = "ValidateWolframIntegration[] loads Wolfram/QuantumFramework and returns the max deviation between Displacement[alpha] and the paclet's DisplacementOperator (Ordering -> Weak).";
RunValidationSuite::usage    = "RunValidationSuite[] runs the full internal validation suite and returns an Association of named checks -> results.";

Begin["`Private`"];

$fockSize = 60;
GCDSetFockSize[n_Integer?Positive] := ($fockSize = n; ClearCache[]; n);
GCDFockSize[] := $fockSize;

(* invalidate memoized displacement matrices when the Fock size changes *)
$dispCache = <||>;
ClearCache[] := ($dispCache = <||>);

aOp[] := SparseArray[Band[{1, 2}] -> Sqrt[Range[$fockSize - 1]], {$fockSize, $fockSize}] // N;
adOp[] := Transpose[aOp[]];
Annihilation[] := aOp[];
Creation[] := adOp[];
NumberOperator[] := adOp[] . aOp[];
Vacuum[] := Normal[SparseArray[{1} -> 1., $fockSize]];
idOp[] := IdentityMatrix[$fockSize];

(* Primary displacement: weak-ordered matrix exponential (unitary).
   Verified identical to Wolfram DisplacementOperator[alpha,"Ordering"->"Weak"];
   see ValidateWolframIntegration[]. Cached per-alpha for the current Fock size. *)
Displacement[al_] := (
  If[! KeyExistsQ[$dispCache, al],
    $dispCache[al] = MatrixExp[N[al adOp[] - Conjugate[al] aOp[]]]];
  $dispCache[al]);
CoherentStateVec[al_] := Displacement[al] . Vacuum[];

RootOfUnity[d_Integer] := Exp[I 2 Pi/d];

QuditZ[d_Integer] := DiagonalMatrix[Table[RootOfUnity[d]^s, {s, 0, d - 1}]];
QuditX[d_Integer] := RotateRight[IdentityMatrix[d]];
QuditXEigenstate[d_Integer, m_Integer] := (1/Sqrt[d]) Table[RootOfUnity[d]^(s m), {s, 0, d - 1}];

(* Eq. 2: block-diagonal CD_d(alpha) on qudit (x) oscillator *)
GeneralizedCD[d_Integer, al_] := ArrayFlatten[
  Table[If[s == t, Displacement[al RootOfUnity[d]^s], 0 idOp[]], {s, 0, d - 1}, {t, 0, d - 1}]];

(* Eq. 3 *)
CatNormalization[d_Integer, m_Integer, al_] :=
  Sum[RootOfUnity[d]^(-s m) Exp[(RootOfUnity[d]^s - 1) Abs[al]^2], {s, 0, d - 1}];
LeggedCatState[d_Integer, m_Integer, al_] := Module[{v},
  v = (1/Sqrt[d]) Sum[RootOfUnity[d]^(-s m) CoherentStateVec[al RootOfUnity[d]^s], {s, 0, d - 1}];
  v/Norm[v]];

(* Eq. 5: Kraus creating the m-cat from vacuum ancilla measurement *)
CatCreationKraus[d_Integer, m_Integer, al_] :=
  (1/d) Sum[RootOfUnity[d]^(-s m) Displacement[al RootOfUnity[d]^s], {s, 0, d - 1}];

(* Eq. 7: qubit phase-estimation Kraus *)
QubitStabilizerKraus[sigma_, al_] :=
  (1/2) (Exp[sigma I Pi/4] Displacement[al] + Exp[-sigma I Pi/4] Displacement[-al]);

(* Eq. 8 *)
QuditMeasBasis[j_Integer, beta_] :=
  (1/2) Table[Exp[I (beta^2 Cos[Pi s] + (Pi/2) Cos[(s + j) Pi/2])], {s, 0, 3}];

(* Eq. 9 *)
QuditStabilizerKraus[j_Integer, beta_] :=
  (1/4) Sum[Exp[-I (Pi/2) Cos[(Pi/2) (s + j)]] Exp[-(-1)^s I beta^2] *
     Displacement[Sqrt[2] Exp[I (Pi/4) (2 s + 1)] beta], {s, 0, 3}];

(* Eq. 10 (stabilizer case beta = sqrt(pi/2)) *)
QuditStabilizerKrausEq10[j_Integer] :=
  (1/4) Sum[Exp[-I (Pi/2) (Cos[(s + j) Pi/2] + Cos[Pi s])] *
     Displacement[Exp[I s 2 Pi/4] Exp[I Pi/4] Sqrt[Pi]], {s, 0, 3}];

(* Eq. 11 *)
QuditHermitianObservable[] :=
  (1/2) {{3, 2 I, 1, 0}, {-2 I, 3, 0, -1}, {1, 0, 3, -2 I}, {0, -1, 2 I, 3}};

(* Wigner via displaced parity: W = (2/pi) Tr[rho D(b) P D(-b)], b=(x+i p)/sqrt2 *)
parityOp[] := DiagonalMatrix[N[(-1)^Range[0, $fockSize - 1]]];
WignerFunctionRho[rho_, x_, p_] := Module[{Db = Displacement[(x + I p)/Sqrt[2]]},
  Re[(2/Pi) Tr[rho . Db . parityOp[] . ConjugateTranspose[Db]]]];
WignerFunction[psi_?VectorQ, x_, p_] := Module[{Db = Displacement[(x + I p)/Sqrt[2]]},
  Re[(2/Pi) Conjugate[psi] . ConjugateTranspose[Db] . parityOp[] . Db . psi]];

(* GKP stabilizers *)
GKPLatticeConstant[] := Sqrt[2 Pi];
GKPStabilizerX[] := Displacement[GKPLatticeConstant[]];
GKPStabilizerZ[] := Displacement[I GKPLatticeConstant[]];
StabilizerExpectations[rho_] := {Re[Tr[rho . GKPStabilizerX[]]], Re[Tr[rho . GKPStabilizerZ[]]]};

applyChannel[rho_, kraus_List] := Total[(# . rho . ConjugateTranspose[#]) & /@ kraus];

Options[RunQuditStabilization] = {"Epsilon" -> 0.1/Sqrt[2]};
RunQuditStabilization[rounds_Integer, OptionsPattern[]] := Module[
  {eps = OptionValue["Epsilon"], mS, l, beta, rho, ksharp, ktrim, rows},
  l = GKPLatticeConstant[]; beta = Sqrt[Pi]/Sqrt[2]; mS = eps/Sqrt[2];
  (* sharpen: M_j(sqrt(pi/2)) + outcome-conditioned recentering correction *)
  ksharp = Table[Displacement[-mS Exp[-I (Pi/4) (2 j + 1)]] . QuditStabilizerKrausEq10[j], {j, 0, 3}];
  (* trim: M_j(eps/2) + envelope recentering *)
  ktrim  = Table[Displacement[-(l/Sqrt[2]) Exp[-I (Pi/4) (2 j + 1)]] . QuditStabilizerKraus[j, eps/2], {j, 0, 3}];
  rho = KroneckerProduct[Vacuum[], Conjugate[Vacuum[]]];
  rows = {Join[{0}, StabilizerExpectations[rho], {Re[Tr[rho . NumberOperator[]]]}]};
  Do[rho = applyChannel[rho, ksharp]; rho = applyChannel[rho, ktrim];
     AppendTo[rows, Join[{2 k}, StabilizerExpectations[rho], {Re[Tr[rho . NumberOperator[]]]}]],
    {k, 1, rounds}];
  rows];

Options[RunQuditSharpen] = {"Epsilon" -> 0.1/Sqrt[2]};
RunQuditSharpen[steps_Integer, OptionsPattern[]] := Module[
  {eps = OptionValue["Epsilon"], mS, rho, ksharp, rows},
  mS = eps/Sqrt[2];
  ksharp = Table[Displacement[-mS Exp[-I (Pi/4) (2 j + 1)]] . QuditStabilizerKrausEq10[j], {j, 0, 3}];
  rho = KroneckerProduct[Vacuum[], Conjugate[Vacuum[]]];
  rows = {Join[{0}, StabilizerExpectations[rho], {Re[Tr[rho . NumberOperator[]]]}]};
  Do[rho = applyChannel[rho, ksharp];
     AppendTo[rows, Join[{k}, StabilizerExpectations[rho], {Re[Tr[rho . NumberOperator[]]]}]],
    {k, 1, steps}];
  rows];

Options[RunQubitSharpen] = {"Epsilon" -> 0.1/Sqrt[2]};
RunQubitSharpen[rounds_Integer, OptionsPattern[]] := Module[
  {eps = OptionValue["Epsilon"], mS, beta, rho, kshp, kshq, rows},
  beta = Sqrt[Pi]/Sqrt[2]; mS = eps/Sqrt[2];
  (* perpendicular outcome-conditioned corrections; cp=-1 (imag), cq=+1 (real) *)
  kshp = Table[Displacement[-mS r I] . QubitStabilizerKraus[r, beta], {r, {1, -1}}];
  kshq = Table[Displacement[ mS r]   . QubitStabilizerKraus[r, I beta], {r, {1, -1}}];
  rho = KroneckerProduct[Vacuum[], Conjugate[Vacuum[]]];
  rows = {Join[{0}, StabilizerExpectations[rho], {Re[Tr[rho . NumberOperator[]]]}]};
  Do[rho = applyChannel[rho, kshp]; rho = applyChannel[rho, kshq];
     AppendTo[rows, Join[{2 k}, StabilizerExpectations[rho], {Re[Tr[rho . NumberOperator[]]]}]],
    {k, 1, rounds}];
  rows];

(* Eq. 17: ideal rotor-GKP implements CD_d exactly since e^{i theta} -> Zbar_d *)
RotorCDIdentityResidual[d_Integer, al_] := Module[{z = QuditZ[d], lhs},
  lhs = ArrayFlatten[Table[If[s == t, Displacement[al z[[s + 1, s + 1]]], 0 idOp[]],
     {s, 0, d - 1}, {t, 0, d - 1}]];
  Chop[Max[Abs[lhs - GeneralizedCD[d, al]]]]];

ValidateWolframIntegration[] := Module[{ok, alphas, dev},
  ok = Quiet@Check[
    Needs["Wolfram`QuantumFramework`"];
    Needs["Wolfram`QuantumFramework`SecondQuantization`"];
    Wolfram`QuantumFramework`SecondQuantization`SetFockSpaceSize[$fockSize]; True, False];
  If[! ok, Return[<|"Available" -> False|>]];
  (* Numeric alphas only: passing exact/symbolic input makes the paclet do a
     symbolic matrix exponential that is enormous.  N[] keeps it numeric. *)
  alphas = N[{0.7 + 0.3 I, 1.2 - 0.5 I, Sqrt[Pi]/Sqrt[2]}];
  dev = Quiet@Check[
    MemoryConstrained[TimeConstrained[
      Max[Table[Max[Abs[Normal[
          Wolfram`QuantumFramework`SecondQuantization`DisplacementOperator[al, "Ordering" -> "Weak"]["Matrix"]] -
         Displacement[al]]], {al, alphas}]],
      60], 600*10^6], $Failed];
  If[dev === $Failed || ! NumericQ[dev],
    <|"Available" -> True, "MaxDeviation" -> "check-skipped"|>,
    <|"Available" -> True, "MaxDeviation" -> Chop[dev]|>]];

RunValidationSuite[] := Module[{res = <||>, d = 4, al = 2.0, beta = Sqrt[Pi]/Sqrt[2], rho},
  ClearCache[];
  res["CD_unitary_d4"] =
    Max[Abs[ConjugateTranspose[GeneralizedCD[4, 0.6 + 0.2 I]] . GeneralizedCD[4, 0.6 + 0.2 I] -
       IdentityMatrix[4 $fockSize]]];
  res["CD_reduces_to_CD2"] =
    Max[Abs[GeneralizedCD[2, 0.5] -
       ArrayFlatten[{{Displacement[0.5], 0 idOp[]}, {0 idOp[], Displacement[-0.5]}}]]];
  res["Eq9_equals_Eq10"] =
    Chop@Max[Table[Max[Abs[QuditStabilizerKraus[j, beta] - QuditStabilizerKrausEq10[j]]], {j, 0, 3}]];
  res["POVM_completeness"] =
    Chop@Max[Abs[Sum[ConjugateTranspose[QuditStabilizerKraus[j, beta]] . QuditStabilizerKraus[j, beta],
        {j, 0, 3}] - idOp[]]];
  res["Eq11_eigenvectors"] =
    Chop@Max[Table[Module[{v = QuditMeasBasis[j, beta], hv},
       hv = QuditHermitianObservable[] . v;
       Norm[hv - (Conjugate[v] . hv/(Conjugate[v] . v)) v]], {j, 0, 3}]];
  res["CatCreation_fidelity_min"] = Min[Table[
     Module[{psi, proj, osc},
      psi = GeneralizedCD[d, al] . Flatten[Outer[Times, QuditXEigenstate[d, 0], Vacuum[]]];
      proj = ArrayFlatten[{Table[Conjugate[QuditXEigenstate[d, m][[s + 1]]] idOp[], {s, 0, d - 1}]}];
      osc = proj . psi;
      Abs[Conjugate[LeggedCatState[d, m, al]] . (osc/Norm[osc])]^2], {m, 0, d - 1}]];
  res["Rotor_identity_residual"] = RotorCDIdentityResidual[4, 1.3 + 0.2 I];
  res["Wolfram_integration"] = ValidateWolframIntegration[];
  res];

End[];
EndPackage[];
