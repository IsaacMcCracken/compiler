package frontend


import ll "core:container/intrusive/list"
import "core:odin/ast"
import "base:runtime"
import "core:fmt"


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
    }
  }
}

sema_analyze_function :: proc(p: ^Parser, fn: ^Function_Decl) -> bool {
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


    type, ok := sema_check_expression(p, arg.expr)
    if !ok {
      //error
      // error(" ")
      return false
    }


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
        sema_item_push(p, get_node_name(p, kind.counter), &primitive_type_map[.Int])
        sema_analyze_block(p, kind.body)
        pop(&p.sema.items)
      case ^Function_Call:
        sema_check_function_call(p, kind)
    }
  }

  fmt.println(p.sema.items[:])
  return true
}

sema_check_expression :: proc(p: ^Parser, expr: Any_Expr) -> (type: Type, ok: bool) {
  switch kind in expr {
    case ^Binary_Expr:
      lhs_type, lhs_ok := sema_check_expression(p, kind.lhs)
      if !lhs_ok do return nil, true
      rhs_type, rhs_ok := sema_check_expression(p, kind.rhs)
      if rhs_type == lhs_type do return lhs_type, true
    case ^Function_Call:
      ok := sema_check_function_call(p, kind)
      
    case ^Array_Index:
      array_name := get_node_name(p, kind)
      item, ok := sema_item_in_scope(p, array_name)
      assert(ok)
      #partial switch type in item.type {
        case ^Slice_Type:
          return type.base, true
        case ^Array_Type:
          return type.base, true
        case:
          assert(false)
      }
    case ^Literal:
      tok := p.tokens[kind.tkn_index]
      
      if tok.kind == .Number {
        return .Any_Number, true
      }
      
      variable_name := get_node_name(p, kind)
      item, ok := sema_item_in_scope(p, variable_name)
      
      if ok {
        return item.type, true
      }
    case ^Type_Conv_Expr:
      return kind.type, true

  }

  return nil, false
}