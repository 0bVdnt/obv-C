(* This file defines the PUBLIC API of the Ast module.
   Anything NOT listed here is PRIVATE to ast.ml. *)

type token =
   | T_KW_RETURN
   | T_KW_INT
   | T_KW_VOID
   | T_LPAREN
   | T_RPAREN
   | T_LBRACE
   | T_RBRACE
   | T_SEMICOLON
   | T_IDENTIFIER of string
   | T_CONSTANT of int

(* Exports the types for the nodes of the Abstract Syntax Tree.
   These types directly model the grammar of the language. *)
type exp = 
   | E_Constant of int

type statement =
   | S_Return of exp

type func = {
   name: string;
   body: statement;
}
   
type program =
   | P_PROGRAM of func

exception DeserializationError of string
exception SyntaxError of string

(* Exports the pretty-printer *)
val string_of_program : program -> string

