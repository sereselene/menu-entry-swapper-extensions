local Files = require("spec/support/files")

local SOURCE_ROOT = "src"

local function sourceModules()
    local modules = {}
    for _, path in ipairs(Files.List(SOURCE_ROOT)) do
        local modulePath = string.match(path, "^(src/.+)%.lua$")
        if modulePath ~= nil then
            modules[#modules + 1] = modulePath
        end
    end
    return modules
end

describe("modules", function()
    before_each(function()
        stub(_G, "print")
    end)

    after_each(function()
        _G.print:revert()
        _G.PluginShutdown = nil
    end)

    it("finds source modules to check", function()
        assert.is_true(#sourceModules() > 0)
    end)

    for _, modulePath in ipairs(sourceModules()) do
        it(modulePath .. " returns a table, as the client requires", function()
            assert.is_table(require(modulePath))
        end)
    end

    it("main returns a table and defines PluginShutdown", function()
        local main = assert(loadfile("main.lua"))
        assert.is_table(main())
        assert.is_function(_G.PluginShutdown)
        assert.has_no.errors(_G.PluginShutdown)
    end)
end)
