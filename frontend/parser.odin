package frontend

import "core:mem"
import "core:fmt"
import "core:strconv"
import rt "base:runtime"



Error_Handler :: #type proc(token: Token, fmt: string, args: ..any)


Parser :: struct {
  filename: string,
  src: []byte,
  decls: Decl_List,

  err: Error_Handler,
  
  sema: Sema,
  allocator: mem.Allocator,
  tokens: []Token,
  curr: u32, // current node we are processing
}


default_error_handler :: proc(token: Token, msg: string, args: ..any) {
  fmt.eprintf("Error: Token(%v, %v, %v)\n\t")
  fmt.eprintfln(msg, args)
}

expect :: proc(p: ^Parser, kind: Token_Kind) -> bool {
  return p.tokens[p.curr].kind == kind
}

advance_token :: proc(p: ^Parser, amount: u32 = 1) -> (tok: Token) {
  p.curr += amount
  return p.tokens[p.curr]
}

current_token :: proc(p: ^Parser) -> (tok: Token, i: Token_Index) {
  i = p.curr
  return peek_token(p, 0), i
}

peek_token :: proc(p: ^Parser, count:=1) -> (tok: Token) {
  if int(p.curr) + count > len(p.tokens) do panic("We gotta stop panicing") 
  return p.tokens[int(p.curr) + count]
}

token_operator_precedence :: proc(tok: Token) -> int {
  #partial switch tok.kind {
    case .Logical_Or: return 3
    case .Logical_And: return 4
    case .Logical_Equals, .Logical_Not_Equals,
         .Less_Than, .Greater_Than, .Less_Than_Equal, .Greater_Than_Equal:
         return 5
    case .Plus, .Minus: return 6
    case .Star, .Slash: return 7
    case:
      fmt.panicf("Expected a +-*/ got a %v", tok.kind)
  }

  unreachable()
}

token_is_operator :: proc(tok: Token) -> bool {
  return (u32(tok.kind) >= u32(Token_Kind.Plus)) && (u32(tok.kind) <= u32(Token_Kind.Greater_Than_Equal))
}

skip_newlines :: proc(p: ^Parser) {
  for p.curr < u32(len(p.tokens)) {
    tkn := p.tokens[p.curr]
    if tkn.kind != .Newline do break
    p.curr += 1
  }
}

parser_from_tokenizer :: proc(p: ^Parser, t: ^Tokenizer, allocator:=context.allocator) {
  p.tokens = t.tokens[:]
  p.src = t.src
  p.filename = t.filename
  p.allocator = allocator
  sema_init(&p.sema)
} 



parse :: proc(p: ^Parser) {
  context.allocator = p.allocator



  parsing: for {
    skip_newlines(p)

    if p.curr >= u32(len(p.tokens)) do break parsing
    
    if expect(p,  .Identifier) {
      index := p.curr // decl index
      advance_token(p)

      if expect(p,  .Colon) {
        // todo add all decls to file node
        decl_append(&p.decls, parse_decl(p, index))
      } else {
        // error here probable or maybe who knows
        fmt.panicf("Right now we are only parsing constant decls got %v", p.tokens[p.curr].kind)
      }

    } else {
      // Todo make this good
      fmt.panicf("Right now we are only parsing constant decls got %v", p.tokens[p.curr].kind)
    }
  }

}

parse_decl :: proc(p: ^Parser, main_token: Token_Index) -> Any_Decl {
  advance_token(p)
  // Todo add all contant and other decls
  // this is the second colon telling us it
  // is a contant declaration, for know just 
  // a function
  if expect(p,  .Colon) {
    advance_token(p)
    tkn := p.tokens[p.curr]

    #partial switch tkn.kind {
      case .Func:
        return parse_function(p, main_token)
      case .Struct:
        return parse_struct(p, main_token)
      case .Enum:
        return parse_enum(p, main_token)
      case:
        fmt.panicf("We are only doing function decls right now")
    }
    
  } else {
    // branch cases for variable decls as well
  }

  return nil
}

parse_enum :: proc(p: ^Parser, enum_name_token: Token_Index) -> ^Enum_Decl {
  enumer := new(Enum_Decl)
  enumer.tkn_index = enum_name_token

  advance_token(p)
  skip_newlines(p)

  if expect(p, .Left_Brace) {
    advance_token(p)
    // todo parse the names into a 
    for !expect(p, .Right_Brace) {
      skip_newlines(p)

      name_tok, name_index := current_token(p)

      if name_tok.kind != .Identifier {
        // we gotta put an error shit on here
        panic("FUCK SHIT FUCK FUCK OMG WE DUMB BITCHES")
      }

      value := new(Named_Expr_List_Node)
      value.tkn_index = name_index 

      skip_newlines(p)
      advance_token(p)

      if expect(p, .Equals) {
        skip_newlines(p)
        advance_token(p)
        value.expr = parse_expression(p)
      }

      named_expr_append(&enumer.values, value)

      if expect(p, .Comma) {
        advance_token(p)
      }  

      advance_token(p)

    }

    advance_token(p)
  }


  return enumer
}

