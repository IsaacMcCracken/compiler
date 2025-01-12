package frontend

import "core:os"
import "core:fmt"
import vmem "core:mem/virtual"
import "core:strings"

main :: proc() {
  fmt.println("Hellope!")

  args := os.args


  // contents, ok := os.read_entire_file(args[1])

  // if len(contents) > int(max(u32)) {
  //   panic("We cannot make source files larger than 4 GB")
  // }

  contents, ok := os.read_entire_file("smpl/fnprototype.kot")

  tokenizer: Tokenizer
  tokenizer_init(&tokenizer, "fnprototype.kot", contents)

  tokenize(&tokenizer)

  // if len(tokenizer.tokens) == 20 do fmt.println("WOW there is 20 tokens")
  fmt.println("Token Count:", len(tokenizer.tokens))

  arena: vmem.Arena
  alloc_err := vmem.arena_init_static(&arena)
  assert(alloc_err == nil)


  parser: Parser
  parser_from_tokenizer(&parser, &tokenizer, vmem.arena_allocator(&arena))


  node := parse(&parser)
  fmt.println(tokenizer.tokens)
  fmt.println(node)

  b, _ := strings.builder_init(&{})
  to_c_code(&parser, node, b)


  code := strings.to_string(b^)

  fmt.println(code)
}