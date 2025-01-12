package frontend

import "core:mem"
import "core:fmt"

Parser :: struct {
  filename: string,
  src: []byte,
  ast: Any_Node,

  
  allocator: mem.Allocator,
  tokens: []Token,
  curr: u32, // current node we are processing
}

expect :: proc(p: ^Parser, index: u32, kind: Token_Kind) -> bool {
  return p.tokens[index].kind == kind
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

    if expect(p, p.curr, .Identifier) {
      index := p.curr // decl index
      p.curr += 1

      if expect(p, p.curr, .Colon) {
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
  p.curr += 1
  // Todo add all contant and other decls
  // this is the second colon telling us it
  // is a contant declaration, for know just 
  // a function
  if expect(p, p.curr, .Colon) {
    p.curr += 1
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

  p.curr += 1
  if expect(p, p.curr, .Left_Paren) {
    // parse field list
    p.curr += 1
    func.params = parse_field_list(p)

    if !expect(p, p.curr, .Right_Paren) {
      fmt.panicf("We expected ')' but we got %v",  p.tokens[p.curr].kind)
    }

  } else {
    fmt.panicf("Expected '(' got %v", p.tokens[p.curr].kind)
  }
  
  // now we should expect -> with return type if not we get void
  p.curr += 1
  if expect(p, p.curr, .Arrow) {
    p.curr += 1
    // Todo not expect int but any type 
    if expect(p, p.curr, .Int) {
    } else {
      fmt.panicf("Only should return int we are int early stages")
    }
  } 

  // now we should check for a function body
  p.curr += 1
  if expect(p, p.curr, .Left_Brace) {
    p.curr += 1
    skip_newlines(p)
    func.body = parse_body(p)
  } else {
    fmt.panicf("We need to consider how we want to do this????????")
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
    if expect(p, p.curr, .Identifier) {
      field.tkn_index = p.curr
    } else {
      fmt.panicf("Expected Identifier in field list got %v", p.tokens[p.curr].kind)
    }

    // colon
    p.curr += 1
    if !expect(p, p.curr, .Colon) {
      fmt.panicf("We expected a colon instead we got %v", p.tokens[p.curr].kind)
    } 


    // type
    // Todo do more than primitive types
    p.curr += 1
    if expect(p, p.curr, .Int) {
      // assume int
      // field.type = Primitive_Type.Int
    } else {
      fmt.panicf("Only supported type right now is int")
    }

    p.curr += 1
    field_count += 1

    if expect(p, p.curr, .Comma) {
      continue  
    } else {
      break 
    }
  }

  return fields
}

parse_body :: proc(p: ^Parser) -> ^Return_Stmt {
  // should enter on the first token of the statement
  tkn := p.tokens[p.curr]
  index := p.curr
  expr: Any_Expr
  #partial switch tkn.kind {
    case .Return:
      p.curr += 1
      expr = parse_expression(p)
    case:
      fmt.panicf("We only expect a return statement right now: got %v", p.tokens[p.curr].kind)

  }

  stmt := new(Return_Stmt)
  stmt.expr = expr
  stmt.tkn_index = index


  return stmt
}


// need to change the crap out of this cause this is baddd
parse_expression :: proc(p: ^Parser) -> Any_Expr {
  top: Any_Expr
  for !expect(p, p.curr, .Newline) {
    lhs := parse_primary(p)
    op := new(Binary_Expr)
    op.tkn_index = p.curr
    p.curr += 1
    rhs := parse_primary(p)

    op.lhs = lhs
    op.rhs = rhs

    top = op
  }

  return top
}

parse_primary :: proc(p: ^Parser) -> ^Literal {
  tkn := p.tokens[p.curr]
  #partial switch tkn.kind {
    case .Identifier:
      lit := new(Literal)
      lit.tkn_index = p.curr
      p.curr += 1
      return lit
    case:
      fmt.panicf("Not supported operand right now: got %v", p.tokens[p.curr].kind)

  }

  return nil
}