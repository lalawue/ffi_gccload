--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local ffi = require("ffi")
local support_arch = {["x86"] = "", ["x64"] = ""}
local support_os = {["Linux"] = "gcc", ["OSX"] = "gcc", ["BSD"] = "cc"} -- ["Windows"]

local _M = {}
_M.__index = _M

function _M:addIncludePaths(...)
    for i = 1, 128, 1 do
        local path = select(i, ...)
        if type(path) == "string" then
            self._incs[#self._incs + 1] = "-I" .. path
        else
            break
        end
    end
end

function _M:addLibaryPaths(...)
    for i = 1, 128, 1 do
        local path = select(i, ...)
        if type(path) == "string" then
            self._lib_paths[#self._lib_paths + 1] = "-L" .. path
        else
            break
        end
    end
end

function _M:addLibraries(...)
    for i = 1, 128, 1 do
        local lib = select(i, ...)
        if type(lib) == "string" then
            self._libs[#self._libs + 1] = "-l" .. lib
        else
            break
        end
    end
end

function _M:addCflags(...)
    for i = 1, 128, 1 do
        local flags = select(i, ...)
        if type(flags) == "string" then
            self._cflags[#self._cflags + 1] = flags
        else
            break
        end
    end
end

local function _tmpPath(self, suffix, fname)
    fname = fname or tostring(math.random(100000))
    return self._dir .. "/" .. fname .. suffix
end

local function _loadLibrary(self)
    if #self._srcs <= 0 then
        print("no input files")
    else
        local tmp_lib = _tmpPath(self, ".so")
        local cmd_tbl = {}
        cmd_tbl[#cmd_tbl + 1] = self._cc
        cmd_tbl[#cmd_tbl + 1] = table.concat(self._incs, " ")
        cmd_tbl[#cmd_tbl + 1] = table.concat(self._lib_paths, " ")
        cmd_tbl[#cmd_tbl + 1] = table.concat(self._libs, " ")
        cmd_tbl[#cmd_tbl + 1] = table.concat(self._cflags, " ")
        cmd_tbl[#cmd_tbl + 1] = "-o " .. tmp_lib
        cmd_tbl[#cmd_tbl + 1] = table.concat(self._srcs, " ")
        local cmd_string = table.concat(cmd_tbl, " ")
        os.execute(cmd_string)
        local lib = ffi.load(tmp_lib)
        os.remove(tmp_lib)
        return lib
    end
end

--[[
    define before add source string
]]
function _M:addSourceDef(cdef_string)
    self._cdef = cdef_string
    ffi.cdef(cdef_string)
end

function _M:loadSourceFiles(...)
    for i = 1, 128, 1 do
        local file = select(i, ...)
        if type(file) == "string" then
            self._srcs[#self._srcs + 1] = file
        end
    end
    return _loadLibrary(self)
end

function _M:loadSourceString(source_string)
    if source_string == nil then
        return nil
    end
    local fpath = _tmpPath(self, ".c", "tmp_string")
    local fp = io.open(fpath, "wb+")
    if not fp then
        print("failed to open tmp file:", fpath)
        return nil
    end
    fp:write(source_string)
    fp:close()
    self._srcs[#self._srcs + 1] = fpath
    return _loadLibrary(self)
end

local function _new()
    if jit and support_arch[jit.arch] and support_os[jit.os] then
        local ins = setmetatable({}, _M)
        ins._dir = "/tmp/ffi_gccload"
        ins._incs = {}
        ins._libs = {}
        ins._lib_paths = {}
        ins._srcs = {}
        ins._cflags = {"-shared", "-fPIC", "-O3", "-Wall"}
        ins._cc = support_os[jit.os]
        os.execute("mkdir -p " .. ins._dir)
        math.randomseed(os.time())
        return ins
    else
        print("sorry, not support platform")
        return nil
    end
end

return {
    new = _new
    -- instance has interface
    -- :addIncludePaths(...)
    -- :addLibaryPaths(...)
    -- :addLibraries(...)
    -- :addSourceDef(...)
    -- :loadSourceFiles(...)
    -- :loadSourceString(source_string)
}