parse_function :: proc(p: ^Parser, fn_name_tkn: Token_Index) -> ^Function_Decl {
  assert(p.tokens[p.curr].kind == .Func)
  func := new(Function_Decl)

  func.tkn_index = fn_name_tkn

  advance_token(p)
  if expect(p,  .Left_Paren) {
    // parse field list
    advance_token(p)
    func.params = parse_field_list(p)

    if !expect(p,  .Right_Paren) {
      fmt.panicf("We expected ')' but we got %v",  p.tokens[p.curr].kind)
    }

  } else {
    fmt.panicf("Expected '(' got %v", p.tokens[p.curr].kind)
  }
  
  // now we should expect -> with return type if not we get void
  advance_token(p)
  if expect(p,  .Arrow) {
    advance_token(p)
    // Todo not expect int but any type 
    func.ret_type = parse_type(p)
  } 

  // now we should check for a function body
  skip_newlines(p)
  if expect(p,  .Left_Brace) {
    advance_token(p)
    skip_newlines(p)
    func.body = parse_body(p)
  } else {
    fmt.panicf("GOT milkies")
  }

  return func
}

parse_struct :: proc(p: ^Parser, struct_name_token_index: Token_Index) -> ^Struct_Decl {
  assert(p.tokens[p.curr].kind == .Struct)
  struct_decl := new(Struct_Decl)

  struct_decl.tkn_index = struct_name_token_index

  token := advance_token(p)

  if expect(p, .Left_Brace) {
    token = advance_token(p)
    fields := parse_field_list(p)
    skip_newlines(p)
    if expect(p, .Right_Brace) {
      struct_decl.fields = fields
      advance_token(p)
    } else {
      tok, i := current_token(p)
      fmt.println(get_node_name(p, {tkn_index = i}))
      fmt.panicf("CRAP: we expected a } we got %v", tok.kind)
    }
  } else {
    // we gotta do an error system soon
  }


  return struct_decl
}

parse_field_list :: proc(p: ^Parser) -> Field_List {
  fields: Field_List

  parsing_fields: for {
    skip_newlines(p)
    field_token, fields_name_index := current_token(p)

    if !expect(p, .Identifier) {
      if field_token.kind == .Right_Brace || field_token.kind == .Right_Paren do break parsing_fields
      //error
    }

    token := advance_token(p)

    if token.kind == .Colon {
      token = advance_token(p)
      type := parse_type(p)
      field := new(Field)
      field.tkn_index = fields_name_index
      field.type = type

      field_append(&fields, field)
    } else if token.kind == .Comma {

    } else {
      // error
    }

    if !expect(p, .Comma) do break parsing_fields
    advance_token(p)

  }

  return fields
}

parse_expect_number :: proc(p: ^Parser) -> (value: int, ok: bool) {
  tok, idx := current_token(p)
  if tok.kind != .Integer_Literal do return 0, false
  str := string(p.src[tok.start:tok.end])
  advance_token(p)
  return strconv.parse_int(str)
}

parse_type :: proc(p: ^Parser) -> Type {
  tok, index := current_token(p)
  type: Type

  #partial switch tok.kind {
    /* Primitive Types */
    case .Int, .Uint, .U8, .S8, .U16, .S16, .U32, .S32, .U64, .S64, .Float, .F32, .F64:
      type = &number_type_map[tok.kind]
    /* Pointer Types */
    case .Carrot:
      ptr_type := new(Pointer_Type)
      advance_token(p)
      base := parse_type(p)
      ptr_type.base = base

      return ptr_type
    /* Array Types */
    case .Left_Bracket:
      advance_token(p)

      if expect(p, .Right_Bracket) {
        /* slice array */
        advance_token(p)
        base := parse_type(p)

        slice_type := new(Slice_Type)
        slice_type.base = base
        type = slice_type
      } else {
        /* static array */
        length, ok := parse_expect_number(p) // this function advances the token
        if !ok do fmt.panicf("Fuck it we fail right now")
        
        if !expect(p, .Right_Bracket) {
          fmt.panicf("Where is the closing bracket")
        }
        advance_token(p)
        // base type
        base := parse_type(p)
  
        // TODO: make a global type system
        arr_type := new(Array_Type)
        arr_type^ = Array_Type{
          base = base,
          len = u32(length)
        }
  
        
        type = arr_type
      }

      // consider making this a expresion

    case:
      fmt.panicf("only primitive types rn, here is the token we got %v", p.tokens[:p.curr+1])
  }
  advance_token(p)

  return type
}

