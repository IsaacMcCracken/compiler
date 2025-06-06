package frontend

import "core:os"
import "core:fmt"
import vmem "core:mem/virtual"
import "core:mem"
import "core:strings"
import "core:unicode"
import "base:runtime"
import odin "core:odin/parser"

main :: proc() {
  args := os.args


  contents, ok := os.read_entire_file("smpl/expression.kot")
  tokenizer: Tokenizer
  tokenizer_init(&tokenizer, "expression.kot", contents)

  tokenize(&tokenizer)
  // print_tokens(tokenizer)

  arena: vmem.Arena
  alloc_err := vmem.arena_init_static(&arena)
  defer vmem.arena_destroy(&arena)
  assert(alloc_err == nil)

  
  parser: Parser
  parser_from_tokenizer(&parser, &tokenizer, vmem.arena_allocator(&arena))


  parse(&parser)
  sema_ok := sema_analyze(&parser)

  if !sema_ok do return 
  b, _ := strings.builder_init(&{})
  to_c_code(&parser, b)


  code := strings.to_string(b^)

  fmt.println(code)


  write_ok := os.write_entire_file("output.c", b.buf[:])

}


print_tokens :: proc(t: Tokenizer) {
  fmt.print("[ ")
  for tkn, i in t.tokens {
    if tkn.kind == .Identifier {
      fmt.printf("%v:\"%v\"", tkn.kind, string(t.src[tkn.start:tkn.end]))
    } else {
      fmt.printf("%v", tkn.kind)

    }
    if i != len(t.tokens) - 1 {
      fmt.print(", ")
    }
  }
  fmt.print(" ]\n")

}