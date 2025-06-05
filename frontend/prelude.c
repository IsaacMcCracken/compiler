#include <stdio.h>
#include <stdint.h>
#include <assert.h>
inline void __f32_vector_add__(float *a, float *b, float *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] + b[i];
  }
}

inline void __f32_vector_sub__(float *a, float *b, float *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] - b[i];
  }
}

inline void __f32_vector_mul__(float *a, float *b, float *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] * b[i];
  }
}

inline void __f32_vector_div__(float *a, float *b, float *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] / b[i];
  }
}

inline void __f32_vector_cpy(float *dst, float *src, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    dst[i] = src[i];
  }

}

inline void __u16_vector_add__(uint16_t *a, uint16_t *b, uint16_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] + b[i];
  }
}

inline void __u16_vector_sub__(uint16_t *a, uint16_t *b, uint16_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] - b[i];
  }
}

inline void __u16_vector_mul__(uint16_t *a, uint16_t *b, uint16_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] * b[i];
  }
}

inline void __u16_vector_div__(uint16_t *a, uint16_t *b, uint16_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] / b[i];
  }
}

inline void __u16_vector_cpy(uint16_t *dst, uint16_t *src, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    dst[i] = src[i];
  }

}

inline void __s32_vector_add__(int32_t *a, int32_t *b, int32_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] + b[i];
  }
}

inline void __s32_vector_sub__(int32_t *a, int32_t *b, int32_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] - b[i];
  }
}

inline void __s32_vector_mul__(int32_t *a, int32_t *b, int32_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] * b[i];
  }
}

inline void __s32_vector_div__(int32_t *a, int32_t *b, int32_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] / b[i];
  }
}

inline void __s32_vector_cpy(int32_t *dst, int32_t *src, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    dst[i] = src[i];
  }

}

inline void __s64_vector_add__(int64_t *a, int64_t *b, int64_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] + b[i];
  }
}

inline void __s64_vector_sub__(int64_t *a, int64_t *b, int64_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] - b[i];
  }
}

inline void __s64_vector_mul__(int64_t *a, int64_t *b, int64_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] * b[i];
  }
}

inline void __s64_vector_div__(int64_t *a, int64_t *b, int64_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] / b[i];
  }
}

inline void __s64_vector_cpy(int64_t *dst, int64_t *src, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    dst[i] = src[i];
  }

}

inline void __u32_vector_add__(uint32_t *a, uint32_t *b, uint32_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] + b[i];
  }
}

inline void __u32_vector_sub__(uint32_t *a, uint32_t *b, uint32_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] - b[i];
  }
}

inline void __u32_vector_mul__(uint32_t *a, uint32_t *b, uint32_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] * b[i];
  }
}

inline void __u32_vector_div__(uint32_t *a, uint32_t *b, uint32_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] / b[i];
  }
}

inline void __u32_vector_cpy(uint32_t *dst, uint32_t *src, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    dst[i] = src[i];
  }

}

inline void __u64_vector_add__(uint64_t *a, uint64_t *b, uint64_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] + b[i];
  }
}

inline void __u64_vector_sub__(uint64_t *a, uint64_t *b, uint64_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] - b[i];
  }
}

inline void __u64_vector_mul__(uint64_t *a, uint64_t *b, uint64_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] * b[i];
  }
}

inline void __u64_vector_div__(uint64_t *a, uint64_t *b, uint64_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] / b[i];
  }
}

inline void __u64_vector_cpy(uint64_t *dst, uint64_t *src, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    dst[i] = src[i];
  }

}

inline void __f64_vector_add__(double *a, double *b, double *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] + b[i];
  }
}

inline void __f64_vector_sub__(double *a, double *b, double *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] - b[i];
  }
}

inline void __f64_vector_mul__(double *a, double *b, double *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] * b[i];
  }
}

inline void __f64_vector_div__(double *a, double *b, double *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] / b[i];
  }
}

inline void __f64_vector_cpy(double *dst, double *src, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    dst[i] = src[i];
  }

}

inline void __s16_vector_add__(int16_t *a, int16_t *b, int16_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] + b[i];
  }
}

inline void __s16_vector_sub__(int16_t *a, int16_t *b, int16_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] - b[i];
  }
}

inline void __s16_vector_mul__(int16_t *a, int16_t *b, int16_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] * b[i];
  }
}

inline void __s16_vector_div__(int16_t *a, int16_t *b, int16_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] / b[i];
  }
}

inline void __s16_vector_cpy(int16_t *dst, int16_t *src, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    dst[i] = src[i];
  }

}

inline void __s8_vector_add__(int8_t *a, int8_t *b, int8_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] + b[i];
  }
}

inline void __s8_vector_sub__(int8_t *a, int8_t *b, int8_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] - b[i];
  }
}

inline void __s8_vector_mul__(int8_t *a, int8_t *b, int8_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] * b[i];
  }
}

inline void __s8_vector_div__(int8_t *a, int8_t *b, int8_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] / b[i];
  }
}

inline void __s8_vector_cpy(int8_t *dst, int8_t *src, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    dst[i] = src[i];
  }

}

inline void __u8_vector_add__(uint8_t *a, uint8_t *b, uint8_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] + b[i];
  }
}

inline void __u8_vector_sub__(uint8_t *a, uint8_t *b, uint8_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] - b[i];
  }
}

inline void __u8_vector_mul__(uint8_t *a, uint8_t *b, uint8_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] * b[i];
  }
}

inline void __u8_vector_div__(uint8_t *a, uint8_t *b, uint8_t *out, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    out[i] = a[i] / b[i];
  }
}

inline void __u8_vector_cpy(uint8_t *dst, uint8_t *src, uint64_t len) {
  for (uint64_t i; i < len; i++) {
    dst[i] = src[i];
  }

}

