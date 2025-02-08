package format_parser

import "core:unicode"
import "core:unicode/utf8"

import "core:os"
import "core:fmt"
import  vmem "core:mem/virtual"

Index   :: u32
Link    :: u32
Tag_Ref :: u32

Location :: struct {
  start, end: Index
}

Token_Kind :: enum u8 {
  Invalid,
  Identifier,
  Tag,
  Scope_Start,
  Scope_End,
}

Token :: struct {
  using loc: Location,
  kind: Token_Kind,
}


Tokenizer :: struct {
  src: []byte,
  tokens: #soa [dynamic]Token,
  curr, prev: Index
}

Parser :: struct {
  module_name: string,
  using t: Tokenizer, 
  nodes: [dynamic]Node,
  tags:  [dynamic]Tag_Node
}

Tag_Node :: struct {
  next, prev: Link,
  using list: Node_List,
  str: Index
}

Node :: struct {
  str: Index,
  parent, ref: Link,
  next, prev: Link,
  children: Node_List,
  tag_list: Tag_Ref
}

Node_List :: struct {
  first, last: Link
}



rune_advance :: proc(t: ^Tokenizer) {
  t.curr += 1
}

rune_current :: proc(t: ^Tokenizer) -> rune {
  return rune(t.src[t.curr])
}

token_append :: proc(t: ^Tokenizer, kind: Token_Kind) {
  append(&t.tokens, Token{start = t.prev, end = t.curr, kind = kind})
}

token_advance_and_append :: proc(t: ^Tokenizer, kind: Token_Kind) {
  rune_advance(t)
  token_append(t, kind)
}

token_produce_identifier :: proc(t: ^Tokenizer) {
  scan: for t.curr < u32(len(t.src)) {
    r := rune_current(t)
    
    switch r {
      case '!','#'..='\'', '*'..='?', 'A'..='~': 
      case: break scan
    }
    rune_advance(t)
  }

  token_append(t, .Identifier)
}

token_produce_captured_identifier :: proc(t: ^Tokenizer) {
  rune_advance(t)
  for t.curr < u32(len(t.src)) {
    r := rune_current(t)
    
    if r == '"' {
      break
    }

    rune_advance(t)
  }

  rune_advance(t)
  token_append(t, .Identifier)
}

token_produce_tag :: proc(t: ^Tokenizer) {
  rune_advance(t)
  for t.curr < u32(len(t.src)) {
    r := rune_current(t)
    
    if !(unicode.is_alpha(r) || unicode.is_digit(r)) {
      break
    }

    rune_advance(t)
  }

  token_append(t, .Tag)
}

tokenize :: proc(t: ^Tokenizer) {
  scan: for t.curr < u32(len(t.src)) {
    t.prev = t.curr
    r := rune_current(t)

    switch r {
      case '\r', ' ', '\t', '\n': rune_advance(t)
      case '(': token_advance_and_append(t, .Scope_Start)
      case ')': token_advance_and_append(t, .Scope_End)
      case '!','#'..='\'', '*'..='?', 'A'..='~': token_produce_identifier(t)
      case '"': token_produce_captured_identifier(t)
      case '@': token_produce_tag(t)
      case: fmt.panicf("Unexpected character: %v", r)
    }
  }
}


tokenizer_init :: proc(t: ^Tokenizer, filename: string, allocator:=context.allocator) -> (ok: bool) {
  context.allocator = allocator
  src, okie_dokie := os.read_entire_file(filename)
  if !okie_dokie do return false
  t.src = src

  
  tokens, alloc_err := make(#soa[dynamic]Token, 0, len(src)/4)
  if alloc_err != .None do return false

  t.tokens = tokens
  t.curr, t.prev = 0, 0

  
  return true
}


alloc_new_node :: proc(p: ^Parser, tok_index: Index) -> (n: ^Node, link: Link) {
  link = Index(len(p.nodes))
  append(&p.nodes, Node{str = tok_index})
  return &p.nodes[link], link
}

alloc_new_tag :: proc(p: ^Parser, tok_index: Index) -> (n: ^Node, ref: Tag_Ref) {
  ref = Tag_Ref(len(p.nodes))
  append(&p.nodes, Node{str = tok_index})
  return &p.nodes[ref], ref
}

parse_token_peek :: proc(p: ^Parser, peek: Index = 1) -> (kind: Token_Kind, index: Index) {
  index = p.curr + peek
  if int(index) < len(p.tokens) {
    kind = p.tokens[index].kind
  }
  kind = .Invalid
  return
}

parse_token_current :: proc(p: ^Parser) -> (kind: Token_Kind, index: Index) {
  index = p.curr
  if int(index) < len(p.tokens) {
    kind = p.tokens[index].kind
  } else {
    kind = .Invalid
    index = 0
  }
  return
}

parse_token_advance :: proc(p: ^Parser) -> (kind: Token_Kind, index: Index) {
  p.curr += 1
  return parse_token_current(p)
}

parse_expect :: proc(p: ^Parser, kind: Token_Kind) -> (ok: bool) {
  k, _ := parse_token_current(p)
  return k == kind
}

parse_get_node :: proc(p: ^Parser, link: Link) -> (node: ^Node) {
  return &p.nodes[link]
}

parse_get_tag :: proc(p: ^Parser, ref: Tag_Ref) -> (tag: ^Tag_Node) {
  return &p.tags[ref]
}

parse_push_tag :: proc(p: ^Parser, prev_ref: Tag_Ref) {
  prev := parse_get_tag(p, prev_ref)
  
}

parse_tags :: proc(p: ^Parser) -> (ref: Tag_Ref) {
  // function should enter on the tag and exit if not on tag and return 0 tag ref
  tok_kind, tok_index := parse_token_current(p)
  
  for tok_kind == .Tag {
    tag, tag_ref := alloc_new_tag(p, tok_index)
    ref = tag_ref
    parse_push_tag(p, parent, tag_ref)

    tok_kind, tok_index = parse_token_advance(p)

    if tok_kind == .Scope_Start {
      
    }

  }

}

parse_children :: proc(p: ^Parser) -> (list: Node_List) {

}

parse_file :: proc(p: ^Parser, t: Tokenizer) -> (ok: bool) {
  p.t = t
  p.nodes = make([dynamic]Node)
  p.tags  = make([dynamic]Tag_Node)
  p.curr = 0

  //stub tag

  // module_name
  if parse_expect(p, .Identifier) {
    file_node, file_node_index := alloc_new_node(p, 0)
    
  } else {
    return false
  }

  parse_node :: proc(p: ^Parser, parent: Link) {

  }

  // parse_tags :: proc(p: ^Parser, parent:)

  return true
}




main :: proc() {
  fmt.println("Node Size", size_of(Node))

  t := &Tokenizer{}
  tokenizer_init(t, "format/sample.tr")

  tokenize(t)

  p := &Parser{}
  parse_file(p, t^)
  alloc_new_node(p, 5)


  for tok in t.tokens {
    fmt.println(tok.kind)
  }
}