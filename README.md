# This is my compiler for my series on youtube

You can watch me make this whole [thing](https://www.youtube.com/playlist?list=PLIBesc5CYsk8b-L70y4J12KkUItBXs8kZ).

The videos are very boring, but I am learning.

so far we got this code

```go
factorial :: func(n: s32) -> s32 {
  if n <= 2 {
    return 1
  }
  return n + factorial(n - 1)
}


nothing :: func() {

}

square :: func(x: s32) -> s32 {
  return x * x
}

main :: func() -> s32 {
  array: [12]int

  array[2 + 4] += int(8) + (1 + 2 * 69)
  x: int = square(array[2 + 4])

  nothing(2)
  return 0
}
```

transpiling into this code 

```c
int factorial(int n )
{
  if ( n <= 2 )
  {
    return 1;
  }
  return n + factorial(n - 1);
}
void nothing(void )
{
}
int square(int x )
{
  return x * x;
}
int main(void )
{
  long long array[12] = {0};
  array[2 + 4] += ((long long)8) + 1 + 2 * 69;
  long long x = square(array[2 + 4]);
  nothing(2);
  return 0;
}
```

we will continue
