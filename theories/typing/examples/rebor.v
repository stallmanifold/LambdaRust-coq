From iris.proofmode Require Export tactics.
From lrust.typing Require Import typing.
Set Default Proof Using "Type".

Section rebor.
  Context `{typeG Σ}.

  Definition rebor : val :=
    funrec: <> ["t1"; "t2"] :=
       Newlft;;
       letalloc: "x" <- "t1" in
       let: "x'" := !"x" in let: "y" := "x'" +ₗ #0 in
       "x" <- "t2";;
       let: "y'" := !"y" in
       letalloc: "r" <- "y'" in
       Endlft ;; delete [ #2; "t1"] ;; delete [ #2; "t2"] ;;
                 delete [ #1; "x"] ;; "return" ["r"].

  Lemma rebor_type :
    typed_instruction_ty [] [] [] rebor
        (fn([]; Π[int; int], Π[int; int]) → int).
  Proof.
    iApply type_fn; [solve_typing..|]. simpl. iIntros ([] ret p). inv_vec p=>t1 t2. simpl_subst.
    iApply (type_newlft []). iIntros (α).
    iApply (type_letalloc_1 (&uniq{α}Π[int; int])); [solve_typing..|]. iIntros (x). simpl_subst.
    iApply type_deref; [solve_typing|apply read_own_move|done|]. iIntros (x'). simpl_subst.
    iApply (type_letpath (&uniq{α}int)); [solve_typing|]. iIntros (y). simpl_subst.
    iApply (type_assign _ (&uniq{α}Π [int; int])); [solve_typing|by apply write_own|].
    iApply type_deref; [solve_typing|apply: read_uniq; solve_typing|done|]. iIntros (y'). simpl_subst.
    iApply type_letalloc_1; [solve_typing..|]. iIntros (r). simpl_subst.
    iApply type_endlft.
    iApply type_delete; [solve_typing..|].
    iApply type_delete; [solve_typing..|].
    iApply type_delete; [solve_typing..|].
    iApply (type_jump [_]); solve_typing.
  Qed.
End rebor.
