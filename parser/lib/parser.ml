(* Open the `Ast` module to get access to all the types (`token`, `exp`, `SyntaxError`, etc.)
   and the type constructors (`T_KW_INT`, `E_Constant`, etc.). *)
open Ast

(* --- I. Private Helper Functions --- *)
let string_of_token = function
    | T_KW_INT -> "'int'" 
    | T_KW_VOID -> "'void'"
    | T_KW_RETURN -> "'return'"
    | T_LPAREN -> "'('"
    | T_RPAREN -> "')'"
    | T_LBRACE -> "'{'"
    | T_RBRACE -> "'}'"
    | T_SEMICOLON -> "';'"
    | T_IDENTIFIER s -> "identifier '" ^ s ^ "'"
    | T_CONSTANT i -> "constant '" ^ string_of_int i ^ "'"

let take_token (tokens : token list) : token * (token list) = 
    match tokens with
    | [] -> raise (SyntaxError "Unexpected end of file. Expected more tokens.")
    | hd :: tl -> (hd, tl)

(* This is a core utility of the parser. It enforces the grammar rules. *)
let expect (expected : token) (tokens : token list) : token list =
    (* Here helper function is being used to get the next token and the remaining list. *)
    let (actual, rest) = take_token tokens in
    (* The `actual` token is compared with the `expected` one. The `token` type can be
       compared with `=` because it is a variant type. *)
    if actual = expected then
        rest (* Success: return the list of remaining tokens. *)
    else
        (* Failure: construct a helpful error message and raise the `SyntaxError` exception. *)
        let msg = "Expected " ^ (string_of_token expected) ^ " but found " ^ (string_of_token actual) in
        raise (SyntaxError msg)

(* --- II. The Recursive Descent Parsing Functions (Private) --- *)
(* Each function here corresponds to a non-terminal symbol in the grammar. *)

(* parse_exp
   Grammar: <exp> ::= <constant>
   Consumes a constant token and returns an 'exp' AST node.
*)
let rec parse_exp tokens =
    let token, rest_of_tokens = take_token tokens in
    match token with
        | T_CONSTANT i -> (E_Constant i, rest_of_tokens)
        | other ->
            let msg = "Expected a constant expression but found " ^ string_of_token other in
            raise (SyntaxError msg)

(* parse_statement
   Grammar: <statement> ::= "return" <exp> ";"
   Consumes a return statement and returns a 'statement' AST node.
*)
and parse_statement tokens =
    let tokens_after_return = expect T_KW_RETURN tokens in
    (* Another parsing function, `parse_exp`, is called to handle the <exp> non-terminal. *)
    let exp_node, tokens_after_exp = parse_exp tokens_after_return in
    let tokens_after_semicolon = expect T_SEMICOLON tokens_after_exp in
    (* Construt the `S_Return` AST node, wrapping the `exp_node` obtained from `parse_exp`. *)
    (S_Return exp_node, tokens_after_semicolon)

(* parse_function
   Grammar:<function> ::= "int" <identifier> "(" [ "void" ] ")" "{" <statement> "}" 
   Consumes a full function definition and returns a 'func' AST node.
*)
and parse_function tokens =
    let tokens = expect T_KW_INT tokens in
    let (func_name, tokens) =
        let (token, rest) = take_token tokens in
        match token with 
        | T_IDENTIFIER s -> (s, rest)
        | other -> 
            let msg = "Expected an identifier for function name, but found " ^ string_of_token other in
            raise (SyntaxError msg)
    in
    let tokens = expect T_LPAREN tokens in
    (* Check for the OPTIONAL 'void' keyword. *)
    let tokens =
        (* This is a "peek" operation. Looking at the next token without consuming it.
           Deconstruct the result of `take_token` but immediately ignore the tail (`_`). *)
        let (next_token, _) = take_token tokens in
        if next_token = T_KW_VOID then
            expect T_KW_VOID tokens (* If `void` is present consume it using expect. *)
        else
            tokens (* Otherwise, do nothing and proceed. *)
    in
    let tokens = expect T_RPAREN tokens in
    let tokens = expect T_LBRACE tokens in
    let (body_node, tokens) = parse_statement tokens in
    let tokens = expect T_RBRACE tokens in
    let func_node = { name = func_name; body = body_node } in
    (func_node, tokens)

(* parse_program
   Grammar: <program> ::= <function>
   This is the top-level entry point for parsing. It consumes an entire
   token stream and returns a single 'program' AST node.
*)
let parse_program (tokens : token list) : program =
    let (func_node, remaining_tokens) = parse_function tokens in
    
    match remaining_tokens with
    | [] ->
        P_PROGRAM func_node
    | hd :: _ ->
        let msg = "Expected end of file but found unexpected token: " ^ (string_of_token hd) in
        raise(SyntaxError msg)

