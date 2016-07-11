From lrust Require Export substitution.
From iris.prelude Require Import fin_maps.

(** The tactic [inv_head_step] performs inversion on hypotheses of the
shape [head_step]. The tactic will discharge head-reductions starting
from values, and simplifies hypothesis related to conversions from and
to values, and finite map operations. This tactic is slightly ad-hoc
and tuned for proving our lifting lemmas. *)
Ltac inv_head_step :=
  repeat match goal with
  | _ => progress simplify_map_eq/= (* simplify memory stuff *)
  | H : to_val _ = Some _ |- _ => apply of_to_val in H
  | H : Lit _ = of_val ?v |- _ =>
    apply (f_equal (to_val)) in H; rewrite to_of_val in H;
    injection H; clear H; intro
  | H : context [to_val (of_val _)] |- _ => rewrite to_of_val in H
  | H : head_step ?e _ _ _ _ |- _ =>
     try (is_var e; fail 1); (* inversion yields many goals if [e] is a variable
     and can thus better be avoided. *)
     inversion H; subst; clear H
  end.

(** The tactic [reshape_expr e tac] decomposes the expression [e] into an
evaluation context [K] and a subexpression [e']. It calls the tactic [tac K e']
for each possible decomposition until [tac] succeeds. *)
Ltac reshape_val e tac :=
  let rec go e :=
  match e with
  | of_val ?v => v
  | wexpr' ?e => reshape_val e tac
  | Lit ?l => constr:(LitV l)
  | Rec ?f ?xl ?e => constr:(RecV f xl e)
  end in let v := go e in first [tac v | fail 2].

Ltac reshape_expr e tac :=
  let rec go_fun K f vs es :=
    match es with
    | ?e :: ?es => reshape_val e ltac:(fun v => go_fun K f (v :: vs) es)
    | ?e :: ?es => go (AppRCtx f (reverse vs) es :: K) e
    end
  with go K e :=
  match e with
  | _ => tac (reverse K) e
  | BinOp ?op ?e1 ?e2 =>
     reshape_val e1 ltac:(fun v1 => go (BinOpRCtx op v1 :: K) e2)
  | BinOp ?op ?e1 ?e2 => go (BinOpLCtx op e2 :: K) e1
  | App ?e ?el => reshape_val e ltac:(fun f => go_fun K f (@nil val) el)
  | App ?e ?el => go (AppLCtx el :: K) e
  | Read ?o ?e => go (ReadCtx o :: K) e
  | Write ?o ?e1 ?e2 =>
    reshape_val e1 ltac:(fun v1 => go (WriteRCtx o v1 :: K) e2)
  | Write ?o ?e1 ?e2 => go (WriteLCtx o e2 :: K) e1
  | CAS ?e0 ?e1 ?e2 => reshape_val e0 ltac:(fun v0 => first
     [ reshape_val e1 ltac:(fun v1 => go (CasRCtx v0 v1 :: K) e2)
     | go (CasMCtx v0 e2 :: K) e1 ])
  | CAS ?e0 ?e1 ?e2 => go (CasLCtx e1 e2 :: K) e0
  | Alloc ?e => go (AllocCtx :: K) e
  | Free ?e1 ?e2 => reshape_val e1 ltac:(fun v1 => go (FreeRCtx v1 :: K) e2)
  | Free ?e1 ?e2 => go (FreeLCtx e2 :: K) e1
  | Case ?e ?el => go (CaseCtx el :: K) e
  end in go (@nil ectx_item) e.

(** The tactic [do_head_step tac] solves goals of the shape [head_reducible] and
[head_step] by performing a reduction step and uses [tac] to solve any
side-conditions generated by individual steps. *)
Tactic Notation "do_head_step" tactic3(tac) :=
  try match goal with |- head_reducible _ _ => eexists _, _, _ end;
  simpl;
  match goal with
  | |- head_step ?e1 ?σ1 ?e2 ?σ2 ?ef =>
     first [apply alloc_fresh|econstructor];
       (* solve [to_val] side-conditions *)
       first [rewrite ?to_of_val; reflexivity|simpl_subst; tac; fast_done]
  end.
