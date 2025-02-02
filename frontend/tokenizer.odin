package frontend

import "core:mem"
import "core:unicode"
// square :: func(x: int) -> int
Token_Kind :: enum u32 {
  Invalid,
  Identifier,

  Colon,
  Comma,
  Newline,

  Left_Bracket,
  Right_Bracket,

  Left_Paren,
  Right_Paren,

  Left_Brace,
  Right_Brace,
  
  // most likely math operators
  Plus,
  Minus,
  Star,
  Slash,


  // Logical Operators
  Logical_Not,
  Logical_Or, // and
  Logical_And, // or
  Logical_Equals, // ==
  Logical_Not_Equals, // !=
  Less_Than, // a < b
  Greater_Than, // a > b
  Less_Than_Equal, // a <= b
  Greater_Than_Equal, // a >= b

  // updaters
  Plus_Equals,
  Minus_Equals,
  Times_Equals,
  Slash_Equals,
  Equals,


  Number, // there is more here

  // primitive types
  Int,
  Uint,
  S8,
  S16,
  S32,
  S64,
  U8,
  U16,
  U32,
  U64,

  Float,
  F32,
  F64,

  Func,
  Arrow,

  // control flow
  If,
  For,
  In,
  Dot,
  Range_Less,
  Return,
}


Token :: struct {
  kind: Token_Kind,
  start, end: u32
}

Tokenizer :: struct {
  filename: string,
  src: []byte,
  tokens: [dynamic]Token,
  curr, prev: u32,
}

tokenizer_init :: proc(t: ^Tokenizer, filename: string, src: []byte) {
  t.filename = filename
  t.src = src
  t.tokens, _ = make([dynamic]Token)
}

tokenizer_number :: proc(t: ^Tokenizer) {
  for t.curr < u32(len(t.src)) && unicode.is_digit(rune(t.src[t.curr])) {
    t.curr += 1
  }

  append_token(t, .Number)
}

tokenize :: proc(t: ^Tokenizer) {
  scan: for t.curr < u32(len(t.src)) {
    t.prev = t.curr
    ch := t.src[t.curr]
    switch ch {
      case ' ', '\t', '\r':
        t.curr += 1
      case 'a'..='z', 'A'..='Z':
        tokenizer_identifier_or_keyword(t)
      
      case '0'..='9':
        tokenizer_number(t)
      case ':':
        t.curr += 1
        append_token(t, .Colon)
      case '.':
        t.curr += 1
        ch = t.src[t.curr]
        if ch == '.' {
          t.curr += 1
          ch = t.src[t.curr]
          if ch == '<' {
            t.curr += 1
            append_token(t, .Range_Less)
          } else {
            // error
            panic("illegal token")
          }
        } else {
          append_token(t, .Dot)
        }
      case ',':
        t.curr += 1
        append_token(t, .Comma)
      case '(':
        t.curr += 1
        append_token(t, .Left_Paren)
      case ')':
        t.curr += 1
        append_token(t, .Right_Paren)
      case '{':
        t.curr += 1
        append_token(t, .Left_Brace)
      case '}':
        t.curr += 1
        append_token(t, .Right_Brace)
      case '[':
        t.curr += 1
        append_token(t, .Left_Bracket)
      case ']':
        t.curr += 1
        append_token(t, .Right_Bracket)
      case '\n':
        t.curr += 1
        append_token(t, .Newline)
      case '<':
        t.curr += 1
        ch := t.src[t.curr] 
        if ch == '=' {
          t.curr += 1
          append_token(t, .Less_Than_Equal)
        } else {
          append_token(t, .Less_Than)
        }
      case '>':
        t.curr += 1
        ch := t.src[t.curr] 
        if ch == '=' {
          t.curr += 1
          append_token(t, .Greater_Than_Equal)
        } else {
          append_token(t, .Greater_Than)
        }
      case '!':
        t.curr += 1
        ch := t.src[t.curr]
        if ch == '=' {
          t.curr += 1
          append_token(t, .Logical_Not_Equals)
        } else {
          append_token(t, .Logical_Not)
        }
      case '=':
        t.curr += 1
        ch := t.src[t.curr]
        if ch == '=' {
          t.curr += 1
          append_token(t, .Logical_Equals)
        } else {
          append_token(t, .Equals)
        }
      case '+':
        t.curr += 1 
        ch = t.src[t.curr]
        if ch == '=' {
          t.curr += 1
          append_token(t, .Plus_Equals)
        } else {
          append_token(t, .Plus)
        }      
      case '-':
        t.curr += 1
        ch = t.src[t.curr]
        if ch == '>' {
          t.curr += 1
          append_token(t, .Arrow)
        } else if ch == '=' {
          t.curr += 1
          append_token(t, .Minus_Equals)
        } else {
          append_token(t, .Minus)
        }
      case '*':
        t.curr += 1 
        ch = t.src[t.curr]
        if ch == '=' {
          t.curr += 1
          append_token(t, .Times_Equals)
        } else {
          append_token(t, .Star)
        }
      case '/':
        t.curr += 1 
        ch = t.src[t.curr]
        if ch == '=' {
          t.curr += 1
          append_token(t, .Slash_Equals)
        } else {
          append_token(t, .Slash)
        }
      case 0:
        break scan
    }

  }
}

tokenizer_identifier_or_keyword :: proc(t: ^Tokenizer) {
  for t.curr < u32(len(t.src)) && (unicode.is_alpha(rune(t.src[t.curr])) || unicode.is_number(rune(t.src[t.curr]))) {
    t.curr += 1
  }

  kind, ok := tmap[string(t.src[t.prev:t.curr])]
  if ok {
    append_token(t, kind)
    return
  }

  append_token(t, .Identifier)
}

append_token :: proc(t: ^Tokenizer, kind: Token_Kind) {
  append(&t.tokens, Token{start = t.prev, end = t.curr, kind = kind})
}