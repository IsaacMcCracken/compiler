package frontend


import "core:strings"
import "core:fmt"


TAB_OR_SPACE :: "  "

@private c_prelude := #load("prelude.c")

to_c_code :: proc(p: ^Parser, b: ^strings.Builder) {
  strings.write_bytes(b, c_prelude)
  iter := decl_iterator_from_list(&p.decls)

  for decl in decl_iterate_forward(&iter) {
    #partial switch kind in decl {
      case ^Function_Decl:
        to_c_function(p, kind, b)
      case ^Struct_Decl:
        to_c_struct(p, kind, b)
      case ^Enum_Decl:
        to_c_enum(p, kind, b)
      case:
        fmt.panicf("NOT SUPPORTED YET")
    }

  }
}

to_c_enum :: proc(p: ^Parser, enum_decl: ^Enum_Decl, b: ^strings.Builder) {

  enum_name := get_node_name(p, enum_decl)

  fmt.sbprintf(b, "typedef int %v;\nenum {{\n", enum_name)

  iter := named_expr_list_iterator_from_list(&enum_decl.values) 

  for named_expr in named_expr_iterate_forward(&iter) {
    value_name := get_node_name(p, named_expr)
    strings.write_string(b, TAB_OR_SPACE)
    fmt.sbprintf(b, "%v_%v", enum_name, value_name)

    if named_expr.expr != nil {
      strings.write_string(b, " = ")
      to_c_expr(p, named_expr.expr, b)
    }

    strings.write_string(b, ",\n")
  }

  strings.write_string(b, "};\n")
}

to_c_struct :: proc(p: ^Parser, struct_decl: ^Struct_Decl, b: ^strings.Builder) {
  struct_name := get_node_name(p, struct_decl)
  fmt.sbprintf(b, "typedef struct %v %v;\n", struct_name, struct_name)
  fmt.sbprintf(b, "struct %v {{\n", struct_name)

  iter := field_iterator_from_list(&struct_decl.fields)
  for field in field_iterate_forward(&iter) {
    strings.write_string(b, TAB_OR_SPACE)
    #partial switch kind in field.type {
      case ^Number_Type:
        to_c_number_type(kind^, b)
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
    case ^Number_Type:
      to_c_number_type(type^, b) 
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
    case ^Pointer_Type:
      base := type.base.(^Number_Type)
      to_c_number_type(base^, b)
      strings.write_string(b, " *")
      name := get_node_name(p, decl)
      strings.write_string(b, name)

      if decl.init == nil {
        strings.write_string(b, " = 0;")
      } else {
        strings.write_string(b, " = ")
        to_c_expr(p, decl.init, b)
        strings.write_string(b, ";\n")

      }

    case ^Array_Type:
      // fix this
      base := type.base.(^Number_Type) // obviously figure out logic for more compounds
      to_c_number_type(base^, b) 
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
      to_c_number_type(type.base.(^Number_Type)^, b)
      strings.write_string(b, " *ptr; unsigned long long len;} ")
      name := get_node_name(p, decl)
      strings.write_string(b, name)
      strings.write_string(b, ";\n")
    case Literal_Type:
      assert(false)
  }
}

to_c_number_type :: proc(type: Number_Type, b: ^strings.Builder) {
  if type.float {
    switch type.size {
      case 2:
        strings.write_string(b, "float")
      case 3:
        strings.write_string(b, "double")
    }
  } else {
    if !type.signed do strings.write_string(b, "u")
    strings.write_string(b, "int")
    strings.write_int(b, 1 << (uint(type.size) + 3))
    strings.write_string(b, "_t")

    
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
    to_c_number_type(fn.ret_type.(^Number_Type)^, b) // fuck it we will fix this later
  }

  strings.write_byte(b, ' ')

  strings.write_string(b, get_node_name(p, fn.node))

  strings.write_byte(b, '(')

  if fn.params.count != 0 {
    iter := field_iterator_from_list(&fn.params)
    counter := 0
    for field in field_iterate_forward(&iter) {
      if field.type != nil {
        to_c_number_type(field.type.(^Number_Type)^, b) // fuck it fix this later
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
      
    case ^Pointer_Deref:
      strings.write_string(b, "(*")
      lit_name := get_node_name(p, kind.ptr_lit)
      strings.write_string(b, lit_name)
      strings.write_byte(b, ')')
    
      case ^Pointer_Ref:
        strings.write_byte(b, '&')
        to_c_expr(p, kind.expr, b)
        // strings.write_string(b, lit_name)

    case ^Array_Index:
      array_type_name := get_node_name(p, kind)
      strings.write_string(b, array_type_name)
      strings.write_byte(b, '[')

      to_c_expr(p, kind.index, b)

      strings.write_byte(b, ']')
    case ^Type_Conv_Expr:
      strings.write_string(b, "((")
      to_c_number_type(kind.type^, b)
      strings.write_byte(b, ')')
      to_c_expr(p, kind.expr, b)
      strings.write_string(b, ")")
  }
}
