package frontend

Integer_Type :: bit_field u32 {
  // Size as in powers of 2 in bytes so if size = 3 its 8 bytes or 64 bits
  // 2^0 = 1, 2^1 = 1, 2^2 = 4, 2^3 = 8,    
  size: u8 | 4,
  signed: bool | 1,
}

Float_Type :: bit_field u32 {
  size: u8 | 4
}


Primitive_Type :: union {
  Integer_Type,
  Float_Type,
}


Type :: union #shared_nil {
  ^Primitive_Type

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