parse_body :: proc(p: ^Parser) -> ^Block {

  block := new(Block)
  
  parsing_stmts: for !expect(p, .Right_Brace) {
    token, index := current_token(p)
    final: Any_Stmt
    #partial switch token.kind {
      case .Return:
        advance_token(p)
        expr := parse_expression(p)
        stmt := new(Return_Stmt)
        stmt.expr = expr
        stmt.tkn_index = index
        final = stmt
      case .Identifier: // this could be a local declaration, a function call, update statement
        final = parse_update_local_decl_or_call(p)
      case .If: 
        final = parse_if_stmt(p)
      case .For: 
        final = parse_for_loop(p)
      
      case:
        fmt.panicf("Not a supported statement right now: got %v", p.tokens[p.curr].kind)
    }

    skip_newlines(p)
    stmt_append(block, final)
  }




  if expect(p, .Right_Brace) {
    advance_token(p)
  } else {
    // error probably
  }

  return block
}

parse_update_local_decl_or_call :: proc(p: ^Parser) -> Any_Stmt {
  final: Any_Stmt
  tok, main_index := current_token(p)

  next_token := peek_token(p)
  #partial switch next_token.kind {
    case .Equals, .Plus_Equals, .Minus_Equals, .Times_Equals:
      advance_token(p)
      _, updater_index := current_token(p)
      stmt := new(Update_Stmt)
      stmt.tkn_index = updater_index
      stmt.var = new(Literal)
      // TODO(ISAAC) make sure that this is a variable
      stmt.var.tkn_index = main_index
      advance_token(p)
      stmt.expr = parse_expression(p)
      final = stmt
      
    case .Colon:
      advance_token(p, 2)
      type := parse_type(p)
      var := new(Local_Var_Decl) 
      var.type = type
      var.tkn_index = main_index

      if expect(p, .Equals) {
        advance_token(p)
        var.init = parse_expression(p)
      }
      final = var
    case .Left_Bracket:
      array_index_update := new(Array_Index_Update_Stmt)
      array_index_update.array_index = parse_array_index(p)
      updater_tok, updater_index := current_token(p)
      #partial switch updater_tok.kind {
        case .Equals, .Plus_Equals, .Minus_Equals, .Times_Equals:
          array_index_update.tkn_index = updater_index
          advance_token(p)
          array_index_update.expr = parse_expression(p)
        case:
          fmt.panicf("Dont know this updater %v", next_token.kind)
      }
      final = array_index_update
    case .Left_Paren:
      final = parse_function_call(p)
  }

  

  return final
}

parse_if_stmt :: proc(p: ^Parser) -> ^If_Stmt {
  stmt := new(If_Stmt)
  advance_token(p)
  stmt.condition = parse_expression(p)
  skip_newlines(p)
  if expect(p, .Left_Brace) {
    advance_token(p)
    skip_newlines(p)
    stmt.body = parse_body(p)
  } else {
    fmt.panicf("expected a {")
  }
  return stmt
}


parse_for_loop :: proc(p: ^Parser) -> Any_Stmt {
  advance_token(p)
  token, index := current_token(p)
  
  if expect(p, .Identifier)  {
    identifier_tok, identifier_idx := token, index
    counter := new(Literal)
    counter^ = Literal{tkn_index = identifier_idx}
    advance_token(p)
    if expect(p, .In) {
      advance_token(p)
      start_expr := parse_expression(p)
      if !expect(p, .Range_Less) {
        fmt.panicf("we are expecting a range here sorry")
      }

      advance_token(p)

      end_expr := parse_expression(p) 
      skip_newlines(p)
      if !expect(p, .Left_Brace) {
        fmt.panicf("we need to start the scope")
      }
      advance_token(p)
      skip_newlines(p)
      body := parse_body(p)

      for_less_stmt := new(For_Range_Less_Stmt)
      for_less_stmt^ = For_Range_Less_Stmt{
        tkn_index = index,
        start_expr = start_expr,
        end_expr = end_expr,
        counter = counter,
        body = body
      }

      return for_less_stmt
    }
  } else {
    fmt.panicf("We do not support this debauchery right now")
  }


  return nil
}


// need to change the crap out of this cause this is baddd
parse_expression :: proc(p: ^Parser) -> Any_Expr {
  return parse_precedence(p, parse_urinary(p))
}

