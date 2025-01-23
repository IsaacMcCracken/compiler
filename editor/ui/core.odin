package editor_ui

MAX_BOXES :: max(u16)

Link :: distinct u16
vec2 :: [2]i32

import mu "vendor:microui"
import arr "core:container/small_array"
import "core:fmt"


Context :: struct {
  boxes: arr.Small_Array(1024, Box),
  box_hashes: [MAX_BOXES]Link,
}

Rec :: struct #raw_union {
  using r: struct {x, y, w, h: i32},
  using v: struct {pos, size: vec2},
}


Render_Flags :: bit_set[Render_Flag; u8]
Render_Flag :: enum u8 {
  Text,
}


// Box_Stack :: arr.Small_Array(MAX_BOXES, Box)
Box :: struct {
  using rec: Rec,
  name: string,
  first_child, last_child: Link,
  parent, next, prev: Link,
  render_flags: Render_Flags,
}


get_link_idx :: proc{get_link_idx_bytes, get_link_idx_string}
get_link_idx_string :: proc(ctx: ^Context, str: string) -> int {return get_link_idx_bytes(ctx, transmute([]byte)str)}
get_link_idx_bytes :: proc(ctx: ^Context, bytes: []byte) -> int {
  hash :: proc(bytes: []byte) -> int {
    h: int = 5381
    for c in bytes {
      h = ((h<<3)+h) + int  (c)
    }

    return h
  }

  return hash(bytes) % len(ctx.box_hashes)
}

get_link :: proc{get_link_bytes, get_link_string}
get_link_string :: proc(ctx: ^Context, str: string) -> Link {return get_link_bytes(ctx, transmute([]byte)str)}
get_link_bytes :: proc(ctx: ^Context, bytes: []byte) -> Link {
  return ctx.box_hashes[get_link_idx(ctx, bytes)]  
}

get_box :: proc{get_box_bytes, get_box_string, get_box_link}
get_box_link :: proc(ctx: ^Context, link: Link) -> ^Box {
  return arr.get_ptr(&ctx.boxes, int(link))
}
get_box_string :: proc(ctx: ^Context, str: string) -> ^Box {
  box := get_box_bytes(ctx, transmute([]byte)str)
  box.name = str
  return box
}
get_box_bytes :: proc(ctx: ^Context, bytes: []byte) -> ^Box {
  link := get_link(ctx, bytes)
  if link == 0 {
    if arr.len(ctx.boxes) == 0 {
      arr.push(&ctx.boxes, Box{})
    }

    link = Link(arr.len(ctx.boxes))
    arr.push(&ctx.boxes, Box{})
    

    idx := get_link_idx(ctx, bytes)
    ctx.box_hashes[idx] = link
  }


  return get_box_link(ctx, link)
}



push_box_child :: proc(ctx: ^Context, parent, child: Link) {
  p := get_box(ctx, parent)
  c := get_box(ctx, child)

  if (p.last_child == 0) {
    assert(p.first_child == 0)

    p.first_child = child
    p.last_child  = child

    return
  }

  push_box_next(ctx, p.last_child, child)
  c.parent = parent
  p.last_child = child
}

push_box_next :: proc(ctx: ^Context, prev, next: Link) {
  p := get_box_link(ctx, prev)
  n := get_box_link(ctx, next)

  p.next = next
  n.prev = prev
}

button :: proc(ctx: ^Context, name: string) -> bool {
  return false
}