package frontend


import "core:strings"
import "core:fmt"


TAB_OR_SPACE :: "  "

@private vector_op_string_map := #partial [Token_Kind]string {
  .Plus = "add",
  .Minus = "sub",
  .Star = "mul",
  .Slash = "div",
  .Plus_Equals = "add",
  .Minus_Equals = "sub",
  .Times_Equals = "mul",
  .Slash_Equals = "div",
  .Equals = "cpy",
}

@private c_prelude := #load("prelude.c")

to_c_code :: proc(p: ^Parser, b: ^strings.Builder) {
  strings.write_bytes(b, c_prelude)
  iter := decl_iterator_from_list(&p.decls)

  for decl in decl_iterate_forward(&iter) {
    #partial switch kind in decl {
      case ^Function_Type:
        to_c_function(p, kind, b)
      case ^Struct_Type:
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

to_c_struct :: proc(p: ^Parser, s: ^Struct_Type, b: ^strings.Builder) {
  struct_name := get_node_name(p, s)
  // fmt.sbprintf(b, "typedef struct %v %v;\n", struct_name, struct_name)
  fmt.sbprintf(b, "struct %v {{\n", struct_name)

  iter := field_iterator_from_list(&s.fields)
  for field in field_iterate_forward(&iter) {
    strings.write_string(b, TAB_OR_SPACE)
    field_name := get_node_name(p, field)
    to_c_local_or_field_type(p, field.type, field_name, b)
    strings.write_string(b, ";\n")
  }

  strings.write_string(b, "};\n")

}
to_c_type :: proc(p: ^Parser, type: Type, b: ^strings.Builder) {
  #partial switch kind in type {
      case ^Number_Type:
        to_c_number_type(kind^, b)
        strings.write_byte(b, ' ')
      case ^Struct_Type:
        struct_name := get_node_name(p, kind)
        fmt.sbprintf(b, "struct %v ", struct_name)
      case ^Pointer_Type:
        n := 1
        base := kind.base
        ptr, ok := base.(^Pointer_Type)
        for ok {
          n += 1
          base = ptr.base
          ptr, ok = base.(^Pointer_Type)
        }
      to_c_type(p, base, b)
      strings.write_byte(b, ' ')
      for i in 0..<n {
        strings.write_byte(b, '*')
      }
      case ^Array_Type:
        base := kind.base.(^Number_Type)
  }
}

to_c_local_or_field_type :: proc(p: ^Parser, type: Type, obj_name: string, b: ^strings.Builder) {
  #partial switch kind in type {
      case ^Array_Type:
        n := kind.len
        base := kind.base
        arr, ok := base.(^Array_Type) 
        for ok {
          n *= arr.len
          base = arr.base
          arr, ok = base.(^Array_Type)
        }
        
        to_c_type(p, base, b)
        
        fmt.sbprintf(b, "%v[%d]", obj_name, n)
      case:
        to_c_type(p, type, b)
        strings.write_string(b, obj_name)
    }
}

