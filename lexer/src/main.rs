mod lexer;
use lexer::{Lexer, LexerError, Token};
use serde::Serialize;
use serde_json;
use std::{
    env, fs,
    io::{self, Write},
};

// Compiler Output Structure
#[derive(Serialize)]
#[serde(untagged)]
enum CompilerOutput {
    Success(Vec<Token>),
    Error(LexerError),
}

fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();

    let source_code = if args.len() > 1 {
        let file_path = &args[1];
        fs::read_to_string(file_path)?
    } else {
        eprintln!("No source file provided. Use default example code.");
        "int main () { return 0; }".to_string()
    };
    eprintln!("--- Source Code ---");
    eprintln!("{}", source_code);
    eprintln!("-------------------");

    let mut lexer_instance = Lexer::new(&source_code);
    let output = match lexer_instance.tokenize_all() {
        Ok(tokens) => CompilerOutput::Success(tokens),
        Err(e) => CompilerOutput::Error(e),
    };

    match serde_json::to_string_pretty(&output) {
        Ok(json_string) => {
            println!("{}", json_string);
        }
        Err(e) => {
            let error_msg = format!(
                "Internal Error: Failed to serialize lexer output to JSON: {}",
                e
            );
            io::stderr().write_all(error_msg.as_bytes())?;
            io::stderr().write_all(b"\n")?;
            std::process::exit(1);
        }
    }

    if let CompilerOutput::Error(_) = output {
        std::process::exit(1);
    }

    Ok(())
}
