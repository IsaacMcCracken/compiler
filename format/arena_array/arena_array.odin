package arena_dynamic_array


import "core:mem"
import vmem "core:mem/virtual"

Allocator :: mem.Allocator
Allocator_Error :: mem.Allocator_Error
Arena :: vmem.Arena
mem.resize()
arena_dynamic_array_allocator_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode,
  size, alignment: int,
  old_memory: rawptr, old_size: int,
  location := #caller_location
) -> (data: []byte, err: Allocator_Error) {

  arena := (^Arena)(allocator_data)

  size, alignment := uint(size), uint(alignment)
  old_size := uint(old_size)

  switch mode {
    case .Alloc, .Alloc_Non_Zeroed:
      return vmem.arena_alloc(arena, size, alignment, location)
    case .Free:
      err = .Mode_Not_Implemented
    case .Free_All:
      vmem.arena_free_all(arena, location)
    case .Resize, .Resize_Non_Zeroed:
      old_data := ([^]byte)(old_memory)

      switch {
        case old_data == nil:
          return vmem.arena_alloc(arena, size, alignment, location)
        case size == old_size:
          // return old memory
          data = old_data[:size]
          return
        case size == 0:
          err = .Mode_Not_Implemented
          return
        case (uintptr(old_data) & uintptr(alignment-1) == 0) && size < old_size:
          // shrink data in-place
          data = old_data[:size]
          return
      }

    new_memory := vmem.arena_alloc(arena, size, alignment, location) or_return
    if new_memory == nil {
      return
    }
    copy(new_memory, old_data[:old_size])
    return new_memory, nil
    case .Query_Features:
    set := (^mem.Allocator_Mode_Set)(old_memory)
    if set != nil {
    set^ = {.Alloc, .Alloc_Non_Zeroed, .Free_All, .Resize, .Query_Features}
    }
    case .Query_Info:
    err = .Mode_Not_Implemented
    }

    return
  }
