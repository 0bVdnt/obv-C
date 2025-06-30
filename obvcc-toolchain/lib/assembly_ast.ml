(** The type for operands in assembly instructions. *)
type operand =
  | A_Imm of int
  | A_Register

(** The type for the different kinds of assembly instructions that can be generated. *)
type instruction =
  | I_Mov of operand * operand
  | I_Ret

(** The type for a function definition in assembly. *)
type func = {
  name: string;
  instructions: instruction list;
}

(** The type for the top-level assembly program structure. *)
type program =
  | P_Program of func
