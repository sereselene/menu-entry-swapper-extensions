local Files = require("spec/support/files")

local SCANNED_FOLDERS = { "src", "spec", "scripts", ".githooks", ".github" }
local SCANNED_FILES = { "main.lua", "plugin.json", ".luacheckrc", ".busted" }
local LUA_FILES = { [".luacheckrc"] = true, [".busted"] = true }
local MAXIMUM_LINE_LENGTH = 200
local BINARY_EXTENSIONS = { png = true }

local function extensionOf(path)
    return string.match(path, "%.([%w]+)$") or ""
end

local function skipQuoted(source, start, quote)
    local position = start + 1
    while position <= #source do
        local character = string.sub(source, position, position)
        if character == "\\" then
            position = position + 2
        elseif character == quote or character == "\n" then
            return position + 1
        else
            position = position + 1
        end
    end
    return position
end

local function luaCommentOffset(source)
    local position = 1
    while position <= #source do
        local character = string.sub(source, position, position)
        if character == "-" and string.sub(source, position + 1, position + 1) == "-" then
            return position
        end
        if character == '"' or character == "'" then
            position = skipQuoted(source, position, character)
        elseif character == "[" and string.match(source, "^%[=*%[", position) then
            local equals = string.match(source, "^%[(=*)%[", position)
            local closing = "]" .. equals .. "]"
            local finish = string.find(source, closing, position + #equals + 2, true)
            position = finish and (finish + #closing) or (#source + 1)
        else
            position = position + 1
        end
    end
    return nil
end

local function isShell(path)
    return extensionOf(path) == "sh" or string.find(path, "^%.githooks/") ~= nil
end

local function lineNumberAt(source, offset)
    local _, newlines = string.gsub(string.sub(source, 1, offset), "\n", "")
    return newlines + 1
end

local function scannedPaths()
    local paths = {}
    for _, folder in ipairs(SCANNED_FOLDERS) do
        for _, path in ipairs(Files.List(folder)) do
            if not BINARY_EXTENSIONS[extensionOf(path)] then
                paths[#paths + 1] = path
            end
        end
    end
    for _, path in ipairs(SCANNED_FILES) do
        paths[#paths + 1] = path
    end
    return paths
end

local function findings()
    local found = {
        comments = {},
        nonAscii = {},
        longLines = {},
        scanned = 0,
        scannedLua = {},
        scannedShell = {},
    }
    for _, path in ipairs(scannedPaths()) do
        found.scanned = found.scanned + 1
        local source = Files.ReadWhole(path)
        local badByte = string.find(source, "[\128-\255]")
        if badByte then
            found.nonAscii[#found.nonAscii + 1] = path .. ":" .. lineNumberAt(source, badByte)
        end
        if isShell(path) then
            found.scannedShell[path] = true
        end
        local lineNumber = 0
        for line in string.gmatch(source .. "\n", "([^\n]*)\n") do
            lineNumber = lineNumber + 1
            if #line > MAXIMUM_LINE_LENGTH then
                found.longLines[#found.longLines + 1] = path .. ":" .. lineNumber
            end
            if isShell(path) and lineNumber > 1 and string.match(line, "^%s*#") then
                found.comments[#found.comments + 1] = path .. ":" .. lineNumber
            end
        end
        if extensionOf(path) == "lua" or LUA_FILES[path] then
            found.scannedLua[path] = true
            local offset = luaCommentOffset(source)
            if offset then
                found.comments[#found.comments + 1] = path .. ":" .. lineNumberAt(source, offset)
            end
        end
    end
    return found
end

describe("standards", function()
    local found

    setup(function()
        found = findings()
    end)

    it("scans files", function()
        assert.is_true(found.scanned > 0)
    end)

    it("scans the Luacheck and Busted configs as Lua", function()
        assert.is_true(found.scannedLua[".luacheckrc"])
        assert.is_true(found.scannedLua[".busted"])
    end)

    it("has no comments", function()
        assert.are.same({}, found.comments)
    end)

    it("has no non ASCII bytes", function()
        assert.are.same({}, found.nonAscii)
    end)

    it("has no line over 200 characters", function()
        assert.are.same({}, found.longLines)
    end)

    it("scans the shell scripts and hooks", function()
        assert.is_true(found.scannedShell[".githooks/pre-commit"])
        assert.is_true(found.scannedShell["scripts/setup.sh"])
    end)

    it("finds a real comment", function()
        assert.is_not_nil(luaCommentOffset("local value = 1 -" .. "- note"))
    end)

    it("ignores dashes inside strings", function()
        assert.is_nil(luaCommentOffset('local value = "a -' .. '- b" .. [[c -' .. "- d]]"))
    end)
end)
