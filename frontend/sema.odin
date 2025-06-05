package frontend


import ll "core:container/intrusive/list"
import "core:odin/ast"
import "base:runtime"
import "core:math"
import "core:fmt"
import "core:mem"


/*
  What We need to do

  we need a array of types 
  and a hash map of identifier based types to 

  Resolve implicit variable type declarations

  Check types

  after ast generation we gotta make a types ast tree
  ambiguous declarations are put in a registry to 
  check how to resolve that declaration


  function() -> not true
*/

error :: default_error_handler
warning :: default_warning_handler

Unresolved_Node :: struct {
  using link: ll.Node,
  decl: Any_Decl,
  type: Type,
}



Sema :: struct {
  // unresolved: ll.List,
  lookup: map[string]Type,
  items: [dynamic]Scope_Item,
  gpa: runtime.Allocator,
  literal_pool: mem.Dynamic_Pool

}

Scope_Item :: struct {
  name: string,
  type: Type,
}

get_expr_string :: proc(p: ^Parser, expr: Any_Expr) -> string {
  recurse :: proc(p: ^Parser, expr: Any_Expr) -> (min, max: u32) {
    switch kind in expr {
      case ^Array_Index:
        tok := get_token(p, kind.tkn_index)
        min = tok.start
        index_min, index_max := recurse(p, kind.index) 
        max = index_max + 1
      case ^Binary_Expr:
        lhs_min, lhs_max := recurse(p, kind.lhs)
        rhs_min, rhs_max := recurse(p, kind.rhs)
        min = math.min(lhs_min, rhs_min)
        max = math.max(lhs_max, rhs_max)
      case ^Literal:
        tok := get_token(p, kind.tkn_index)
        min, max = tok.start, tok.end
      case ^Pointer_Ref:
        tok := get_token(p, kind.tkn_index)
        min = tok.start
        _, max = recurse(p, kind.expr)
      case ^Function_Call:
        tok := get_token(p, kind.tkn_index)
        min = tok.start
        if kind.args.count > 0 {
          tok = get_token(p, kind.args.tail.tkn_index)
          _, max = recurse(p, kind.args.tail.expr)
          max += 1
        } else {
          max = tok.start + 2
        }
      case ^Type_Conv_Expr:
        tok := get_token(p, kind.tkn_index)
        min = tok.start
        expr_min, expr_max := recurse(p, kind.expr) 
        max = expr_max + 1
      case ^Dot_Op:
        min, _ = recurse(p, kind.par)
        _, max = recurse(p, kind.child)
      case ^Pointer_Deref:
        tok := get_token(p, kind.tkn_index)
        max = tok.end
        tok = get_token(p, kind.ptr_lit.tkn_index)
        min = tok.start
    }
    
    return
  }

  start, end := recurse(p, expr)
  return string(p.src[start:end])
}

sema_check_types :: proc(p: ^Parser, a, b: Type) -> (ok: bool) {
  switch atype in a {
    case ^Struct_Type:
      #partial switch btype in b {
        case ^Struct_Type:
          aname := get_node_name(p, atype)
          bname := get_node_name(p, btype)
          return aname == bname
        case: return false
      }
    case ^Array_Type:
      #partial switch btype in b {
        case ^Array_Type:
          return sema_check_types(p, atype.base, btype.base)
        case: return false
      }
    case ^Number_Type:
      #partial switch btype in b {
        case ^Number_Type:
          return atype^ == btype^
        case Literal_Type:
          return sema_literal_conversion(btype, atype) != nil
        case: return false
      }
    case ^Function_Type:
      #partial switch btype in b {
        case ^Function_Type:
          aname := get_node_name(p, atype)
          bname := get_node_name(p, btype)
          return aname == bname
        case: return false
      }
    case ^Slice_Type:
      #partial switch btype in b {
        case ^Slice_Type:
          return sema_check_types(p, atype.base, btype.base)
        case: return false
      }
    case ^Pointer_Type:
      #partial switch btype in b {
        case ^Pointer_Type:
          return sema_check_types(p, atype.base, btype.base)
        case: return false
      }
    case Literal_Type:
        #partial switch btype in b {
        case ^Number_Type:
          return sema_literal_conversion(atype, btype) == btype
        case Literal_Type:
          if atype != btype {
            if (atype == .Any_Float && btype == .Any_Integer ) do return true
            if (btype == .Any_Float && atype == .Any_Integer ) do return true
            return false

          }
          return true
        case: return false
      }
  }
  return false
}

