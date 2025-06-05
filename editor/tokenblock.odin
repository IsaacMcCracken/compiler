package editor


import vmem "core:mem/virtual"

Token_Block :: struct {
  str: [63]u8,
  len: u8,
}

Token_Block_Node :: struct #raw_union {
  next: ^Token_Block_Node,
  block: Token_Block,
}

Token_Block_Pool :: struct {
  arena: ^vmem.Arena,
  free: ^Token_Block_Node,
}


token_block_pool_init_arena :: proc(arena: ^Arena)

token_block_to_string :: proc(block: ^Token_Block) -> string {
  return string(block.str[:block.len])
}