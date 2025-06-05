package editor 

import "ui"
import "../format"

import rl "vendor:raylib"

import mem "core:mem/virtual"
import "core:fmt"

import "core:text/edit"
import "core:strings"

Arena :: mem.Arena

font: rl.Font


Context :: struct {
  node_tex: rl.RenderTexture
}


main :: proc() {
  arena := &Arena{}
  _ = mem.arena_init_static(arena) 
  context.allocator = mem.arena_allocator(arena)


  // font = rl.LoadFont("C:\\Windows\\Fonts\\COURBD.ttf")
  
  rl.InitWindow(1000, 900, "Format Editor")
  rl.SetConfigFlags({.MSAA_4X_HINT})
  font = rl.LoadFont("C:\\Windows\\Fonts\\COURBD.ttf")


  p := &format.Parser{}
  root, module := format.parse_file(p, "format/sample.tr")
  
  b := strings.builder_init(&{})
  code := format.unparse(p, b)
  fmt.println(code)
  
  fmt.println(root)
  fmt.println(p.nodes[7])




  for !rl.WindowShouldClose() {
    rl.BeginDrawing()
      rl.ClearBackground(rl.BLACK)
      dummy_draw_children(p, root.children, &{})



    rl.EndDrawing()


    free_all(context.temp_allocator)
  }
}


dummy_draw_children :: proc(p: ^format.Parser, children: format.Node_List, offset: ^rl.Vector2) {
  iter := format.node_iterator_from_list(p, children) 

  for child in format.node_iterate_forward(&iter) {
    str := strings.clone_to_cstring(format.parse_get_token_name(p, child.token), context.temp_allocator) 
    rl.DrawTextPro(font, str, offset^, {}, 0, 25, 1, rl.WHITE)
    offset.y += 30
    if format.node_has_children(child) {
      offset.x += 60
      fmt.println("offset 1", offset)
      dummy_draw_children(p, child.children, offset)
      offset.x -= 60
      fmt.println("offset 2", offset)

    }
  }
}