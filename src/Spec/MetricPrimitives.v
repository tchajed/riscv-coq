Require Import Coq.Lists.List.
Require Import Coq.ZArith.BinInt.
Require Import coqutil.Map.Interface.
Require Import riscv.Utility.Monads.
Require Import riscv.Utility.Utility.
Require Import riscv.Spec.Decode.
Require Import riscv.Platform.Memory.
Require Import riscv.Spec.Machine.
Require Import riscv.Platform.MetricRiscvMachine.
Require Import riscv.Utility.MkMachineWidth.
Require Import riscv.Platform.MetricLogging.
Require Import riscv.Spec.Primitives.

Section MetricPrimitives.

  Context {W: Words}.
  Context {Registers: map.map Register word}.
  Context {Action: Type}.
  Context {mem: map.map word byte}.

  Local Notation RiscvMachineL := (MetricRiscvMachine Register Action).

  Context {M: Type -> Type}.
  Context {MM: Monad M}.
  Context {RVM: RiscvProgram M word}.
  Context {RVS: @RiscvMachine M word _ _ RVM}.

  Definition spec_load{p: PrimitivesParams M RiscvMachineL}(V: Type)
             (riscv_load: SourceType -> word -> M V)
             (mem_load: mem -> word -> option V)
             (nonmem_load: RiscvMachineL -> word -> (V  -> RiscvMachineL -> Prop) -> Prop)
             : Prop :=
    forall initialL addr (kind: SourceType) (post: V -> RiscvMachineL -> Prop),
        let initialLMetrics := updateMetrics (addMetricLoads 1) initialL in
        (exists v: V, mem_load initialL.(getMem) addr = Some v /\ post v initialLMetrics) \/
        (mem_load initialL.(getMem) addr = None /\ nonmem_load initialL addr post) <->
        mcomp_sat (riscv_load kind addr) initialL post.

  Definition spec_store{p: PrimitivesParams M RiscvMachineL}(V: Type)
             (riscv_store: SourceType -> word -> V -> M unit)
             (mem_store: mem -> word -> V -> option mem)
             (nonmem_store: RiscvMachineL -> word -> V -> (RiscvMachineL -> Prop) -> Prop)
             : Prop :=
    forall initialL addr v (kind: SourceType) (post: unit -> RiscvMachineL -> Prop),
      let initialLMetrics := updateMetrics (addMetricStores 1) initialL in
      (exists m', mem_store initialL.(getMem) addr v = Some m' /\ post tt (withMem m' initialLMetrics)) \/
      (mem_store initialL.(getMem) addr v = None /\ nonmem_store initialL addr v (post tt)) <->
      mcomp_sat (riscv_store kind addr v) initialL post.

  (* primitives_params is a paramater rather than a field because Primitives lives in Prop and
     is opaque, but the fields of primitives_params need to be visible *)
  Class MetricPrimitives(primitives_params: PrimitivesParams M RiscvMachineL): Prop := {

    spec_Bind{A B: Type}: forall (initialL: RiscvMachineL) (post: B -> RiscvMachineL -> Prop)
                                 (m: M A) (f : A -> M B),
        (exists mid: A -> RiscvMachineL -> Prop,
            mcomp_sat m initialL mid /\
            (forall a middle, mid a middle -> mcomp_sat (f a) middle post)) <->
        mcomp_sat (Bind m f) initialL post;

    spec_Return{A: Type}: forall (initialL: RiscvMachineL)
                                 (post: A -> RiscvMachineL -> Prop) (a: A),
        post a initialL <->
        mcomp_sat (Return a) initialL post;

    spec_getRegister: forall (initialL: RiscvMachineL) (x: Register)
                             (post: word -> RiscvMachineL -> Prop),
        (valid_register x /\
         match map.get initialL.(getRegs) x with
         | Some v => post v initialL
         | None => forall v, is_initial_register_value v -> post v initialL
         end) \/
        (x = Register0 /\ post (word.of_Z 0) initialL) <->
        mcomp_sat (getRegister x) initialL post;

    spec_setRegister: forall initialL x v (post: unit -> RiscvMachineL -> Prop),
      (valid_register x /\ post tt (withRegs (map.put initialL.(getRegs) x v) initialL) \/
       x = Register0 /\ post tt initialL) <->
      mcomp_sat (setRegister x v) initialL post;

    spec_loadByte: spec_load w8 (Machine.loadByte (RiscvProgram := RVM))
                                Memory.loadByte
                                nonmem_loadByte_sat;

    spec_loadHalf: spec_load w16 (Machine.loadHalf (RiscvProgram := RVM))
                                 Memory.loadHalf
                                 nonmem_loadHalf_sat;

    spec_loadWord: spec_load w32 (Machine.loadWord (RiscvProgram := RVM))
                                 Memory.loadWord
                                 nonmem_loadWord_sat;

    spec_loadDouble: spec_load w64 (Machine.loadDouble (RiscvProgram := RVM))
                                   Memory.loadDouble
                                   nonmem_loadDouble_sat;

    spec_storeByte: spec_store w8 (Machine.storeByte (RiscvProgram := RVM))
                                  Memory.storeByte
                                  nonmem_storeByte_sat;

    spec_storeHalf: spec_store w16 (Machine.storeHalf (RiscvProgram := RVM))
                                    Memory.storeHalf
                                    nonmem_storeHalf_sat;

    spec_storeWord: spec_store w32 (Machine.storeWord (RiscvProgram := RVM))
                                    Memory.storeWord
                                    nonmem_storeWord_sat;

    spec_storeDouble: spec_store w64 (Machine.storeDouble (RiscvProgram := RVM))
                                     Memory.storeDouble
                                     nonmem_storeDouble_sat;

    spec_getPC: forall initialL (post: word -> RiscvMachineL -> Prop),
        post initialL.(getPc) initialL <->
        mcomp_sat getPC initialL post;

    spec_setPC: forall initialL v (post: unit -> RiscvMachineL -> Prop),
        post tt (withNextPc v
                (updateMetrics (addMetricJumps 1)
                               initialL)) <->
        mcomp_sat (setPC v) initialL post;

    spec_step: forall initialL (post: unit -> RiscvMachineL -> Prop),
        post tt (withNextPc (word.add initialL.(getNextPc) (word.of_Z 4))
                (withPc     initialL.(getNextPc)
                (updateMetrics (addMetricInstructions 1)
                               initialL))) <->
        mcomp_sat step initialL post;
  }.

End MetricPrimitives.
