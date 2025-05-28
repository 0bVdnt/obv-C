use serde::Serialize;

#[derive(Serialize)]
pub enum Token {
    // Keywords
    KwInt,
    KwVoid,
    KwReturn,

    // Identifiers (ex. main, foo, bar, return)
    Identifier(String),
    
    // Constant (Holds 32-bit integer values)
    Constant(i32),

    // Symbols
    CloseParen,
    OpenParen,
    CloseBrace,
    OpenBrace,
    Semicolon,
}
