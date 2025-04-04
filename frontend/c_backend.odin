package frontend


import "core:strings"
import "core:fmt"


TAB_OR_SPACE :: "  "

to_c_code :: proc(p: ^Parser, b: ^strings.Builder) {

  iter := decl_iterator_from_list(&p.decls)

  for decl in decl_iterate_forward(&iter) {
    #partial switch kind in decl {
      case ^Function_Decl:
        to_c_function(p, kind, b)
      case ^Struct_Decl:
        to_c_struct(p, kind, b)
      case:
        fmt.panicf("NOT SUPPORTED YET")
    }

  }
}

to_c_struct :: proc(p: ^Parser, struct_decl: ^Struct_Decl, b: ^strings.Builder) {
  struct_name := get_node_name(p, struct_decl)
  fmt.sbprintf(b, "typedef struct %v %v;\n", struct_name, struct_name)
  fmt.sbprintf(b, "struct %v {{\n", struct_name)

  iter := field_iterator_from_list(&struct_decl.fields)
  for field in field_iterate_forward(&iter) {
    strings.write_string(b, TAB_OR_SPACE)
    #partial switch kind in field.type {
      case ^Primitive_Type:
        to_c_primitive_type(kind^, b)
      case ^Slice_Type:
        
    }
    strings.write_byte(b, ' ')
    field_name := get_node_name(p, field)
    fmt.sbprintf(b, "%v;\n", field_name)
  }

  strings.write_string(b, "};\n")

}

