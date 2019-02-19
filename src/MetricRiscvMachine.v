Require Import coqutil.Map.Interface.
Require Import coqutil.Word.Interface.
Require Import coqutil.Word.LittleEndian.
Require Import riscv.Memory.
Require Import riscv.Utility.
Require Import riscv.RiscvMachine.
Require Import riscv.MetricLogging.

Section Machine.

  Context {Reg: Type}.
  Context {W: Words}.
  Context {Registers: map.map Reg word}.
  Context {Mem: map.map word byte}.
  Context {Action: Type}.

  Local Notation RiscvMachineL := (RiscvMachine Reg Action).

  Record MetricRiscvMachine := mkMetricRiscvMachine {
    getMachine :> RiscvMachineL;
    getMetrics: MetricLog;
  }.

  Definition withMetrics : MetricLog -> MetricRiscvMachine -> MetricRiscvMachine :=
    fun metrics '(mkMetricRiscvMachine m _) =>
                  mkMetricRiscvMachine m metrics.

  Definition updateMetrics(fm: MetricLog -> MetricLog)(m: MetricRiscvMachine) :=
    withMetrics (fm m.(getMetrics)) m.
  
  Definition liftGet{A: Type}(getF: RiscvMachineL -> A): (MetricRiscvMachine -> A) :=
    fun m => getF m.

  Definition getRegs := liftGet getRegs.
  Definition getPc := liftGet getPc.
  Definition getNextPc := liftGet getNextPc.
  Definition getMem := liftGet getMem.
  Definition getLog := liftGet getLog.

  Definition liftWith{A: Type}(withF: A -> RiscvMachineL -> RiscvMachineL) :=
    fun a m =>
      mkMetricRiscvMachine (withF a m.(getMachine)) m.(getMetrics).

  Definition withRegs := liftWith withRegs.
  Definition withPc := liftWith withPc.
  Definition withNextPc := liftWith withNextPc.
  Definition withMem := liftWith withMem.
  Definition withLog := liftWith withLog.
  Definition withLogItem := liftWith withLogItem.
  Definition withLogItems := liftWith withLogItems.
  
End Machine.

Arguments MetricRiscvMachine Reg {W} {Registers} {Mem} Action.