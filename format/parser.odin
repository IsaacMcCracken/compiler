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
}


Node :: struct {
  token: Index,
  ref: Link,
  next, prev: Link,
  children: Node_List,
  attributes: Node_List
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
  t.prev = t.curr
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

parse_get_node_name :: proc(p: ^Parser, node: Link) -> (str: string) {
  n := get_node(p, node)
  return parse_get_token_name(p, n.token)
}

parse_get_token_name :: proc(p: ^Parser, tok_index: Index) -> (str: string) {
  tok := p.tokens[tok_index]
  return string(p.src[tok.start:tok.end])
}


alloc_new_node :: proc(p: ^Parser, tok_index: Index) -> (n: ^Node, link: Link) {
  link = Index(len(p.nodes))
  append(&p.nodes, Node{token = tok_index})
  return &p.nodes[link], link
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

get_node :: proc(p: ^Parser, link: Link) -> (node: ^Node) {
  if int(link) > len(p.nodes) || link == 0 {
    return nil
  }
  
  return &p.nodes[link]
}

push_node :: proc(p: ^Parser, prev, next: Link) {
  pv := get_node(p, prev)
  nx := get_node(p, next)

  nx.prev = prev
  pv.next = next
}

push_list :: proc(p: ^Parser, list: ^Node_List, new: Link) {
  if list.last != 0 {
    // default case when this list is not empty
    if list.first == 0 {
      fmt.panicf("list: %v new %v", list^, new)
    }

    push_node(p, list.last, new)
    list.last = new
  } else {
    list.first = new
    list.last = new
  }
}

push_child :: proc(p: ^Parser, parent, child: Link) {
  par := get_node(p, parent)
  push_list(p, &par.children, child)
}

parse_nodes :: proc(p: ^Parser) -> (children: Node_List) {
  kind, index := parse_token_current(p)

  for kind == .Identifier || kind == .Tag {
    attributes := parse_attributes(p)
    kind, index = parse_token_current(p)

    
    if kind != .Identifier {
      str := parse_get_token_name(p, index)
      fmt.panicf("why: %v %v, %v", index, kind, str)
    }
    
    node, link  := alloc_new_node(p, index)
    push_list(p, &children, link)
    node.attributes = attributes

    kind, index = parse_token_advance(p)

    if kind == .Scope_Start {
      parse_token_advance(p)
      node.children = parse_nodes(p)
      
      if !parse_expect(p, .Scope_End) {
        fmt.panicf("Where is the scope end")
      } 
    }
  
    
  }

  return children
}

parse_attributes :: proc(p: ^Parser) -> (list: Node_List) {
  // function should enter on the tag and exit if not on tag and return 0 tag ref
  kind, index := parse_token_current(p)
  
  for kind == .Tag {
    kind, index = parse_token_current(p)

    tag, link := alloc_new_node(p, index)
    push_list(p, &list, link)
    
    kind, index = parse_token_advance(p)


    if kind == .Scope_Start {
      kind, index = parse_token_advance(p)
      tag.children = parse_nodes(p)
      if !parse_expect(p, .Scope_End) {
        fmt.panicf("expected to end")
      }
      kind, index = parse_token_advance(p)
    }

  }

  return list
}



parse_file :: proc(p: ^Parser, filename: string) -> (root: ^Node, module: string) {
  t := Tokenizer{}
  tokenizer_init(&t, filename)
  tokenize(&t)

  p.t = t
  p.nodes = make([dynamic]Node, 0, len(t.tokens))
  p.curr = 0

  kind, index := parse_token_current(p)
  name := parse_get_token_name(p, index)
  if kind != .Tag || name != "forest" {
    fmt.panicf("%v", name)
  }

  // start
  kind, index = parse_token_advance(p)
  // version  
  kind, index = parse_token_advance(p)
  // end
  kind, index = parse_token_advance(p)

  // module name
  kind, index = parse_token_advance(p)
  link: Link
  root, link = alloc_new_node(p, index)
  module = parse_get_token_name(p, index)

  _rid := index
  // decls
  kind, index = parse_token_advance(p)
  
  if kind == .Scope_Start {
    kind, index = parse_token_advance(p)
    
    p.nodes[0].children = parse_nodes(p)
    if !parse_expect(p, .Scope_End) {
      // fmt.panicf("no i expected a scope end")
    }
  }
  
  
  return
}


import "core:strings"


main :: proc() {
  p := &Parser{}
  root, name := parse_file(p, "format/sample.tr")

  for tok, i in p.t.tokens {
    if tok.kind == .Identifier || tok.kind == .Tag {
      fmt.println(i, tok.kind, parse_get_token_name(p, Index(i)))
    } else {

      fmt.println(i, tok.kind)
    }
  }

  b := strings.builder_init(&{})
  code := unparse(p, b)

  fmt.println(code)
  // fmt.println(p.nodes)

}