package frontend

Type :: union #shared_nil {
  ^Integer_Type,
}

Integer_Type :: bit_field u32 {
  // Size as in powers of 2 in bytes so if size = 3 its 8 bytes or 64 bits
  // 2^0 = 1, 2^1 = 1, 2^2 = 4, 2^3 = 8,    
  size: u8 | 2 
}


primitive_type_map := #partial [Token_Kind]^Type {

}