get_type_string :: proc(p: ^Parser, type: Type) -> string {
  switch kind in type {
    case ^Array_Type:
      return fmt.tprintf("[%d]%v", kind.len, get_type_string(p, kind.base))
    case ^Number_Type:
      size := 1 << (kind.size + 3)
      if kind.float {
        return fmt.tprintf("f%d", size)
      } else {
        if kind.signed {
          return fmt.tprintf("s%d", size)
        } else {
          return fmt.tprintf("u%d", size)
        }
      }
    case ^Pointer_Type:
      return fmt.tprintf("^%v", get_type_string(p, kind.base))
    case ^Struct_Type:
      return get_node_name(p, kind)
    case ^Function_Type:
      fn_tok_index := kind.tkn_index + 3
      end_tok_index := kind.params.tail.tkn_index + 1
      fn_tok := get_token(p, fn_tok_index)
      end_tok := get_token(p, end_tok_index)
      return string(p.src[fn_tok.start:end_tok.end])
    case ^Slice_Type:
      return fmt.tprintf("[]%v", get_type_string(p, kind.base))
    case Literal_Type:
      switch kind {
        case .Any_Float:
          return "float"
        case .Any_Integer:
          return "integer"
        case .String:
          return "string"
        case .Invalid:
          return "invalid "
      }
  }
  return "nil"
}

/* create a better scope look up system */
sema_item_in_scope :: proc(p: ^Parser, name: string) -> (item: Scope_Item, ok: bool) {
  for item in p.sema.items {
    if item.name == name do return item, true
  }
  return {}, false
}

sema_item_push :: proc(p: ^Parser, name: string, type: Type) {
  append(&p.sema.items, Scope_Item{name = name, type = type})
}

sema_init :: proc(s: ^Sema) {
  s.gpa = runtime.default_allocator() 
  context.allocator = s.gpa
  s.items = make([dynamic]Scope_Item)
  s.lookup = make(map[string]Type)
}


sema_analyze :: proc(p: ^Parser) -> (ok: bool) {
  context.allocator = p.sema.gpa

  ok = true
  iter := decl_iterator_from_list(&p.decls)
  for decl in decl_iterate_forward(&iter) {
    switch kind in decl {
      case ^Function_Type: 
        p.sema.lookup[get_node_name(p, kind)] = kind
        if !sema_analyze_function(p, kind) do ok = false
      case ^Global_Var_Decl:
        sema_item_push(p, get_node_name(p, kind), kind.type)
      case ^Struct_Type:
        p.sema.lookup[get_node_name(p, kind)] = kind
        if !sema_analyze_struct(p, kind) do ok = false
      case ^Enum_Decl:
    }
  }

  return
}

sema_resolve_decl_type :: proc(p: ^Parser, tok_index: Token_Index, type: ^Type) -> (ok: bool) {
  #partial switch kind in type {
    case ^Array_Type:
      // todo if array is an expression add tok index based on that
      return sema_resolve_decl_type(p, tok_index + 3, &kind.base)
    case ^Number_Type:
      return true
    case ^Pointer_Type:
      return sema_resolve_decl_type(p, tok_index + 1, &kind.base)
    case ^Slice_Type:
      return sema_resolve_decl_type(p, tok_index + 2, &kind.base)
    case nil:
      type_tok := get_token(p, tok_index)

      if type_tok.kind == .Identifier {
          type_name := get_token_name(p, tok_index)
          utype, uok := p.sema.lookup[type_name]
          type^ = utype
          return uok
      }

    case:
      fmt.println("LOOKIE", type)
      return false
  }


  return 
}

sema_analyze_struct :: proc(p: ^Parser, s: ^Struct_Type) -> (ok: bool) {
  ok = true

  iter := field_iterator_from_list(&s.fields)

  for field in field_iterate_forward(&iter) {
    type_ok := sema_resolve_decl_type(p, field.tkn_index + 2, &field.type)
    if !type_ok {
      ok = false
      struct_name := get_node_name(p, s)
      field_name := get_node_name(p, field)
      // fmt.println(field.type)
      error(p, get_token(p, field.tkn_index), "In struct '%v' we cannot resolve field type of '%v'", struct_name, field_name)
    }
  }

  return
}

sema_analyze_function :: proc(p: ^Parser, fn: ^Function_Type) -> bool {
  before_sema_items_len := len(p.sema.items)
  defer resize(&p.sema.items, before_sema_items_len)
  

  iter := field_iterator_from_list(&fn.params)
  for param in field_iterate_forward(&iter) {
    sema_item_push(p, get_node_name(p, param), param.type)
  }

  return sema_analyze_block(p, fn.body, fn.ret_type)
}