to_c_local_var_decl :: proc(p: ^Parser, decl: ^Local_Var_Decl, b: ^strings.Builder, indent := 0) {
  assert(decl.type != nil)
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
      to_c_type(p, type, b)

      if decl.init == nil {
        strings.write_string(b, " = 0;")
      } else {
        strings.write_string(b, " = ")
        to_c_expr(p, decl.init, b)
        strings.write_string(b, ";\n")

      }

    case ^Array_Type:
      // fix this

      name := get_node_name(p, decl)

      to_c_local_or_field_type(p, decl.type, name, b)

      if decl.init == nil {
        strings.write_string(b, " = {0};\n")
      } else {
        strings.write_string(b, ";\n")
        to_c_vector_stmt(p, decl, b, indent)
      }
    case ^Slice_Type:
      // declaration
      /*
        struct { base *ptr, unsigned long long len } var_name;
      */

      // TODO(make there be a prelude type buffer so that we can make good type stuff)
      strings.write_string(b, "struct {")
      to_c_number_type(type.base.(^Number_Type)^, b)
      strings.write_string(b, " *ptr; unsigned long long len;} ")
      name := get_node_name(p, decl)
      strings.write_string(b, name)
      strings.write_string(b, ";\n")
    case ^Struct_Type:
      var_name := get_node_name(p, decl)
      to_c_local_or_field_type(p, type, var_name, b)

      if decl.init == nil {
        strings.write_string(b, " = { 0 }")
      } else {
        strings.write_string(b, " = ")
        to_c_expr(p, decl.init, b)
      }
      strings.write_string(b, ";\n")

    case Literal_Type:
      assert(false)
    case ^Function_Type:
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


to_c_function :: proc(p: ^Parser, fn: ^Function_Type, b: ^strings.Builder) {
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
      #partial switch type in kind.type {
        case ^Array_Type:
          to_c_vector_stmt(p, kind, b, level)
        case:
          to_c_expr(p, kind.obj, b)
          
          updater := get_node_name(p, kind)
          strings.write_byte(b, ' ')
          strings.write_string(b, updater)
          strings.write_byte(b, ' ')
    
          to_c_expr(p, kind.expr, b)
          strings.write_string(b, ";\n")
      }
    case ^If_Stmt:
      strings.write_string(b, "if ( ")
      to_c_expr(p, kind.condition, b)
      strings.write_string(b, " )\n")
      to_c_block(p, kind.body, b, level)
    case ^Elif_Stmt:
      strings.write_string(b, "else if ( ")
      to_c_expr(p, kind.condition, b)
      strings.write_string(b, " )\n")
      to_c_block(p, kind.body, b, level)
    case ^Else_Stmt:
      strings.write_string(b, "else\n")
      to_c_block(p, kind.body, b, level)
    case ^Local_Var_Decl:
      to_c_local_var_decl(p, kind, b, level)
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

to_c_vector_stmt :: proc(p: ^Parser, stmt: Any_Stmt, b: ^strings.Builder, indent: int) {
  #partial switch kind in stmt {
    case ^Local_Var_Decl:
      for i in 0..<indent do strings.write_string(b, TAB_OR_SPACE)
      // Start Expression
      strings.write_string(b, "{\n")

      local_name := get_node_name(p, kind)
      to_c_vector_expr(p, kind.init, kind.type.(^Array_Type), local_name, b, indent + 1)

      
      for i in 0..<indent do strings.write_string(b, TAB_OR_SPACE)
      strings.write_string(b, "}\n")
      // End Expression

    case ^Update_Stmt:
      strings.write_byte(b, '\n')
      for i in 0..<indent do strings.write_string(b, TAB_OR_SPACE)
      // Start Expression
      strings.write_string(b, "{\n")
      arr_type := kind.type.(^Array_Type)
      base_name := get_type_string(p, arr_type.base)
      tok := get_token(p, kind.tkn_index)

      TEMP_VECTOR_STRING :: "___temp_vector___"
      obj_str := get_expr_string(p, kind.obj)
      for i in 0..<indent + 1 do strings.write_string(b, TAB_OR_SPACE)
      #partial switch op in kind.expr {
        case ^Binary_Expr:

          
          #partial switch tok.kind {
            case .Plus_Equals, .Minus_Equals, .Times_Equals, .Slash_Equals:
              to_c_local_or_field_type(p, arr_type, TEMP_VECTOR_STRING, b)
              strings.write_string(b, ";\n")
              to_c_vector_expr(p, kind.expr, arr_type, TEMP_VECTOR_STRING, b, indent + 1)
              for i in 0..<indent + 1 do strings.write_string(b, TAB_OR_SPACE)
    
              fmt.sbprintf(
                b,
                "__%s_vector_%s__(%s, %s, %s, %d);\n",
                base_name,
                vector_op_string_map[tok.kind],
                obj_str,
                TEMP_VECTOR_STRING,
                obj_str,
                arr_type.len,
              )
            case .Equals:
              to_c_vector_expr(p, kind.expr, arr_type, obj_str, b, indent + 1)
          }
        case: 
          rhs_str := get_expr_string(p, kind.expr)
          #partial switch tok.kind {
            case .Plus_Equals, .Minus_Equals, .Times_Equals, .Slash_Equals:
              fmt.sbprintf(
                b,
                "__%s_vector_%s__(%s, %s, %s, %d);\n",
                base_name,
                vector_op_string_map[tok.kind],
                obj_str,
                rhs_str,
                obj_str,
                arr_type.len,
              )
            case .Equals:
              fmt.sbprintf(
                b,
                "__%s_vector_cpy__(%s, %s, %d);\n",
                base_name,
                obj_str,
                rhs_str,
                arr_type.len
              )
          }
      }
      
    
      for i in 0..<indent do strings.write_string(b, TAB_OR_SPACE)
      strings.write_string(b, "}\n")
      // End Expression

  }
}

to_c_vector_expr :: proc(
  p: ^Parser,
  expr: Any_Expr,
  arr_type: ^Array_Type,
  out_str: string,
  b: ^strings.Builder,
  indent: int,
  n := 0
  ) {

  #partial switch kind in expr {
    case ^Binary_Expr:
      lhs_string, rhs_string: string

      #partial switch lhs in kind.lhs  {
        case ^Binary_Expr:
          // declare lhs vector
          for i in 0..<indent do strings.write_string(b, TAB_OR_SPACE)
          lhs_string = fmt.tprintf("___%s_lhs_temp_vector_%d___", get_type_string(p, arr_type.base), n)
          to_c_local_or_field_type(p, arr_type, lhs_string, b)
          strings.write_string(b, ";\n")
        case:
          lhs_string = get_expr_string(p, lhs)
      }
      to_c_vector_expr(p, kind.lhs, arr_type, lhs_string, b, indent, n + 1)

      #partial switch rhs in kind.rhs  {
        case ^Binary_Expr:
          // declare lhs vector
          for i in 0..<indent do strings.write_string(b, TAB_OR_SPACE)
          rhs_string = fmt.tprintf("___%s_rhs_temp_vector_%d___", get_type_string(p, arr_type.base), n)
          to_c_local_or_field_type(p, arr_type, rhs_string, b)
          strings.write_string(b, ";\n")
        case:
          rhs_string = get_expr_string(p, rhs)
      }
      to_c_vector_expr(p, kind.rhs, arr_type, rhs_string, b, indent, n + 1)



      tok := get_token(p, kind.tkn_index)
      op_str := vector_op_string_map[tok.kind]
      base := arr_type.base.(^Number_Type)
      base_type_name := get_type_string(p, base)

      for i in 0..<indent do strings.write_string(b, TAB_OR_SPACE)
      fmt.sbprintf(
        b, 
        "__%s_vector_%s__(%s, %s, %s, %d);\n",
        base_type_name,
        op_str, lhs_string,
        rhs_string,
        out_str,
        arr_type.len
      )
  }
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
    case ^Dot_Op:
      to_c_expr(p, kind.par, b)
      strings.write_byte(b, '.')
      to_c_expr(p, kind.child, b)
  }
}
