package frontend

Token_Index :: u32

Node :: struct {
  tkn_index: Token_Index,
}

Any_Node :: union #shared_nil {
  ^Node,
  ^Function_Decl,
  ^Literal
}

Any_Decl :: union #shared_nil {
  ^Function_Decl
}

Any_Expr :: union #shared_nil {
  ^Binary_Expr,
  ^Literal,
}

Any_Stmt :: union #shared_nil {
  ^Block,
  ^Return_Stmt,
  ^Update_Stmt,
  ^If_Stmt,
  ^Var_Decl,
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
  type: ^Primitive_Type
}

Block :: struct {
  using node: Node, 
  stmts: []Any_Stmt 
}

Return_Stmt :: struct {
  using node: Node,
  expr: Any_Expr,
}

If_Stmt :: struct {
  using node: Node,
  condition: Any_Expr,
  body: ^Block,
}

Update_Stmt :: struct {
  using node: Node,
  var: ^Literal, //maybe make this a literal :( idk
  expr: Any_Expr
}


Var_Decl :: struct {
  using node: Node,
  type: ^Primitive_Type,
  init: Any_Expr,
}


Function_Decl :: struct {
  using node: Node, // this has our function name
  params: []Field, 
  ret_type: ^Primitive_Type,
  body: ^Block
}


get_node_name :: proc(p: ^Parser, node: Node) -> string {
  tkn := p.tokens[node.tkn_index]
  return string(p.src[tkn.start:tkn.end])
}