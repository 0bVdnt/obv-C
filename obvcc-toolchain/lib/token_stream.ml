(* The two modules needed here are opened. `Ast` for the types (`token`, `DeserializationError`)
   and `Yojson.Basic.Util` for helper functions from the `yojson` library.
   `Yojson.Basic.Util` provides functions like `to_string` and `to_int`
   that extract values from JSON objects. *)
open Ast
open Yojson.Basic.Util

let token_from_json (json: Yojson.Basic.t) : token =
    match json with
    | `String s -> (
        match s with
        | "KwInt" -> T_KW_INT
        | "KwVoid" -> T_KW_VOID
        | "KwReturn" -> T_KW_RETURN
        | "OpenParen" -> T_LPAREN
        | "CloseParen" -> T_RPAREN
        | "OpenBrace" -> T_LBRACE
        | "CloseBrace" -> T_RBRACE
        | "Semicolon" -> T_SEMICOLON
        | other -> 
            raise (DeserializationError ("Unknown string token: " ^ other))
        ) 
    | `Assoc [ (key, value) ] -> (
        match key with
        | "Identifier" -> T_IDENTIFIER (to_string value)
        | "Constant" -> T_CONSTANT (to_int value)
        | other -> raise (DeserializationError ("Unknown object key token: " ^ other))
        )
    | _ ->
        raise
            (DeserializationError
                ("Invalid JSON token format: " ^ Yojson.Basic.to_string json)
            )

(* This is the PUBLIC function promised in the `.mli` file. *)
let token_from_string (s: string) : token list =
    try
        let json = Yojson.Basic.from_string s in
        match json with
        | `Assoc [ ("Success", `List tokens_json) ] ->
            List.map token_from_json tokens_json
        | `Assoc [ ("Error", error_json) ] ->
            let err_str = Yojson.Basic.pretty_to_string error_json in
            raise (DeserializationError ("The lexer reported an error:\n" ^ err_str))
        | _ ->
            let err_str = Yojson.Basic.to_string json in
            raise (DeserializationError ("Expected a 'Success' or 'Error' object, but got:" ^ err_str) )
    with
    | Yojson.Json_error msg -> raise (DeserializationError ("JSON parsing failed: " ^ msg))

