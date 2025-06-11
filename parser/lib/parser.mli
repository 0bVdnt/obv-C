(* Ast types are required *)
open Ast 

(** [parse_program tokens] consumes a list of tokens and returns a complete
    program AST.
    @raise Ast.SyntaxError if the token stream does not conform to the language grammar.
*)
val parse_program : token list -> program