parse_precedence :: proc(p: ^Parser, lhs: Any_Expr, precedence := 0) -> Any_Expr {
  // make loohahead helper called peek_token
  // parse primary should be parse_urinary
  // get_token_op_precedence(tok: Token) -> int
  // make a function that checks if token is a operator
  // token_is_operator should be called token is binary operator

  // When precedence is going down or staying the same we want to loop
  // When precedence is going up we want to recurse.
  lhs := lhs
  lookahead, lindex := current_token(p) // should be operator

  // assert(lookahead.kind == .Plus)

  for token_is_operator(lookahead) && token_operator_precedence(lookahead) >= precedence {
    op, oindex := lookahead, lindex
    
    advance_token(p) // second operand
    rhs := parse_urinary(p) // second operand
    lookahead, lindex = current_token(p)
    
    for token_is_operator(lookahead) && token_operator_precedence(lookahead) > token_operator_precedence(op) {
      rhs = parse_precedence(p, rhs, token_operator_precedence(lookahead))
      lookahead, lindex = current_token(p)
    }
    operation := new(Binary_Expr)
    operation^ = Binary_Expr{
      lhs = lhs,
      rhs = rhs,
      tkn_index = oindex
    }

    lhs = operation
  }

  // fmt.println(lookahead)
  return lhs

}

parse_urinary :: proc(p: ^Parser) -> Any_Expr {

  tkn, tkn_index := current_token(p)
  #partial switch tkn.kind {
    case .Identifier:
      if peek_token(p).kind == .Left_Paren {
        return parse_function_call(p)
      } else if peek_token(p).kind == .Left_Bracket {
        return parse_array_index(p)
      } else if peek_token(p).kind ==.Carrot {
        /* we will probably have to fix this later to be more modular */
        advance_token(p)
        tok, index := current_token(p)
        deref := new(Pointer_Deref)
        deref.tkn_index = index
        deref.ptr_lit.tkn_index = tkn_index
        advance_token(p)
        return deref
      }

      fallthrough 
    case .Integer_Literal, .Float_Literal:
      lit := new(Literal)
      lit.tkn_index = p.curr
      advance_token(p)
      return lit
    case .Int, .Uint, .U8, .S8, .U16, .S16, .U32, .S32, .U64, .S64, .Float, .F32, .F64:
      conv := parse_type_conv(p)
      advance_token(p)
      return conv
    case .Left_Paren:
      advance_token(p)
      expr := parse_expression(p)
      if !expect(p, .Right_Paren) {
        fmt.panicf("expected a right paren")
      }
      advance_token(p)
      return expr
    case .Ambersand:
      advance_token(p)
      expr := parse_expression(p)
      ref := new(Pointer_Ref)
      ref.tkn_index = tkn_index
      ref.expr = expr
      return ref
    case:
      fmt.panicf("Not supported operand right now: got %v", p.tokens[p.curr].kind)
  }

  return nil
}

parse_type_conv :: proc(p: ^Parser) -> ^Type_Conv_Expr {
  conv := new(Type_Conv_Expr)
  tok, index := current_token(p)
  type := &number_type_map[tok.kind]
  tok = advance_token(p)
  if !expect(p, .Left_Paren) {
    fmt.panicf("expected a left paren")
  }

  advance_token(p)
  expr := parse_expression(p)

  if !expect(p, .Right_Paren) {
    fmt.panicf("expected a right paren")
  }
  
  conv^ = Type_Conv_Expr{
    tkn_index = index,
    type = type,
    expr = expr
  }

  return conv
}

parse_array_index :: proc(p: ^Parser) -> ^Array_Index {
  array_index := new(Array_Index)
  _, array_index_token_index := current_token(p)
  array_index.tkn_index = array_index_token_index

  advance_token(p, 2)

  array_index.index = parse_expression(p)
  
  if !expect(p, .Right_Bracket) {
    fmt.panicf("Nooo we expected a right bracket")
  }

  advance_token(p)


  return array_index
}

parse_function_call :: proc(p: ^Parser) -> ^Function_Call {
  call := new(Function_Call)

  fn_call_token, fn_call_tkn_index := current_token(p)

  
  
  call.tkn_index = fn_call_tkn_index
  // parse args 

  advance_token(p)
  if !expect(p, .Left_Paren) {
    //error
    fmt.panicf("Frick")
  } 
  
  advance_token(p) // current token is now the first arg
  parsing_args: for p.curr < u32(len(p.tokens)) {
    tok, _ := current_token(p)
   
    if tok.kind == .Right_Paren do break  

    node := new(Expr_List_Node) 
    node.expr = parse_expression(p)
    expr_append(&call.args, node)

    tok, _ = current_token(p)

    if tok.kind == .Comma do advance_token(p)


  }



  if !expect(p, .Right_Paren) {
    fmt.panicf("Friggen Heck")
  } 

  advance_token(p)

  return call
}