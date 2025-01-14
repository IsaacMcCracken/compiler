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
  Left_Paren,
  Right_Paren,
  Left_Brace,
  Right_Brace,

  // most likely math operators
  Plus,
  Minus,
  Star,
  Slash,

  Int,
  Func,
  Arrow,

  // control flow
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

tokenize :: proc(t: ^Tokenizer) {
  scan: for t.curr < u32(len(t.src)) {
    t.prev = t.curr
    ch := t.src[t.curr]
    switch ch {
      case ' ', '\t', '\r':
        t.curr += 1
      case 'a'..='z', 'A'..='Z':
        tokenizer_identier_or_keyword(t)
      case ':':
        t.curr += 1
        append_token(t, .Colon)
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
      case '\n':
        t.curr += 1
        append_token(t, .Newline)
      case '+':
        t.curr += 1 
        append_token(t, .Plus)
      case '-':
        t.curr += 1
        ch = t.src[t.curr]
        if ch == '>' {
          t.curr += 1
          append_token(t, .Arrow)
        } else {
          append_token(t, .Minus)
        }
      case '*':
        t.curr += 1 
        append_token(t, .Star)
      case '/':
        t.curr += 1 
        append_token(t, .Slash)
      case 0:
        break scan
    }

  }
}

tokenizer_identier_or_keyword :: proc(t: ^Tokenizer) {
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