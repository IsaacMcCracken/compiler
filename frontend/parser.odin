package frontend

import "core:mem"
import "core:fmt"
import rt "base:runtime"

Error_Handler   :: #type proc(token: Token, fmt: string, args: ..any)


Parser :: struct {
  filename: string,
  src: []byte,
  ast: Any_Node,

  err: Error_Handler,
  
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

advance_token :: proc(p: ^Parser) -> (tok: Token) {
  p.curr += 1
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
} 



parse :: proc(p: ^Parser) -> Any_Node {
  context.allocator = p.allocator

  parsing: for {
    if expect(p,  .Identifier) {
      index := p.curr // decl index
      advance_token(p)

      if expect(p,  .Colon) {
        // todo add all decls to file node
        return parse_decl(p, index)
      } else {
        // error here probable or maybe who knows
        fmt.panicf("Right now we are only parsing constant decls got %v", p.tokens[p.curr].kind)
      }

    } else {
      // Todo make this good
      fmt.panicf("Only parsing function decls right now.")
    }
  }

  return nil
}

parse_decl :: proc(p: ^Parser, main_token: Token_Index) -> Any_Node {
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
      case:
        fmt.panicf("We are only doing function decls right now")
    }
    
  } else {
    // branch cases for variable decls as well
  }

  return nil
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

parse_field_list :: proc(p: ^Parser) -> []Field {
  // count parameters

  // this is kinda dangerous
  // Todo means test this
  count := 1
  for tkn in p.tokens[p.curr:] {
    if tkn.kind == .Right_Paren do break  
    if tkn.kind == .Comma do count += 1
  }

  fields, _ := make([]Field, count)

  field_count := 0
  for &field in fields {
    // name
    if expect(p,  .Identifier) {
      field.tkn_index = p.curr
    } else {
      fmt.panicf("Expected Identifier in field list got %v", p.tokens[p.curr].kind)
    }

    // colon
    advance_token(p)
    if !expect(p,  .Colon) {
      fmt.panicf("We expected a colon instead we got %v", p.tokens[p.curr].kind)
    } 


    // type
    // Todo do more than primitive types
    advance_token(p)
    if expect(p,  .Int) {
      type := parse_type(p)
      field.type = type
    } else {
      fmt.panicf("Only supported type right now is int")
    }


    if expect(p,  .Comma) {
      advance_token(p)
      continue  
    } else {
      break 
    }
  }

  return fields
}


parse_type :: proc(p: ^Parser) -> ^Primitive_Type {
  tok, index := current_token(p)
  type: ^Primitive_Type
  #partial switch tok.kind {
    case .Int, .Uint, .U8, .S8, .U16, .S16, .U32, .S32, .U64, .S64, .Float, .F32, .F64:
      type = &primitive_type_map[tok.kind]
    case:
      fmt.panicf("only primitive types rn")
  }
  advance_token(p)

  return type
}

parse_body :: proc(p: ^Parser) -> ^Block {
  // should enter on the first token of the statement
  temp := rt.default_temp_allocator_temp_begin() // maybe replace with custom
  defer rt.default_temp_allocator_temp_end(temp)

  // every time we make a statement we use the temp allocator to
  // make a slice. Make sure that when call stack gets back to this function
  // that the context.temp_allocator remains in the same state for slices.
  // basically when ever a allocation is made on the temp allocator it uses the temp arena ???
  fmt.println(temp)

  
  
  first: ^Any_Stmt  
  stmts, err := make([]Any_Stmt, 8)
  count := 0

  
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
        advance_token(p)
        next_token, next_index := current_token(p)
        #partial switch next_token.kind {
          case .Equals, .Plus_Equals, .Minus_Equals, .Times_Equals:
            stmt := new(Update_Stmt)
            stmt.tkn_index = next_index
            stmt.var = new(Literal)
            stmt.var.tkn_index = index
            advance_token(p)
            stmt.expr = parse_expression(p)
            final = stmt
            
          case .Colon:
            advance_token(p)
            type := parse_type(p)
            var := new(Var_Decl)
            var.type = type
            var.tkn_index = index
    
            if expect(p, .Equals) {
              advance_token(p)
              var.init = parse_expression(p)
            }

            final = var
        }
      case .If: {
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

        final = stmt
      }
      case:
        fmt.panicf("We only expect a return statement right now: got %v", p.tokens[p.curr].kind)
    }

    skip_newlines(p)

    stmts[count] = final
    count += 1

  }



  block := new(Block)
  block.stmts = stmts[:count]

  if expect(p, .Right_Brace) {
    advance_token(p)
  } else {
    // error probably
  }

  return block
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
  tkn := p.tokens[p.curr]
  #partial switch tkn.kind {
    case .Identifier, .Number:
      lit := new(Literal)
      lit.tkn_index = p.curr
      advance_token(p)
      return lit
    case:
      fmt.panicf("Not supported operand right now: got %v", p.tokens[p.curr].kind)
  }

  return nil
}