package editor


import vmem "core:mem/virtual"

#assert(size_of(String_Block) == 64)
String_Block :: struct {
  str: [63]u8,
  len: u8,
}

String_Block_Node :: struct #raw_union {
  next: ^String_Block_Node,
  block: String_Block,
}

String_Block_Pool :: struct {
  arena: ^vmem.Arena,
  free: ^String_Block_Node,
}

string_block_pool_init :: proc{}
string_block_pool_init_arena :: proc(arena: ^)

string_block_to_string :: proc(block: ^String_Block) -> string {
  return string(block.str[:block.len])
}