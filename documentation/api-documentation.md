---
coverY: 0
---

# API documentation

**NOTE: This tutorial teaches you about hosts. host.cpp is a command-line tool and does not use the following documentation.**



### Interpret

```
host.interpret(code) 
```

Returns null.



### Compiler

```
host.compile(code)
```

Returns Bytecode.



### Language

Language can transpile to other languages

#### Lua:

```
host.lang.lua(code)
```

Returns lua code that is equivalent to your voxel code
