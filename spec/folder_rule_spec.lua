local Files = require("spec/support/files")

local SOURCE_ROOT = "src"
local LAYER_ORDER = { "app", "windows", "packs", "swapper", "core", "foundation" }
local ROOT_FILE_LAYERS = { app = "app", plugin = "foundation", state = "foundation" }

local layerRanks = {}
for rank, layer in ipairs(LAYER_ORDER) do
    layerRanks[layer] = rank
end

local function layerOf(modulePath)
    local folder = string.match(modulePath, "^([^/]+)/")
    if folder ~= nil then
        return layerRanks[folder] and folder or nil
    end
    return ROOT_FILE_LAYERS[modulePath]
end

local function upstreamRequires(modulePath, source)
    local ownLayer = layerOf(modulePath)
    local found = {}
    for target in string.gmatch(source, 'require%(%s*"src/([^"]+)"%s*%)') do
        local targetLayer = layerOf(target)
        if targetLayer == nil or layerRanks[targetLayer] < layerRanks[ownLayer] then
            found[#found + 1] = modulePath .. " uses " .. target
        end
    end
    return found
end

local function sourceFiles()
    local found = {}
    for _, path in ipairs(Files.List(SOURCE_ROOT)) do
        local modulePath = string.match(path, "^src/(.+)%.lua$")
        if modulePath ~= nil then
            found[#found + 1] = { path = path, modulePath = modulePath }
        end
    end
    return found
end

describe("folder rule", function()
    it("finds source files to check", function()
        assert.is_true(#sourceFiles() > 0)
    end)

    it("puts every file in a known folder", function()
        local unplaced = {}
        for _, file in ipairs(sourceFiles()) do
            if layerOf(file.modulePath) == nil then
                unplaced[#unplaced + 1] = file.modulePath
            end
        end
        assert.are.same({}, unplaced)
    end)

    it("never uses anything upstream", function()
        local upstream = {}
        for _, file in ipairs(sourceFiles()) do
            if layerOf(file.modulePath) ~= nil then
                for _, finding in
                    ipairs(upstreamRequires(file.modulePath, Files.ReadWhole(file.path)))
                do
                    upstream[#upstream + 1] = finding
                end
            end
        end
        assert.are.same({}, upstream)
    end)

    it("allows a window to use core", function()
        assert.are.same(
            {},
            upstreamRequires("windows/pack_window", 'local Client = require("src/core/client")')
        )
    end)

    it("catches core using a window", function()
        assert.are.same(
            { "core/client uses windows/pack_window" },
            upstreamRequires("core/client", 'local PackWindow = require("src/windows/pack_window")')
        )
    end)

    it("catches a file in an unknown folder", function()
        assert.are.same(
            { "core/client uses elsewhere/thing" },
            upstreamRequires("core/client", 'local Thing = require("src/elsewhere/thing")')
        )
    end)
end)
