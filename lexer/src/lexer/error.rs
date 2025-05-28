use serde::Serialize;
use std::fmt;

#[derive(Debug, PartialEq, Serialize)]
pub enum LexerError {
    #[serde(rename = "unexpected_character")]
    UnexpectedCharacter { char: char, pos: usize },
    #[serde(rename = "invalid_integer")]
    InvalidInteger { value: String, pos: usize },
    #[serde(rename = "no_match")]
    NoMatch { pos: usize },
}

impl fmt::Display for LexerError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            LexerError::UnexpectedCharacter { char, pos } => {
                write!(f, "Unexpected character '{}' at position {}", char, pos)
            }

            LexerError::InvalidInteger { value, pos } => write!(
                f,
                "Invalid integer constant '{}' at position {}",
                value, pos
            ),

            LexerError::NoMatch { pos } => write!(f, "No token matched at position {}", pos),
        }
    }
}

impl std::error::Error for LexerError {}
