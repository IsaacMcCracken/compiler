package frontend

Integer_Type :: bit_field u32 {
  size: u8 | 4,
  signed: bool | 1,
}

Float_Type :: bit_field u32 {
  size: u8 | 4
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

Primitive_Type :: union {
  Integer_Type,
  Float_Type,
}

Struct_Type :: struct {
  decl: ^Struct_Decl
}

Literal_Type :: enum {
  Invalid,
  Any_Number,
  Any_Float,
  String,
}

Type :: union #shared_nil {
  ^Primitive_Type,
  ^Array_Type,
  ^Slice_Type,
  Literal_Type,
}


primitive_type_map := #partial [Token_Kind]Primitive_Type {
  .Int = Integer_Type{size = 3, signed = true}, 
  .S8  = Integer_Type{size = 0, signed = true},
  .S16 = Integer_Type{size = 1, signed = true},
  .S32 = Integer_Type{size = 2, signed = true},
  .S64 = Integer_Type{size = 3, signed = true},
  .Uint= Integer_Type{size = 3, signed = false}, 
  .U8  = Integer_Type{size = 0, signed = false},
  .U16 = Integer_Type{size = 1, signed = false},
  .U32 = Integer_Type{size = 2, signed = false},
  .U64 = Integer_Type{size = 3, signed = false},
 
  .Float = Float_Type{size = 2},
  .F32 = Float_Type{size = 2},
  .F64 = Float_Type{size = 3},
}


