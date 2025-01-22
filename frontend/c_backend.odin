package frontend


import "core:strings"
import "core:fmt"


TAB_OR_SPACE :: "  "

to_c_code :: proc(p: ^Parser, node: Any_Node, b: ^strings.Builder) {
  #partial switch n in node {
    case ^Function_Decl:
      to_c_function(p, n, b)
    case:
      fmt.panicf("NOT SUPPORTED YET")
  }
}

to_c_primitive_type :: proc(type: Primitive_Type, b: ^strings.Builder) {
  switch kind in type {
    case Float_Type:
      switch kind.size {
        case 2:
          strings.write_string(b, "float")
        case 3:
          strings.write_string(b, "double")
        case:
          fmt.panicf("unknown float type with size %v", kind.size)
      }
    case Integer_Type:
      if kind.signed == false {
        strings.write_string(b, "unsigned ")
      }

      switch kind.size {
        case 0: strings.write_string(b, "char")
        case 1: strings.write_string(b, "short")
        case 2: strings.write_string(b, "int")
        case 3: strings.write_string(b, "long long")
      }
  }
}


to_c_function :: proc(p: ^Parser, fn: ^Function_Decl, b: ^strings.Builder) {
  if fn.ret_type == nil {
    strings.write_string(b, "void")
  } else {
    to_c_primitive_type(fn.ret_type^, b)
  }

  strings.write_byte(b, ' ')

  strings.write_string(b, get_node_name(p, fn.node))

  strings.write_byte(b, '(')
  strings.write_byte(b, ' ')


  for field, index in fn.params {
    if field.type != nil {
      to_c_primitive_type(field.type^, b)
    }

    strings.write_byte(b, ' ')
    strings.write_string(b, get_node_name(p, field.node))

    if index != len(fn.params) - 1 {
      strings.write_string(b, ", ")
    }
  }

  strings.write_string(b, " ) ")


  if fn.body != nil {
    to_c_stmt(p, fn.body, b)
  }

}

to_c_block :: proc(p: ^Parser, block: ^Block, b: ^strings.Builder, level := 0) {
  for i in 0..<level do strings.write_string(b, TAB_OR_SPACE)
  strings.write_string(b, "{\n")
  for stmt in block.stmts {
    to_c_stmt(p, stmt, b, level + 1)
  }
  for i in 0..<level do strings.write_string(b, TAB_OR_SPACE)
  strings.write_string(b, "}\n")

}

to_c_stmt :: proc(p: ^Parser, stmt: Any_Stmt, b: ^strings.Builder, level := 0) {
  for i in 0..<level do strings.write_string(b, TAB_OR_SPACE)
  switch kind in stmt {
    case ^Block:
      to_c_block(p, kind, b, level)
    case ^Return_Stmt:
      strings.write_string(b, "return ")
      
      to_c_expr(p, kind.expr, b)
      strings.write_string(b, ";\n")
    case ^Update_Stmt:
      var_name := get_node_name(p, kind.var)
      strings.write_string(b, var_name)
      strings.write_byte(b, ' ')

      updater := get_node_name(p, kind)
      strings.write_string(b, updater)
      strings.write_byte(b, ' ')

      to_c_expr(p, kind.expr, b)
      strings.write_string(b, ";\n")
    case ^If_Stmt:
      strings.write_string(b, "if ( ")
      to_c_expr(p, kind.condition, b)
      strings.write_string(b, " )\n")
      to_c_block(p, kind.body, b, level)
    case ^Var_Decl:
      to_c_primitive_type(kind.type^, b)
      strings.write_byte(b, ' ')
      name := get_node_name(p, kind)
      strings.write_string(b, name)
      
      if kind.init != nil {
        strings.write_string(b, " = ")
        to_c_expr(p, kind.init, b)
      } else {
        strings.write_string(b, " = 0")
      }
      strings.write_string(b, ";\n")
  }
}

to_c_expr :: proc(p: ^Parser, expr: Any_Expr, b: ^strings.Builder) {
  switch kind in expr {
    case ^Binary_Expr:
      to_c_expr(p, kind.lhs, b)
      strings.write_byte(b, ' ')
      tkn := p.tokens[kind.tkn_index]
      strings.write_string(b, string(p.src[tkn.start:tkn.end]))
      strings.write_byte(b, ' ')
      to_c_expr(p, kind.rhs, b)

    case ^Literal:
      tkn := p.tokens[kind.tkn_index]
      strings.write_string(b, string(p.src[tkn.start:tkn.end]))
  }
}
