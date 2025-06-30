(* I. The Input: Tokens *)
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

(* II. The Output: Abstract Syntax Tree (AST) *)

(* <exp> ::= <integer_literal> *)
type exp = 
    | E_Constant of int
(* <statement> ::= "return" <exp> ";" *)
type statement =
    | S_Return of exp

(* <function> ::= "int" <identifier> "(" [ "void" ] ")" "{" <statement> "}" *)
(* Here [ "void" ] is the notation from EBNF - Extended Backus-Naur Form representing that it is optional*)
type func = {
    name: string;
    body: statement;
}
(* <program> ::= <function> *)
type program =
    | P_PROGRAM of func

(* III. Exceptions *)
exception DeserializationError of string
exception SyntaxError of string

(* IV. Pretty Printer and Main Executable *)
let string_of_exp indent exp =
    let i = String.make indent ' ' in
    match exp with
    | E_Constant n -> 
        i ^ "Constant(" ^ (string_of_int n) ^ ")"

let string_of_statement indent stmt =
    let i = String.make indent ' ' in
    match stmt with
    | S_Return exp ->
        "Return(\n" ^
        (* Makes a recursive call to the other private helper function. *)
        (string_of_exp (indent + 2) exp) ^ "\n" ^
        i ^ ")"

let string_of_program prog =
    match prog with
    | P_PROGRAM func ->
        (* This pattern deconstructs the `P_PROGRAM` to get the `func` record inside. *)
        "Program(\n" ^
        "  Function(\n" ^
        "    name=\"" ^ func.name ^ "\",\n" ^
        "    body=" ^ (string_of_statement 4 func.body) ^ "\n" ^
        "  )\n" ^
        ")"

