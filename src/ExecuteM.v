Require Import Coq.ZArith.BinInt.
Require Import riscv.util.NameWithEq.
Require Import riscv.RiscvBitWidths.
Require Import riscv.util.StateMonad.
Require Import riscv.Utility.
Require Import riscv.NoVirtualMemory.
Require Import riscv.Decode.
Require Import riscv.Program.

Local Open Scope Z.
Local Open Scope alu_scope.
Local Open Scope bool_scope.

Section Riscv.

  Context {Name: NameWithEq}. (* register name *)
  Notation Register := (@name Name).
  Existing Instance eq_name_dec.

  Context {B: RiscvBitWidths}.

  Context {t: Set}.

  Context {MW: MachineWidth t}.

  Definition execute{M: Type -> Type}{MM: Monad M}{MP: MonadPlus M}{RVS: RiscvState M}
    (i: Instruction): M unit :=
    match i with
    (* begin ast *)
    | Mul rd rs1 rs2 =>
        x <- getRegister rs1;
        y <- getRegister rs2;
        setRegister rd (x * y)
    | Mulh rd rs1 rs2 =>
        x <- getRegister rs1;
        y <- getRegister rs2;
        setRegister rd (highBits ((regToZ_signed x) * (regToZ_signed y)) : t)
    | Mulhsu rd rs1 rs2 =>
        x <- getRegister rs1;
        y <- getRegister rs2;
        setRegister rd (highBits ((regToZ_signed x) * (regToZ_unsigned y)) : t)
    | Mulhu rd rs1 rs2 =>
        x <- getRegister rs1;
        y <- getRegister rs2;
        setRegister rd (highBits ((regToZ_unsigned x) * (regToZ_unsigned y)) : t)
    | Div rd rs1 rs2 =>
        x <- getRegister rs1;
        y <- getRegister rs2;
        let q := (if x == minSigned && y == minusone then x
                  else if y == zero then minusone
                  else div x y)
          in setRegister rd q
    | Divu rd rs1 rs2 =>
        x <- getRegister rs1;
        y <- getRegister rs2;
        let q := (if y == zero then maxUnsigned
                  else divu x y)
          in setRegister rd q
    | Rem rd rs1 rs2 =>
        x <- getRegister rs1;
        y <- getRegister rs2;
        let r := (if x == minSigned && y == minusone then zero
                  else if y == zero then x
                  else rem x y)
          in setRegister rd r
    | Remu rd rs1 rs2 =>
        x <- getRegister rs1;
        y <- getRegister rs2;
        let r := (if y == zero then x
                  else remu x y)
          in setRegister rd r
    (* end ast *)
    | _ => mzero
    end.

End Riscv.
