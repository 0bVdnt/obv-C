open Assembly_ast

(* --- Private Helper Functions for Formatting --- *)

let format_operand (op: operand) : string =
  match op with
  | A_Imm n ->
      "$" ^ string_of_int n
  | A_Register ->
      "%eax"

let format_instruction (instr: instruction) : string =
  match instr with
  | I_Mov (src, dst) ->
      "    movl " ^ format_operand src ^ ", " ^ format_operand dst
  | I_Ret ->
      "    ret"

(* --- Public API --- *)

let emit_program (p: program) (is_macos: bool) : string =
  match p with
  | P_Program asm_func ->
      let func_name =
        if is_macos then
          "_" ^ asm_func.name
        else
          asm_func.name
      in
      let instruction_strings = List.map format_instruction asm_func.instructions in
      let gnu_stack_note =
        if is_macos then [] (* Return an empty list for macOS. *)
        else [ ".section .note.GNU-stack,\"\",@progbits" ] (* A list with one string for Linux. *)
      in
      let all_lines =
        [ "    .globl " ^ func_name; (* The `.globl` directive makes the function visible to the linker. *)
          func_name ^ ":"             (* The function label, where execution will jump to. *)
        ]
        @ instruction_strings (* Append the list of formatted instruction strings. *)
        @ gnu_stack_note      (* Append the list containing the GNU stack note (which is empty on macOS). *)
      in
      String.concat "\n" all_lines ^ "\n"
