package frontend

import "core:crypto/hash"
import "core:container/intrusive/list"



Pointer_Type :: struct {
  base: Type
}

Array_Like_Type :: struct {
  base: Type,
}


Array_Type :: struct {
  using array: Array_Like_Type,
  len: u32,
}

Slice_Type :: struct {
  using array: Array_Like_Type,
}


Number_Type :: bit_field u8 {
  size: u8 | 4,
  float: bool | 1,
  signed: bool | 1,
}

Struct_Type :: struct {
  decl: ^Struct_Decl
}

Literal_Type :: enum {
  Invalid,
  Any_Integer,
  Any_Float,
  String,
}

Type :: union #shared_nil {
  ^Number_Type,
  ^Pointer_Type,
  ^Array_Type,
  ^Slice_Type,
  Literal_Type,
}


number_type_map := #partial [Token_Kind]Number_Type {
  .Int = Number_Type{size = 3, signed = true}, 
  .S8  = Number_Type{size = 0, signed = true},
  .S16 = Number_Type{size = 1, signed = true},
  .S32 = Number_Type{size = 2, signed = true},
  .S64 = Number_Type{size = 3, signed = true},
  .Uint= Number_Type{size = 3, signed = false}, 
  .U8  = Number_Type{size = 0, signed = false},
  .U16 = Number_Type{size = 1, signed = false},
  .U32 = Number_Type{size = 2, signed = false},
  .U64 = Number_Type{size = 3, signed = false},
 
  .Float =  Number_Type{size = 2, float = true},
  .F32 =    Number_Type{size = 2, float = true},
  .F64 =    Number_Type{size = 3, float = true},
}

Type_Cell :: struct {
  using link: list.Node,
  type: Type,
}

Type_Map :: struct {
  cells: []^Type_Cell
}

