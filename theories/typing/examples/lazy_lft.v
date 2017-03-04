From iris.proofmode Require Import tactics.
From lrust.typing Require Import typing.
Set Default Proof Using "Type".

Section lazy_lft.
  Context `{typeG Σ}.

  Definition lazy_lft : val :=
    funrec: <> [] :=
      Newlft;;
      let: "t" := new [ #2] in let: "f" := new [ #1] in let: "g" := new [ #1] in
      let: "42" := #42 in "f" <- "42";;
      "t" +ₗ #0 <- "f";; "t" +ₗ #1 <- "f";;
      let: "t0'" := !("t" +ₗ #0) in "t0'";;
      let: "23" := #23 in "g" <- "23";;
      "t" +ₗ #1 <- "g";;
      let: "r" := new [ #0] in
      Endlft;; delete [ #2; "t"];; delete [ #1; "f"];; delete [ #1; "g"];; "return" ["r"].

  Lemma lazy_lft_type :
    typed_val lazy_lft (fn([]) → unit).
  Proof.
    intros. iApply type_fn; [solve_typing..|]. iIntros "/= !#". iIntros ([] ret p).
      inv_vec p. simpl_subst.
    iApply (type_newlft []). iIntros (α).
    iApply (type_new_subtype (Π[uninit 1;uninit 1])); [solve_typing..|].
      iIntros (t). simpl_subst.
    iApply type_new; [solve_typing|]. iIntros (f). simpl_subst.
    iApply type_new; [solve_typing|]. iIntros (g). simpl_subst.
    iApply type_int. iIntros (v42). simpl_subst.
    iApply type_assign; [solve_typing|by eapply write_own|].
    (* FIXME somehow this fails nowadays if we don't give the own_ptr hints. *)
    iApply (type_assign (own_ptr _ _) (&shr{α} _)); [solve_typing..|by eapply write_own|].
    iApply (type_assign (own_ptr _ _)); [solve_typing|by eapply write_own|].
    iApply type_deref; [solve_typing|apply: read_own_copy|done|]. iIntros (t0'). simpl_subst.
    iApply type_letpath; [solve_typing|]. iIntros (dummy). simpl_subst.
    iApply type_int. iIntros (v23). simpl_subst.
    iApply type_assign; [solve_typing|by eapply write_own|].
    iApply (type_assign _ (&shr{α} int)); [solve_typing..|by eapply write_own|].
    iApply type_new; [solve_typing..|]. iIntros (r). simpl_subst.
    iApply type_endlft; [solve_typing..|].
    iApply (type_delete (Π[&shr{_}_;&shr{_}_])%T).
    { (* FIXME how on earth has this ever worked? It's also really slow even now. *)
      eapply tctx_extract_merge_own_prod; first done. solve_typing. }
    { solve_typing. } { solve_typing. }
    iApply type_delete; [solve_typing..|].
    iApply type_delete; [solve_typing..|].
    iApply (type_jump [_]); solve_typing.
  Qed.
End lazy_lft.
