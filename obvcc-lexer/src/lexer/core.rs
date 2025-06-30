use super::error::LexerError;
use super::token::Token;
use lazy_static::lazy_static;
use regex::Regex;

lazy_static! {
    static ref IDENTIFIER_RE: Regex = Regex::new(r"\A[a-zA-Z_]\w*\b").unwrap();
    static ref CONSTANT_RE: Regex = Regex::new(r"\A[0-9]+\b").unwrap();
    static ref OPEN_PAREN_RE: Regex = Regex::new(r"\A\(").unwrap();
    static ref CLOSE_PAREN_RE: Regex = Regex::new(r"\A\)").unwrap();
    static ref OPEN_BRACE_RE: Regex = Regex::new(r"\A\{").unwrap();
    static ref CLOSE_BRACE_RE: Regex = Regex::new(r"\A\}").unwrap();
    static ref SEMICOLON_RE: Regex = Regex::new(r"\A;").unwrap();

    // For skipping these
    static ref WHITESPACE_RE: Regex = Regex::new(r"\A\s+").unwrap();
    static ref SINGLE_LINE_COMMENTS_RE: Regex = Regex::new(r"\A//.*").unwrap();
    static ref MULTI_LINE_COMMENTS_RE: Regex = Regex::new(r"\A(?s)/\*.*?\*/").unwrap();
    // Does not consider nested multiline comments
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
        Lexer { input, position: 0 }
    }

    // Skips whitespaces and comments and return true if skipped any, otherwise false.
    fn skip_whitespaces_and_comments(&mut self) -> bool {
        let mut skipped_something = false;
        loop {
            let current_slice = &self.input[self.position..];
            if current_slice.is_empty() {
                break;
            }
            if let Some(mat) = WHITESPACE_RE.find(current_slice) {
                self.position += mat.end();
                skipped_something = true;
                continue;
            }
            if let Some(mat) = SINGLE_LINE_COMMENTS_RE.find(current_slice) {
                self.position += mat.end();
                skipped_something = true;
                continue;
            }
            if let Some(mat) = MULTI_LINE_COMMENTS_RE.find(current_slice) {
                // TODO: Add a check for unterminated multiline comment
                self.position += mat.end();
                skipped_something = true;
                continue;
            }
            // if nothing was skipped in this iteration break from the loop.
            break;
        }
        skipped_something
    }

    fn next_token_internal(&mut self) -> Option<Result<Token, LexerError>> {
        // Loop to skip whitespaces and comments until a token a found or EOF
        loop {
            let _ = self.skip_whitespaces_and_comments(); // Results ignored, just ensure
                                                          // skipping
            if self.position >= self.input.len() {
                return None;
            }
            // If control reaches here which means that `self.position` points to a
            // potential start of a token, so the control breaks out of the skipping loop
            break;
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
        // If there's still input left at `current_slice` and no token matched,
        // it means there's an unexpected character or sequence.
        if !current_slice.is_empty() {
            if let Some(first_char) = current_slice.chars().next() {
                self.position += first_char.len_utf8();
                return Some(Err(LexerError::UnexpectedCharacter {
                    char: first_char,
                    pos: start_position_of_the_token,
                }));
            }
        }

        // In case of no match
        Some(Err(LexerError::NoMatch {
            pos: start_position_of_the_token,
        }))
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
