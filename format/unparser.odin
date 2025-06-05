package format_parser

import "core:strings"
import "core:fmt"

Node_Iterator :: struct {
  n: ^Node,
  p: ^Parser,
}

node_iterator_from_head :: proc(p: ^Parser, head: Link) -> (iter: Node_Iterator) {
  if head == 0 do return 
  iter.n = &p.nodes[head]
  iter.p = p
  return 
}

node_iterator_from_list :: proc(p: ^Parser, list: Node_List) -> (iter: Node_Iterator) {
  return node_iterator_from_head(p, list.first)
}

node_iterate_forward :: proc(iter: ^Node_Iterator) -> (n: ^Node, ok: bool) {
  n = iter.n

  if n == nil do return nil, false

  if n.next == 0 do iter.n = nil
  else do iter.n = &iter.p.nodes[n.next]

  return n, true
}

node_has_children :: proc(node: ^Node) -> (ok: bool) {
  if node.children.last == 0 {
    assert(node.children.first == 0)
    return false
  }

  return true
} 

unparse :: proc(p: ^Parser, b: ^strings.Builder) -> (code: string) {
  unparse_node :: proc(p: ^Parser, n: ^Node, b: ^strings.Builder, is_attribute := false) {
    iter := node_iterator_from_list(p, n.attributes)

    if is_attribute do strings.write_string(b, parse_get_token_name(p, n.token))

    for tag in node_iterate_forward(&iter) {
      strings.write_byte(b, '@')
      unparse_node(p, tag, b, true)
      strings.write_byte(b, ' ')
    }


    if !is_attribute do strings.write_string(b, parse_get_token_name(p, n.token))

    iter = node_iterator_from_list(p, n.children)
    if node_has_children(n) {
      strings.write_byte(b, '(')
      
      for child in node_iterate_forward(&iter) {
        unparse_node(p, child, b)
        if !(child.next == 0) do strings.write_byte(b, ' ')
      }

      strings.write_byte(b, ')')
    }


    
  }


  strings.write_string(b, "@forest(0.1) program (\n")

  n := &p.nodes[0]
  iter := node_iterator_from_list(p, n.children)

  // fmt.println("root:", n^)
  for child in node_iterate_forward(&iter) {
    strings.write_byte(b, '\t')
    unparse_node(p, child, b)
  }

  strings.write_string(b, "\n)")



  return strings.to_string(b^)
}