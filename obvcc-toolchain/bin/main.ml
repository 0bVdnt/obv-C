open Obvcc_toolchain_lib

let is_macos () =
  try
    let ic = Unix.open_process_in "uname -s" in
    let uname = input_line ic in
    let _ = Unix.close_process_in ic in
    String.trim uname = "Darwin"
  with
  | _ -> false

let () =
  try
    (* I. Determine Input Source and Output Filename *)
    let input_channel, input_name, output_base_name =
      if Array.length Sys.argv > 1 then
        let filename = Sys.argv.(1) in
        (open_in filename, filename, Filename.remove_extension filename)
      else
        (stdin, "stdin", "a")
    in

    Printf.eprintf "Compiling from %s...\n" input_name;

    (* II. Read and Deserialize Tokens *)
    let json_string = In_channel.input_all input_channel in
    if input_channel <> stdin then close_in input_channel;
    let tokens = Token_stream.token_from_string json_string in

    (* III. Run the Parser *)
    let c_ast = Parser.parse_program tokens in

    (* IV. Generate Assembly AST *)
    let assembly_ast = Assembly_generator.generate_program c_ast in

    (* V. Emit Assembly Code *)
    let assembly_code = Code_emitter.emit_program assembly_ast (is_macos ()) in

    (* VI. Write Output to File *)
    let output_filename = output_base_name ^ ".s" in
    Out_channel.with_open_text output_filename (fun oc ->
      Out_channel.output_string oc assembly_code
    );

    Printf.eprintf "Generated assembly to %s\n" output_filename;
    exit 0

  (* VII. Handle Errors *)
  with
  | Ast.DeserializationError msg ->
      Printf.eprintf "[ERROR] Failed to read tokens: %s\n" msg;
      exit 1
  | Ast.SyntaxError msg ->
      Printf.eprintf "[ERROR] Syntax error: %s\n" msg;
      exit 1
  | e ->
      Printf.eprintf "[ERROR] An unknown error occurred: %s\n" (Printexc.to_string e);
      exit 1
