---
coverY: 0
---

# Introduction

This tutorial will guide you through making a random number picker.



Example:

```
Random number picker

Min value:
2
Max value:
10

Your number is 4!
```

### Starting out:

In the script we need to define the minimum value and maximum then use the math library to return a random number.



First define the min & max. Use the print function to output. \n means newline.

```
var min = 0
var max = 0

print("Random number picker\n\n")
```



### Get the values

Now ask for the min value. Use the read function to receive text.

```
min = read("Min value:\n")
```

To get the max we do the same.

```
max = read("Max value\n")
```



### Return the random number

We will use math.random(a, b) to get the random number. Use .. to concat strings together.

tonumber makes a string to a number

tostring makes a number to a string

```
print("Your number is "..tostring(
        math.random(
                tonumber(min), 
                tonumber(max)
        )
    )
)
```

### Full code:

```
var min = 0
var max = 0

print("Random number picker\n\n")

min = read("Min value:\n")
max = read("Max value:\n")

print("Your number is "..tostring(
        math.random(
                tonumber(min), 
                tonumber(max)
        )
    )
)
```
