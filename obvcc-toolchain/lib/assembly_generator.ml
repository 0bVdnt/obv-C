open Ast
open Assembly_ast

(* --- Private Helper Functions for AST Traversal --- *)

let generate_exp (e: Ast.exp) : Assembly_ast.operand =
  match e with
  | E_Constant n -> A_Imm n

let generate_statement (s: Ast.statement) : Assembly_ast.instruction list =
  match s with
  | S_Return e ->
      let source_operand = generate_exp e in
      [ I_Mov (source_operand, A_Register); (* movl $val, %eax *)
        I_Ret ]                             (* ret *)

(* --- Public API --- *)

let generate_program (p: Ast.program) : Assembly_ast.program =
  match p with
  | P_PROGRAM c_func ->
      let instructions = generate_statement c_func.body in
      let asm_func = { name = c_func.name; instructions = instructions } in
      P_Program asm_func
