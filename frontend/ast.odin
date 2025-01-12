package frontend

Token_Index :: u32



Any_Node :: union #shared_nil {
  ^Node,
  ^Function_Decl,
}

Any_Decl :: union #shared_nil {
  ^Function_Decl
}

Node :: struct {
  tkn_index: Token_Index,
}



Field :: struct {
  using node: Node,
  type: ^Type
}// 2^0 = 1, 2^1 = 1, 2^2 = 4, 2^3 = 8,    

Function_Decl :: struct {
  using node: Node, // this has our function name
  params: []Field, // TODO MAKE TYPE SYSTEM
  ret_type: ^Type,
}


get_node_name :: proc(p: ^Parser, node: Node) -> string {
  tkn := p.tokens[node.tkn_index]
  return string(p.src[tkn.start:tkn.end])
}