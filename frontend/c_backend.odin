package frontend


import "core:strings"
import "core:fmt"


to_c_code :: proc(p: ^Parser, node: Any_Node, b: ^strings.Builder) {
  #partial switch n in node {
    case ^Function_Decl:
      to_c_function(p, n, b)
    case:
      fmt.panicf("NOT SUPPORTED YET")
  }
} 


to_c_function :: proc(p: ^Parser, fn: ^Function_Decl, b: ^strings.Builder) {
  if fn.ret_type == nil {
    strings.write_string(b, "int")
  }

  strings.write_byte(b, ' ')

  strings.write_string(b, get_node_name(p, fn.node))

  strings.write_byte(b, '(')
  strings.write_byte(b, ' ')


  for field, index in fn.params {
    if field.type == nil {
      strings.write_string(b, "int")
    }

    strings.write_byte(b, ' ')
    strings.write_string(b, get_node_name(p, field.node))

    if index != len(fn.params) - 1 {
      strings.write_byte(b, ',')
      strings.write_byte(b, ' ')
    }
  }
  strings.write_byte(b, ' ')

  strings.write_rune(b, ')')

}