sema_check_function_returns :: proc(p: ^Parser, block: ^Block) -> (ok: bool) {
  block_count, return_count := 0, 0

  iter := stmt_iterator_from_block(block)
  for stmt in stmt_iterate_forward(&iter) {
    #partial switch kind in stmt {
      case ^Block:
        block_count += 1
        if sema_check_function_returns(p, kind) do return_count += 1
      case ^Return_Stmt: 
        return true
    }
  }

  return false
}

sema_check_function_call :: proc(p: ^Parser, call: ^Function_Call) -> (ret_type: Type, ok: bool) {
  fn_name := get_node_name(p, call)
  call_token := get_token(p, call.tkn_index)
  ufn, uok := p.sema.lookup[fn_name]
  if !uok {
    // what should happen is that this is put on a queue that
    // we see if this dependency had been resolved... miau :3
    error(p, call_token, "%v has not been declared yet :\\")
    return nil, false
  }
  fn, fok := ufn.(^Function_Type)
  if !fok {
    error(p, call_token, "%v is not a function.", fn_name)
    return nil, false
  }

  args, fields := call.args, fn.params
  ret_type = fn.ret_type
  
  if args.count != fields.count {
    // error message about not having the same shit
    error(p, call_token, "The function %v has %v arguments you put %v", fn_name, fields.count, args.count)
    return ret_type, false
  }
  
  call_iter := expr_list_iterator_from_list(&args)
  field_iter := field_iterator_from_list(&fields)

  for field in field_iterate_forward(&field_iter) {
    arg, iter_ok := expr_iterate_forward(&call_iter)



    type := sema_check_expression(p, arg.expr)

    if field.type != type {
      // error
      num_type, num_ok := field.type.(^Number_Type)
      lit_type, lit_ok := type.(Literal_Type)
      if num_ok && lit_ok {
        if sema_literal_conversion(lit_type, num_type) == nil {
          field_name := get_node_name(p, field)
          error(p, get_token(p, arg.tkn_index), "cannot convert literal '%v' to the parameter '%v' in function %v", lit_type, field_name, fn_name)
          return ret_type, false
        }
      } else {
        arg_token := get_token(p, arg.tkn_index)
        error(p, arg_token, "Function call type mismatch suppose")
        return ret_type, false
      }
    }
  }

  return ret_type, true
}

sema_resolve_local_decl_type :: proc(p: ^Parser, decl: ^Local_Var_Decl) {
  colon_tok := p.tokens[decl.tkn_index + 1]
  assert(colon_tok.kind == .Colon)

  type_tok := p.tokens[decl.tkn_index + 2]

  #partial switch type_tok.kind {
    case .Equals:
      utype := sema_check_expression(p, decl.init)
      #partial switch type in utype {
        case Literal_Type:
          switch type {
            case .Any_Float:
              decl.type = &number_type_map[Token_Kind.Float]
            case .Any_Integer:
              decl.type = &number_type_map[Token_Kind.Int]
            case .String:
            case .Invalid:
          }
        case ^Function_Type:
          error(p, type_tok, "we cant do this rn")
        case:
          decl.type = utype

      }
      case .Identifier:
        name := get_token_name(p, decl.tkn_index + 2)
        utype, uok := p.sema.lookup[name]
        if !uok {
          error(p, type_tok, "%v has not been declared")
        }
        decl.type = utype
  }


}

sema_check_valid_update_obj :: proc(p: ^Parser, obj: Any_Expr) -> (ok: bool) {
  #partial switch kind in obj {
    case ^Array_Index:
      arr_name := get_node_name(p, kind)
      item, ok := sema_item_in_scope(p, arr_name)
      if !ok {
        error(p, get_token(p, kind.tkn_index), "There is no array like type called %v in scope", arr_name)
        return false
      }
      #partial switch type in item.type {
        case ^Array_Type:
          return true
        case ^Slice_Type:
          return true
        case:
          error(p, get_token(p, kind.tkn_index), "%v is not an array like type.")
          return false
      }
      return true
    case ^Literal:
      return true
    case ^Dot_Op:
      return sema_check_valid_update_obj(p, kind.child)
  }

  return false
}

