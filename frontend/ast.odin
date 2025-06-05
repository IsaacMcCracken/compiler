/*
  Note whenever making a new stmt or decl make sure to use 
    using stmt: Stmt // when its a statement
    using decl: Decl // when its a declaration
  ALWAYS MAKE SURE IT IS THE FIRsT FIELD!!!!

*/


package frontend

import "base:runtime"

Token_Index :: u32
Float :: f64
Int :: i64


Node :: struct {
  tkn_index: Token_Index,
}

Function_Type_Flags :: bit_set[Function_Type_Flag; u8]
Function_Type_Flag :: enum u8 {
  Extern,
}

Any_Node :: union #shared_nil {
  ^Node,
  ^Function_Type,
  ^Literal
}

Any_Decl :: union #shared_nil {
  ^Function_Type,
  ^Struct_Type,
  ^Enum_Decl,
  ^Global_Var_Decl,
}

Any_Expr :: union #shared_nil {
  ^Binary_Expr,
  ^Literal,
  ^Function_Call,
  ^Pointer_Ref,
  ^Pointer_Deref,
  ^Array_Index,
  ^Type_Conv_Expr,
  ^Dot_Op,
}

Any_Stmt :: union #shared_nil {
  ^Block,
  ^Return_Stmt,
  ^Update_Stmt,
  ^If_Stmt,
  ^Elif_Stmt,
  ^Else_Stmt,
  ^Local_Var_Decl,
  ^For_Range_Less_Stmt,
  ^Function_Call,
}



Pointer_Ref :: struct {
  using node: Node,
  expr: Any_Expr,
}

Pointer_Deref :: struct {
  using node: Node,
  ptr_lit: Literal,
}

Array_Index :: struct {
  using node: Node,
  index: Any_Expr
}

Function_Call :: struct {
  using stmt: Stmt, // contains function call name
  args: Expr_List
}

Binary_Expr :: struct {
  using node: Node,
  lhs, rhs: Any_Expr
}

/* 
  Todo make sure to check errors and have correct conversion
  during semantic analysis
*/
Type_Conv_Expr :: struct {
  using node: Node,
  type: ^Number_Type,
  expr: Any_Expr
}

Expr_List_Node :: struct {
  using node: Node,
  next: ^Expr_List_Node,
  expr: Any_Expr,
}

Named_Expr_List_Node :: struct {
  using node: Node,
  next: ^Named_Expr_List_Node,
  expr: Any_Expr,
}

Named_Expr_List :: struct  {
  head, tail: ^Named_Expr_List_Node,
  count: int
}

Expr_List :: struct {
  head, tail: ^Expr_List_Node,
  count: int
}


Literal :: struct {
  using node: Node,
}

Field :: struct {
  using node: Node,
  next: ^Field,
  type: Type
}

Field_List :: struct {
  head, tail: ^Field,
  count: int
}

Stmt :: struct {
  using node: Node,
  next: Any_Stmt
}

Raw_Any_Stmt :: struct {
  ptr: ^Stmt,
  _type: u64,
}

Block :: struct {
  using stmt: Stmt, 
  head, tail: Any_Stmt, 
}



Return_Stmt :: struct {
  using stmt: Stmt,
  expr: Any_Expr,
}

If_Stmt :: struct {
  using stmt: Stmt,
  condition: Any_Expr,
  body: ^Block, 
}

Elif_Stmt :: struct {
  using if_stmt: If_Stmt
}

Else_Stmt :: struct {
  using stmt: Stmt,
  body: ^Block
}

For_Range_Less_Stmt :: struct {
  using stmt: Stmt,
  counter: ^Literal,
  start_expr: Any_Expr,
  end_expr: Any_Expr,
  body: ^Block
}

Update_Stmt :: struct {
  using stmt: Stmt,
  obj: Any_Expr, 
  expr: Any_Expr
}

Dot_Op :: struct {
  par: ^Literal,
  child: Any_Expr 
}



Local_Var_Decl :: struct {
  using stmt: Stmt,
  type: Type,
  init: Any_Expr,
}


Decl :: struct {
  using node: Node,
  next: Any_Decl
}

Decl_List :: struct {
  head, tail: Any_Decl
}

Raw_Any_Decl :: struct {
  ptr: ^Decl,
  _type: u64,
}

Function_Type :: struct {
  using decl: Decl, // this has our function name
  params: Field_List, 
  ret_type: Type,
  body: ^Block
}

Struct_Type :: struct {
  using decl: Decl,
  fields: Field_List,
}

Enum_Decl :: struct {
  using decl: Decl,
  values: Named_Expr_List,
}

Global_Var_Decl :: struct {
  using decl: Decl,
  type: Type,
  init: Any_Expr,
}



get_node_name :: proc(p: ^Parser, node: Node) -> string {
  tkn := p.tokens[node.tkn_index]
  return string(p.src[tkn.start:tkn.end])
}

get_token_name :: proc(p: ^Parser, index: Token_Index) -> string {
  tkn := p.tokens[index]
  return string(p.src[tkn.start:tkn.end])
}

// Stmt :: struct {
//   using node: Node,
//   next: Any_Stmt
// }

// Block :: struct {
//   using stmt: Stmt, 
//   head, tail: Any_Stmt, 
// }

