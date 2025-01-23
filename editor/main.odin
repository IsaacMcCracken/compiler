package editor 

import "ui"


import mem "core:mem/virtual"
import "core:fmt"
Arena :: mem.Arena

main :: proc() {
  arena := &Arena{}
  _ = mem.arena_init_static(arena) 
  context.allocator = mem.arena_allocator(arena)
  
  ctx := new(ui.Context)
  
  box := ui.get_box(ctx, "miau")
  fmt.println(box  , "miau")
}