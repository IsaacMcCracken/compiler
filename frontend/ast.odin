package frontend

Token_Index :: u32

Node :: struct {
  tkn_index: Token_Index,
}

Any_Node :: union #shared_nil {
  ^Node,
  ^Function_Decl,
  ^Return_Stmt
}

Any_Decl :: union #shared_nil {
  ^Function_Decl
}

Any_Stmt :: union #shared_nil {
  ^Update_Stmt,
  ^Return_Stmt,
}

Any_Expr :: union #shared_nil {
  ^Binary_Expr,
  ^Literal,
}

Binary_Expr :: struct {
  using node: Node,
  lhs, rhs: Any_Expr
}

Literal :: struct {
  using node: Node
}

Field :: struct {
  using node: Node,
  type: ^Type
}


Block_Stmts :: struct {
  stmts: []Any_Stmt
}

Return_Stmt :: struct {
  using node: Node,
  expr: Any_Expr,
}

Update_Stmt :: struct {
  using node: Node,
  var: Any_Node, // consider if this can be narrowed down
  expr: Any_Expr,
}


Function_Decl :: struct {
  using node: Node, // this has our function name
  params: []Field, // TODO MAKE TYPE SYSTEM
  ret_type: ^Type,
  body: ^Block_Stmts
}


get_node_name :: proc(p: ^Parser, node: Node) -> string {
  tkn := p.tokens[node.tkn_index]
  return string(p.src[tkn.start:tkn.end])
}