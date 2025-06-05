# This is my compiler for my series on youtube

You can watch me make this whole [thing](https://www.youtube.com/playlist?list=PLIBesc5CYsk8b-L70y4J12KkUItBXs8kZ).

The videos are very boring, but I am learning.

so far we got this code

```go
Vector2 :: struct {
  x: f32,
  y: f32
}

Animal_Kind :: enum {
  Dog = 42,
  Human = 420,
  Monkey = 69
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
  Animal_Kind_Human = 420,
  Animal_Kind_Monkey = 69,
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