sema_analyze_block :: proc(p: ^Parser, block: ^Block, ret_type: Type /* nil if none*/) -> (ok: bool) {
  ok = true
  before_sema_items_len := len(p.sema.items)
  defer resize(&p.sema.items, before_sema_items_len)
  
  
  iter := stmt_iterator_from_block(block)
  for stmt in stmt_iterate_forward(&iter) {
    #partial switch kind in stmt {
      /* Todo check all these sema checks and analys and report errors*/
      case ^Local_Var_Decl:
        if kind.type == nil {
          sema_resolve_local_decl_type(p, kind)
        }

        if kind.type == nil do ok = false
          
        sema_item_push(p, get_node_name(p, kind), kind.type)
      case ^Block:

        block_ok := sema_analyze_block(p, kind, ret_type)
        if !block_ok do ok = false
      case ^Return_Stmt:

        expr_type := sema_check_expression(p, kind.expr)
        number_type, num_ok := ret_type.(^Number_Type)
        lit_type, lit_ok := expr_type.(Literal_Type)
        if ret_type != expr_type {
          if !(num_ok && lit_ok && sema_literal_conversion(lit_type, number_type) != nil) {
            expr_name, ret_name, expr_str := get_type_string(p, lit_type), get_type_string(p, number_type), get_expr_string(p, kind.expr)
            error(p, get_token(p, kind.tkn_index), "the expression '%v' of type '%v' is not the expected return type '%v'.", expr_str, expr_name, ret_name)
            ok = false
          }
        }
      case ^Update_Stmt:
        if !sema_check_valid_update_obj(p, kind.obj) do ok = false
        obj_type := sema_check_expression(p, kind.obj)      
        expr_type := sema_check_expression(p, kind.expr)

        if !sema_check_types(p, obj_type, expr_type) {
          obj_name, obj_type_name := get_expr_string(p, kind.obj), get_type_string(p, obj_type)
          expr_type_name, expr_string := get_type_string(p, expr_type), get_expr_string(p, kind.expr)
          error(p, get_token(p, kind.tkn_index), "A expression '%v' of type '%v' cannot update '%v' of type '%v'.", expr_string, expr_type_name, obj_name, obj_type_name)
          ok = false
        }
      case ^If_Stmt:
        if sema_check_expression(p, kind.condition) == nil do ok = false
        if !sema_analyze_block(p, kind.body, ret_type) do ok = false
      case ^For_Range_Less_Stmt:
        sema_item_push(p, get_node_name(p, kind.counter), &number_type_map[.Int])
        if !sema_analyze_block(p, kind.body, ret_type) do ok = false
        pop(&p.sema.items)
      case ^Function_Call:
        type, fok := sema_check_function_call(p, kind) 
        if !fok do ok = false
        if type != nil {
          fn_name := get_node_name(p, kind)
          warning(p, get_token(p, kind.tkn_index), "Unused return in '%v' function call.", fn_name)
        }
    }
  }

  // fmt.println(p.sema.items[:])
  return 
}

sema_literal_conversion :: proc(lit: Literal_Type, num: ^Number_Type) -> (type: Type) {
  if num.float {
    #partial switch lit {
      case .Any_Float, .Any_Integer:
        return num
    }
  } else {

    // TODO(ISAAC) Consider signedness
    if lit == .Any_Integer do return num 
  }

  return nil
}

sema_check_expression :: proc(p: ^Parser, expr: Any_Expr) -> (type: Type) {
  switch kind in expr {
    case ^Binary_Expr:
      lhs_type := sema_check_expression(p, kind.lhs)
      rhs_type := sema_check_expression(p, kind.rhs)

      if lhs_type == nil || rhs_type == nil do return nil

      if lhs_type == rhs_type do return lhs_type
      // Since we are not doing operations every type conversion is communitive/assosittive
      
      // lets switch the types to make this easier
      
      _, rhs_is_lit := rhs_type.(Literal_Type)
      if rhs_is_lit do lhs_type, rhs_type = rhs_type, lhs_type 

      // Literal To Number Conversion
      #partial switch lt in lhs_type {
        case Literal_Type:
          #partial switch rt in rhs_type {
            case ^Number_Type:
              return sema_literal_conversion(lt, rt)
            case Literal_Type:
              if lt == rt do return lt
              if lt == .Any_Float && rt == .Any_Integer do return .Any_Float
              if lt == .Any_Integer && rt == .Any_Float do return .Any_Float
              fmt.println("Cannot convert")
            case:
              fmt.println("Cannot do something")
          }
      }

      return nil
    case ^Function_Call:
      type, ok := sema_check_function_call(p, kind)
      if !ok do return nil
      return type
    
    case ^Pointer_Deref:
      ptr_name := get_node_name(p, kind.ptr_lit)
      item, ok := sema_item_in_scope(p, ptr_name)
      assert(ok)
      ptr_type := item.type.(^Pointer_Type)
      return ptr_type.base
    case ^Array_Index:
      array_name := get_node_name(p, kind)
      item, ok := sema_item_in_scope(p, array_name)
      assert(ok)
      #partial switch type in item.type {
        case ^Slice_Type:
          return type.base
        case ^Array_Type:
          return type.base
        case:
          assert(false)
      }
    case ^Literal:
      tok := p.tokens[kind.tkn_index]
      
      if tok.kind == .Integer_Literal {
        return .Any_Integer
      }

      if tok.kind == .Float_Literal {
        return .Any_Float
      }
      
      variable_name := get_node_name(p, kind)
      item, ok := sema_item_in_scope(p, variable_name)
      
      if !ok {
        error(p, get_token(p, kind.tkn_index), "The variable %v is not in scope", variable_name)
        return nil
      }

      return item.type
    case ^Type_Conv_Expr:
      return kind.type
    case ^Pointer_Ref:
      return nil
    case ^Dot_Op:
      return sema_check_dot_expression(p, kind)
  }

  return nil
}

