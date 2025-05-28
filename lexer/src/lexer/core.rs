use regex::Regex;
use lazy_static::lazy_static;
use super::token::Token;
use super::error::LexerError;

lazy_static! {
    static ref IDENTIFIER_RE: Regex = Regex::new(r"\A[a-zA-Z_]\w*\b").unwrap();
    static ref CONSTANT_RE: Regex = Regex::new(r"\A[0-9]+\b").unwrap();
    static ref OPEN_PAREN_RE: Regex = Regex::new(r"\A\(").unwrap();
    static ref CLOSE_PAREN_RE: Regex = Regex::new(r"\A\)").unwrap();
    static ref OPEN_BRACE_RE: Regex = Regex::new(r"\A\{").unwrap();
    static ref CLOSE_BRACE_RE: Regex = Regex::new(r"\A\}").unwrap();
    static ref SEMICOLON_RE: Regex = Regex::new(r"\A;").unwrap();
    static ref WHITESPACE_RE: Regex = Regex::new(r"\A\s+").unwrap();
}

const KEYWORDS: [(&str, Token); 3] = [
    ("int", Token::KwInt),
    ("void", Token::KwVoid),
    ("return", Token::KwReturn),
];

pub struct Lexer<'a> {
    input: &'a str,
    position: usize,
}

impl<'a> Lexer<'a> {
    pub fn new(input: &'a str) -> Self {
        Lexer {input, position: 0}
    }

    fn skip_whitespaces(&mut self) {
        let current_slice = &self.input[self.position..];
        if let Some(mat) = WHITESPACE_RE.find(current_slice) {
            self.position += mat.end();
        }
    }

    fn next_token_internal(&mut self) -> Option<Result<Token, LexerError>> {
        self.skip_whitespaces();
        if self.position >= self.input.len() {
            return None;
        }

        let current_slice = &self.input[self.position..];
        let start_position_of_the_token = self.position;

        // Match punctuation
        
        if let Some(mat) = OPEN_PAREN_RE.find(current_slice) {
            self.position += mat.end();
            return Some(Ok(Token::OpenParen));
        }

        if let Some(mat) = CLOSE_PAREN_RE.find(current_slice) {
            self.position += mat.end();
            return Some(Ok(Token::CloseParen));
        }

        if let Some(mat) = OPEN_BRACE_RE.find(current_slice) {
            self.position += mat.end();
            return Some(Ok(Token::OpenBrace));
        }

        if let Some(mat) = CLOSE_BRACE_RE.find(current_slice) {
            self.position += mat.end();
            return Some(Ok(Token::CloseBrace));
        }

        if let Some(mat) = SEMICOLON_RE.find(current_slice) {
            self.position += mat.end();
            return Some(Ok(Token::Semicolon));
        }

        // Match Identifiers (and then check for keywords)
        if let Some(mat) = IDENTIFIER_RE.find(current_slice) {
            let val = mat.as_str();
            self.position += mat.end();
            for (keyword_str, token_variant) in KEYWORDS.iter() {
                if *keyword_str == val {
                    return Some(Ok(token_variant.clone()));
                }
            }
            return Some(Ok(Token::Identifier(val.to_string())));
        }

        // Match Integer Constants
        if let Some(mat) = CONSTANT_RE.find(current_slice) {
            let val_str = mat.as_str();
            self.position += mat.end();
            match val_str.parse::<i32>() {
                Ok(val) => return Some(Ok(Token::Constant(val))),
                Err(_) => {
                    return Some(Err(LexerError::InvalidInteger {
                        value: val_str.to_string(),
                        pos: start_position_of_the_token,
                    }));
                }
            }
        }

        // In case of no match
        Some(Err(LexerError::NoMatch { pos: start_position_of_the_token }))
    }

    pub fn tokenize_all(&mut self) -> Result<Vec<Token>, LexerError> {
        let mut tokens = Vec::new();
        while let Some(token_result) = self.next_token_internal() {
            match token_result {
                Ok(token) => tokens.push(token),
                Err(e) => return Err(e),
            }
        }
        Ok(tokens)
    }
}
