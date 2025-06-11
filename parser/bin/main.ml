(* Makes all the public modules INSIDE the library (`Ast`, `Parser`, `Token_stream`)
   directly available in this file. *)
open Obv_parser_lib 

let () =
    try
        (* I. Read from stdin *)
        let input_json = In_channel.input_all stdin in
        
        (* II. Deserialize the JSON *)
        let tokens = Token_stream.token_from_string input_json in

        (* III. Run the parser *)
        let ast = Parser.parse_program tokens in

        (* IV. Print the result *)
        print_endline (Ast.string_of_program ast)

    (* V. Handle errors *)
    with
    | Ast.DeserializationError msg ->
        Printf.eprintf "[PARSER ERROR] Failed to read tokens: %s\n" msg;
        exit 1
    | Ast.SyntaxError msg ->
        Printf.eprintf "[PARSER ERROR] Syntax error: %s\n" msg;
        exit 1
    | e ->
        Printf.eprintf "[PARSER ERROR] An unknown error occurred: %s\n" (Printexc.to_string e);
        exit 1

