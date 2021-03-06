Require Import Coq.ZArith.ZArith.
Require Import riscv.Utility.Tactics.

Local Open Scope Z_scope.

(* Credits: Mostly copied from fiat-crypto *)

Ltac div_mod_to_quot_rem_inequality_solver := omega.

Ltac generalize_div_eucl x y :=
  let H := fresh in
  let H' := fresh in
  assert (H' : y <> 0) by div_mod_to_quot_rem_inequality_solver;
  generalize (Z.div_mod x y H'); clear H';
  first [ assert (H' : 0 < y) by div_mod_to_quot_rem_inequality_solver;
          generalize (Z.mod_pos_bound x y H'); clear H'
        | assert (H' : y < 0) by div_mod_to_quot_rem_inequality_solver;
          generalize (Z.mod_neg_bound x y H'); clear H'
        | assert (H' : y < 0 \/ 0 < y) by (apply Z.neg_pos_cases; div_mod_to_quot_rem_inequality_solver);
          let H'' := fresh in
          assert (H'' : y < x mod y <= 0 \/ 0 <= x mod y < y)
            by (destruct H'; [ left; apply Z.mod_neg_bound; assumption
                             | right; apply Z.mod_pos_bound; assumption ]);
          clear H'; revert H'' ];
  let q := fresh "q" in
  let r := fresh "r" in
  set (q := x / y) in *;
  set (r := x mod y) in *;
  clearbody q r.

Ltac div_mod_to_quot_rem_step :=
  so fun hyporgoal => match hyporgoal with
  | context[?x / ?y] => generalize_div_eucl x y
  | context[?x mod ?y] => generalize_div_eucl x y
  end.

Ltac div_mod_to_quot_rem := repeat div_mod_to_quot_rem_step; intros.