sema_check_dot_expression :: proc(p: ^Parser, dot: ^Dot_Op) -> (type: Type) {
  sema_check_dot_expr_struct :: proc(p: ^Parser, s: ^Struct_Type, expr: Any_Expr) -> (type: Type) {
    #partial switch kind in expr {
      case ^Dot_Op:
        field_name := get_node_name(p, kind.par)
        field_type, ok := get_struct_field_type(p, s, field_name)
        struct_name := get_node_name(p, s)
        if !ok {
          error(p, get_token(p, kind.par.tkn_index), "struct '%v' has no field '%v'.", struct_name, field_name)
          return nil
        }
        struct_type, sok := field_type.(^Struct_Type)
        if !sok {
          error(p, get_token(p, kind.par.tkn_index), "field '%v' in %v is not of type 'struct'", field_name, struct_name)
          return nil
        }
        return sema_check_dot_expr_struct(p, struct_type, kind.child)
      case ^Literal:
        field_name := get_node_name(p, kind)
        field_type, ok := get_struct_field_type(p, s, field_name)
        struct_name := get_node_name(p, s)
        if !ok {
          error(p, get_token(p, kind.tkn_index), "struct '%v' has no field '%v'.", struct_name, field_name)
          return nil
        }
        return field_type
      case ^Array_Index:
        field_name := get_node_name(p, kind)
        field_type, ok := get_struct_field_type(p, s, field_name)
        if !ok {
          struct_name := get_node_name(p, s)
          error(p, get_token(p, kind.tkn_index), "struct '%v' has no array-like field '%v'.", struct_name, field_name)
          return nil
        }
        index_type := sema_check_expression(p, kind.index)

        #partial switch index_kind in index_type {
          case ^Number_Type:
          case Literal_Type:
            #partial switch index_kind {
              case .Any_Integer:
              case:
                error(p, get_token(p, kind.tkn_index), "The expression for the index of %v is not an integer.", field_name)
                return nil
            }
          case:
            error(p, get_token(p, kind.tkn_index), "The expression for the index of %v is not an integer.", field_name)
            return nil
        }
        #partial switch field_kind in field_type {
          case ^Array_Type:
            return field_kind.base   
          case ^Slice_Type:
            return field_kind.base   
          case:
            struct_name := get_node_name(p, s)
            error(p, get_token(p, kind.tkn_index), "in struct '%v', field '%v' is not an indexable type", struct_name, field_name)
            return nil
        }
    }
    return type
  }

  parent := dot.par
  parent_name := get_node_name(p, parent)
  item, ok := sema_item_in_scope(p, parent_name)
  if !ok {
    error(p, get_token(p, parent.tkn_index), "The variable %v is not in scope", parent_name)
    return nil
  }
  
  struct_type, sok := item.type.(^Struct_Type)
  if !sok {
    error(p, get_token(p, parent.tkn_index), "variable '%v' is not of type struct", parent_name)
    return nil
  }
  return sema_check_dot_expr_struct(p, struct_type, dot.child)

}

get_struct_field_type :: proc(p: ^Parser, s: ^Struct_Type, field_name: string) -> (type: Type, ok: bool) {
  iter := field_iterator_from_list(&s.fields)
  for field in field_iterate_forward(&iter) {
    curr_name := get_node_name(p, field)
    if curr_name == field_name {
      return field.type, true
    }
  }

  return
}

