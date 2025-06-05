#+feature dynamic-literals
package meta

import "../frontend"

import "core:os"
import "core:strings"
import "core:fmt"

number_types := map[string]frontend.Number_Type { 
  "s8"  = {size = 0, signed = true},
  "s16" = {size = 1, signed = true},
  "s32" = {size = 2, signed = true},
  "s64" = {size = 3, signed = true},
  "u8"  = {size = 0, signed = false},
  "u16" = {size = 1, signed = false},
  "u32" = {size = 2, signed = false},
  "u64" = {size = 3, signed = false},
 
  "f32" = {size = 2, float = true},
  "f64" = {size = 3, float = true},
}

write_vector_op_functions :: proc(b: ^strings.Builder) {
  op_names := [?]string{"add", "sub", "mul", "div"}
  ops := [?]string{"+", "-", "*", "/"}
  arg_names := [?]string{"a", "b", "out"}
  for type_name, num_type in number_types {
    for op, opi in ops {
      // frontend.to_c_number_type(num_type, b)
      // strings.write_byte(b, ' ')
      fmt.sbprintf(b, "void __%v_vector_%v__(", type_name, op_names[opi])

      for arg, argi in arg_names {
        frontend.to_c_number_type(num_type, b)
        fmt.sbprintf(b, " *%v", arg)
        strings.write_string(b, ", ")

      }
      strings.write_string(b, "uint64_t len) {\n")

      strings.write_string(b, "  for (uint64_t i; i < len; i++) {\n")
      fmt.sbprintfln(b, "    out[i] = a[i] %v b[i];", op)
      strings.write_string(b, "  }\n")
      strings.write_string(b, "}\n\n")

    }
  }
}

main :: proc() {

  b, err := strings.builder_init(&{}, 0, 256)  
  assert(err ==.None)

  include, _ := os.read_entire_file("include.c")
  strings.write_bytes(b, include)
  strings.write_byte(b, '\n')
  write_vector_op_functions(b)

  

  output := strings.to_string(b^)
  fmt.println(output)

  os.write_entire_file("frontend/prelude.c", b.buf[:])

  

}