import "core:fmt"

Stmt_Iterator :: struct {
  stmt: Any_Stmt
}

stmt_iterator_from_block :: proc(block: ^Block) -> Stmt_Iterator {
  return stmt_iterator_from_head(block.head)
}

stmt_iterator_from_head :: proc(head: Any_Stmt) -> Stmt_Iterator {
  return Stmt_Iterator{stmt = head}
}

stmt_iterate_forward :: proc(iter: ^Stmt_Iterator) -> (stmt: Any_Stmt, ok: bool) {
  if iter.stmt == nil {
    return nil, false
  } else {
    result := iter.stmt
    raw := transmute(Raw_Any_Stmt)iter.stmt
    iter.stmt = raw.ptr.next
    return result, true
  }
}


stmt_append :: proc(block: ^Block, stmt: Any_Stmt) {
  if block.tail == nil {
    assert(block.head == nil) 

    block.head = stmt
    block.tail = stmt
  } else {
    old_tail := transmute(Raw_Any_Stmt)block.tail
    old_tail.ptr.next = stmt
    block.tail = stmt

  }
}

Decl_Iterator :: struct {
  decl: Any_Decl
}

decl_iterator_from_list :: proc(decls: ^Decl_List) -> Decl_Iterator {
  return decl_iterator_from_head(decls.head)
}

decl_iterator_from_head :: proc(head: Any_Decl) -> Decl_Iterator {
  return Decl_Iterator{decl = head}
}

decl_iterate_forward :: proc(iter: ^Decl_Iterator) -> (decl: Any_Decl, ok: bool) {
  if iter.decl == nil {
    return nil, false
  } else {
    result := iter.decl
    raw := transmute(Raw_Any_Decl)iter.decl
    iter.decl = raw.ptr.next
    return result, true
  }
}

decl_append :: proc(decls: ^Decl_List, decl: Any_Decl) {
  if decls.tail == nil {
    assert(decls.head == nil) 

    decls.head = decl
    decls.tail = decl
  } else {
    old_tail := transmute(Raw_Any_Decl)decls.tail
    old_tail.ptr.next = decl
    decls.tail = decl
  }
}

Field_Iterator :: struct {
  field: ^Field
}

field_iterator_from_list :: proc(fields: ^Field_List) -> Field_Iterator {
  return field_iterator_from_head(fields.head)
}

field_iterator_from_head :: proc(head: ^Field) -> Field_Iterator {
  return Field_Iterator{field = head}
}

field_iterate_forward :: proc(iter: ^Field_Iterator) -> (field: ^Field, ok: bool) {
  if iter.field == nil {
    return nil, false
  } else {
    result := iter.field
    iter.field = iter.field.next
    return result, true
  }
}

field_append :: proc(fields: ^Field_List, field: ^Field) {
  if fields.tail == nil {
    assert(fields.head == nil) 

    fields.head = field
    fields.tail = field
  } else {
    old_tail := fields.tail
    old_tail.next = field
    fields.tail = field
  }

  fields.count += 1
}


Expr_Iterator :: struct {
  expr: ^Expr_List_Node
}

expr_list_iterator_from_list :: proc(exprs: ^Expr_List) -> Expr_Iterator {
  return expr_iterator_from_head(exprs.head)
}

expr_iterator_from_head :: proc(head: ^Expr_List_Node) -> Expr_Iterator {
  return Expr_Iterator{expr = head}
}

expr_iterate_forward :: proc(iter: ^Expr_Iterator) -> (expr: ^Expr_List_Node, ok: bool) {
  if iter.expr == nil {
    return nil, false
  } else {
    result := iter.expr
    iter.expr = iter.expr.next
    return result, true
  }
}

expr_append :: proc(exprs: ^Expr_List, expr: ^Expr_List_Node) {
  if exprs.tail == nil {
    assert(exprs.head == nil) 

    exprs.head = expr
    exprs.tail = expr
  } else {
    old_tail := exprs.tail
    old_tail.next = expr
    exprs.tail = expr
  }

  exprs.count += 1
}


Named_Expr_Iterator :: struct {
  expr: ^Named_Expr_List_Node
}

named_expr_list_iterator_from_list :: proc(exprs: ^Named_Expr_List) -> Named_Expr_Iterator {
  return named_expr_iterator_from_head(exprs.head)
}

named_expr_iterator_from_head :: proc(head: ^Named_Expr_List_Node) -> Named_Expr_Iterator {
  return Named_Expr_Iterator{expr = head}
}

named_expr_iterate_forward :: proc(iter: ^Named_Expr_Iterator) -> (expr: ^Named_Expr_List_Node, ok: bool) {
  if iter.expr == nil {
    return nil, false
  } else {
    result := iter.expr
    iter.expr = iter.expr.next
    return result, true
  }
}

named_expr_append :: proc(exprs: ^Named_Expr_List, expr: ^Named_Expr_List_Node) {
  if exprs.tail == nil {
    assert(exprs.head == nil) 

    exprs.head = expr
    exprs.tail = expr
  } else {
    old_tail := exprs.tail
    old_tail.next = expr
    exprs.tail = expr
  }

  exprs.count += 1
}
