# This is my compiler

so far we got this code

```go
Vector2 :: struct {
  x: f32,
  y: f32
}

Animal_Kind :: enum {
  Dog = 42,
  Human,
  Monkey
}

Animal :: struct {
  pos: Vector2,
  age: s8
}

fibonacci :: func(n: s32) -> s32 {
  if n <= 2 {
    return 1
  }
  return n + fibonacci(n - 1)
}



square :: func(x: s32) -> s32 {
  return x * x
}

main :: func() -> s32 {

  a: Animal
  a.age = s8(fibonacci(4))
  a.pos.x = square(3)
  a.pos.y = 42.0

  return 0
}





```

transpiling into this code 

```c
struct Vector2 {
  float x;
  float y;
};
typedef int Animal_Kind;
enum {
  Animal_Kind_Dog = 42,
  Animal_Kind_Human,
  Animal_Kind_Monkey,
};
struct Animal {
  struct Vector2 pos;
  int8_t age;
};
int32_t fibonacci(int32_t n )
{
  if ( n <= 2 )
  {
    return 1;
  }
  return n + fibonacci(n - 1);
}
int32_t square(int32_t x )
{
  return x * x;
}
int32_t main(void )
{
  struct Animal a = { 0 };
  a.age = ((int8_t)fibonacci(4));
  a.pos.x = square(3);
  a.pos.y = 42.0;
  return 0;
}
```

we will continue
