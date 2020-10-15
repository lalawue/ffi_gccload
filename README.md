
# About

dynamic compile C source string to shared library, then ffi.load() it into LuaJIT process.

# Usage

```lua
local config = require("ffi_gccload").new()

-- like ffi.cdef
config:addSourceDef([[
    int print_name(void);
    int add_num(int a, int b); 
]])
local p = config:loadSourceString([[
#include <stdio.h>
int print_name(void) {
    printf("Hello, world\n");
    return 0;
}
int add_num(int a, int b) {
    return a * 2 + b;
}
]])
if p then
    p.print_name()
    local a, b = ...
    a, b = a and tonumber(a) or 0, b and tonumber(b) or 0
    print("result", p.add_num(a, b))
else
    print("failed to load")
end
```

# Todo

only test under MacOSX.