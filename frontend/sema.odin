package frontend


import ll "core:container/intrusive/list"
import "core:odin/ast"
import "base:runtime"
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

error :: fmt.println

Unresolved_Node :: struct {
  using link: ll.Node,
  decl: Any_Decl,
  type: Type,
}



Sema :: struct {
  // unresolved: ll.List,
  lookup: map[string]Type,
  items: [dynamic]Scope_Item,
  functions: map[string]^Function_Decl,
  gpa: runtime.Allocator,
  literal_pool: mem.Dynamic_Pool

}

Scope_Item :: struct {
  name: string,
  type: Type,
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


sema_analyze :: proc(p: ^Parser) {
  context.allocator = p.sema.gpa

  
  iter := decl_iterator_from_list(&p.decls)
  for decl in decl_iterate_forward(&iter) {
    switch kind in decl {
      case ^Function_Decl: // for now we will just register the return type
        p.sema.functions[get_node_name(p, kind)] = kind
        sema_analyze_function(p, kind)
      case ^Global_Var_Decl:
        sema_item_push(p, get_node_name(p, kind), kind.type)
      case ^Struct_Decl:
      case ^Enum_Decl:
    }
  }
}

sema_analyze_function :: proc(p: ^Parser, fn: ^Function_Decl) -> bool {
  before_sema_items_len := len(p.sema.items)
  defer resize(&p.sema.items, before_sema_items_len)
  

  iter := field_iterator_from_list(&fn.params)
  for param in field_iterate_forward(&iter) {
    sema_item_push(p, get_node_name(p, param), param.type)
  }
  return sema_analyze_block(p, fn.body)
  
}

sema_check_function_call :: proc(p: ^Parser, call: ^Function_Call) -> bool {
  fn_name := get_node_name(p, call)
  fn, ok := p.sema.functions[fn_name]
  if !ok do return false

  args, fields := call.args, fn.params

  
  if args.count != fields.count {
    // error message about not having the same shit
    error("You messed up the arguments count in the function", fn_name)
    return false
  }
  
  call_iter := expr_list_iterator_from_list(&args)
  field_iter := field_iterator_from_list(&fields)

  for field in field_iterate_forward(&field_iter) {
    arg, iter_ok := expr_iterate_forward(&call_iter)
    if !iter_ok {
      error("You messed up the arguments count in the function", fn_name)
      return false
    }


    type := sema_check_expression(p, arg.expr)

    if field.type != type {
      // error
      return false
    }
  }

  return true
}

sema_analyze_block :: proc(p: ^Parser, block: ^Block) -> bool {
  
  

  before_sema_items_len := len(p.sema.items)
  defer resize(&p.sema.items, before_sema_items_len)
  
  
  iter := stmt_iterator_from_block(block)
  for stmt in stmt_iterate_forward(&iter) {
    switch kind in stmt {
      /* Todo check all these sema checks and analys and report errors*/
      case ^Local_Var_Decl:
        sema_item_push(p, get_node_name(p, kind), kind.type)
      case ^Block:
        // ok := 
        sema_analyze_block(p, kind)
      case ^Return_Stmt:
        // ok := 
        sema_check_expression(p, kind.expr)
      case ^Update_Stmt:
        // ok := 
        sema_check_expression(p, kind.expr)
      case ^Array_Index_Update_Stmt:
        
        sema_check_expression(p, kind.array_index)
        sema_check_expression(p, kind.expr)
      case ^If_Stmt:
        sema_check_expression(p, kind.condition)
        sema_analyze_block(p, kind.body)
      case ^For_Range_Less_Stmt:
        sema_item_push(p, get_node_name(p, kind.counter), &number_type_map[.Int])
        sema_analyze_block(p, kind.body)
        pop(&p.sema.items)
      case ^Function_Call:
        sema_check_function_call(p, kind)
    }
  }

  fmt.println(p.sema.items[:])
  return true
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

sema_check_expression :: proc(p: ^Parser, expr: Any_Expr, parent: Any_Expr = nil) -> (type: Type) {
  switch kind in expr {
    case ^Binary_Expr:
      lhs_type := sema_check_expression(p, kind.lhs, kind)
      rhs_type := sema_check_expression(p, kind.rhs, kind)

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
      ok := sema_check_function_call(p, kind)
    
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
        fmt.println("Error: the variable", variable_name, "is not in scope.")
        return nil
      }

      return item.type
    case ^Type_Conv_Expr:

      return kind.type
    case ^Pointer_Ref:
      return nil

  }

  return nil
}