to_c_local_var_decl :: proc(p: ^Parser, decl: ^Local_Var_Decl, b: ^strings.Builder) {
  switch type in decl.type {
    case ^Primitive_Type:
      to_c_primitive_type(type^, b) 
      strings.write_byte(b, ' ')
      name := get_node_name(p, decl)
      strings.write_string(b, name)
      
      if decl.init != nil {
        strings.write_string(b, " = ")
        to_c_expr(p, decl.init, b)
      } else {
        strings.write_string(b, " = 0")
      }
      strings.write_string(b, ";\n")
    case ^Array_Type:
      // fix this
      base := type.base.(^Primitive_Type) // obviously figure out logic for more compounds
      to_c_primitive_type(base^, b) 
      strings.write_byte(b, ' ')
      name := get_node_name(p, decl)
      strings.write_string(b, name)
      strings.write_byte(b, '[')
      strings.write_int(b, int(type.len))
      strings.write_byte(b, ']')

      assert(decl.init == nil) // we will see this later
      strings.write_string(b, " = {0}")
      strings.write_string(b, ";\n")
    case ^Slice_Type:
      // declaration
      /*
        struct { base *ptr, unsigned long long len } var_name;
      */
      strings.write_string(b, "struct {")
      to_c_primitive_type(type.base.(^Primitive_Type)^, b)
      strings.write_string(b, " *ptr; unsigned long long len;} ")
      name := get_node_name(p, decl)
      strings.write_string(b, name)
      strings.write_string(b, ";\n")
    case Literal_Type:
      assert(false)
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

to_c_operator :: proc(p: ^Parser, op: ^Binary_Expr, b: ^strings.Builder) {
  tok := p.tokens[op.tkn_index]

  #partial switch tok.kind {
    case .Logical_And:
      strings.write_string(b, "&&")
    case .Logical_Or:
      strings.write_string(b, "||")
    case:
      strings.write_string(b, string(p.src[tok.start:tok.end]))
  }
}


to_c_function :: proc(p: ^Parser, fn: ^Function_Decl, b: ^strings.Builder) {
  if fn.ret_type == nil {
    strings.write_string(b, "void")
  } else {
    to_c_primitive_type(fn.ret_type.(^Primitive_Type)^, b) // fuck it we will fix this later
  }

  strings.write_byte(b, ' ')

  strings.write_string(b, get_node_name(p, fn.node))

  strings.write_byte(b, '(')

  if fn.params.count != 0 {
    iter := field_iterator_from_list(&fn.params)
    counter := 0
    for field in field_iterate_forward(&iter) {
      if field.type != nil {
        to_c_primitive_type(field.type.(^Primitive_Type)^, b) // fuck it fix this later
      }
  
      strings.write_byte(b, ' ')
      strings.write_string(b, get_node_name(p, field.node))
  
      if counter != fn.params.count - 1 {
        strings.write_string(b, ", ")
      }
  
      counter += 1
    }
  } else {
    strings.write_string(b, "void")
  }

  strings.write_string(b, " )\n")


  if fn.body != nil {
    to_c_stmt(p, fn.body, b)
  }

}

to_c_block :: proc(p: ^Parser, block: ^Block, b: ^strings.Builder, level := 0) {
  for i in 0..<level do strings.write_string(b, TAB_OR_SPACE)
  strings.write_string(b, "{\n")
  // to do turn into linked list
  iter := stmt_iterator_from_block(block)
  for stmt in stmt_iterate_forward(&iter) {
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
    case ^Local_Var_Decl:
      to_c_local_var_decl(p, kind, b)
    case ^For_Range_Less_Stmt:
      strings.write_string(b, "for ( long long ")
      counter_name := get_node_name(p, kind.counter)
      strings.write_string(b, counter_name)
      strings.write_string(b, " = ")
      to_c_expr(p, kind.start_expr, b)
      strings.write_string(b, "; ")
      strings.write_string(b, counter_name)
      strings.write_string(b, " < ")
      to_c_expr(p, kind.end_expr, b)
      strings.write_string(b, "; ")
      strings.write_string(b, counter_name)
      strings.write_string(b, "++)\n")
      to_c_block(p, kind.body, b, level)
    case ^Array_Index_Update_Stmt:
      array_type_name := get_node_name(p, kind.array_index)
      strings.write_string(b, array_type_name)
      strings.write_byte(b, '[')

      to_c_expr(p, kind.array_index.index, b)

      strings.write_string(b, "] ")

      updater_string := get_node_name(p, kind)
      strings.write_string(b, updater_string)
      strings.write_byte(b, ' ')

      
      to_c_expr(p, kind.expr, b)

      strings.write_string(b, ";\n");
    case ^Function_Call:
      to_c_function_call(p, kind, b)
      strings.write_string(b, ";\n");

  }
}

to_c_function_call :: proc(p: ^Parser, call: ^Function_Call, b: ^strings.Builder) {
  fn_name := get_node_name(p, call)
  strings.write_string(b, fn_name)

  strings.write_byte(b, '(')

  iter := expr_list_iterator_from_list(&call.args)
  counter := 0
  for expr in expr_iterate_forward(&iter) {
    to_c_expr(p, expr.expr, b)

    if counter != call.args.count - 1 do strings.write_byte(b, ',')

    counter += 1
  }

  strings.write_byte(b, ')') 
}

to_c_expr :: proc(p: ^Parser, expr: Any_Expr, b: ^strings.Builder) {
  switch kind in expr {
    case ^Binary_Expr:
      to_c_expr(p, kind.lhs, b)
      strings.write_byte(b, ' ')

      // make the binary operator a c-type
      to_c_operator(p, kind, b)
      strings.write_byte(b, ' ')
      to_c_expr(p, kind.rhs, b)
    case ^Literal:
      strings.write_string(b, get_node_name(p, kind))
    case ^Function_Call:
      to_c_function_call(p, kind, b)
    case ^Array_Index:
      array_type_name := get_node_name(p, kind)
      strings.write_string(b, array_type_name)
      strings.write_byte(b, '[')

      to_c_expr(p, kind.index, b)

      strings.write_byte(b, ']')
    case ^Type_Conv_Expr:
      strings.write_string(b, "((")
      to_c_primitive_type(kind.type^, b)
      strings.write_byte(b, ')')
      to_c_expr(p, kind.expr, b)
      strings.write_string(b, ")")
  }
}
