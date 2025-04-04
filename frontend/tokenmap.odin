#+feature dynamic-literals
package frontend


tmap := map[string]Token_Kind {
  "func" = .Func,
  "struct" = .Struct,
  "for" = .For,
  "in" = .In,
  "return" = .Return,
  "and" = .Logical_And,
  "or" = .Logical_Or,
  "if" = .If,
  

  // MIAU :3
  "int" = .Int,
  "uint" = .Int,
  "s8" = .S8,
  "s16" = .S16,
  "s32" = .S32,
  "s64" = .S64,
  "u8" = .U8,
  "u16" = .U16,
  "u32" = .U32,
  "u64" = .U64,
  "float" = .Float,
  "f32" = .F32,
  "f64" = .F64,
  
}