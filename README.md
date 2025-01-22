# This is my compiler for my series on youtube

You can watch me make this whole [thing](https://www.youtube.com/playlist?list=PLIBesc5CYsk8b-L70y4J12KkUItBXs8kZ).

The videos are very boring, but I am learning.

so far we got this code

```go
linear :: func(x: int, m: int, b: int) -> int {
  return m * x + b
}
```

transpiling into this code 

```c
int linear(int x, int m, int b) {
  return m * x + b
}
```

we will continue
