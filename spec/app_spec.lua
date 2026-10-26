local function freshApp()
    for name in pairs(package.loaded) do
        if string.find(name, "^src/") then
            package.loaded[name] = nil
        end
    end
    return require("src/app")
end

describe("App", function()
    local App

    before_each(function()
        App = freshApp()
        stub(_G, "print")
    end)

    after_each(function()
        _G.print:revert()
        _G.prettyui = nil
    end)

    it("warns once when PrettyUI is missing", function()
        _G.prettyui = nil
        App.Start()
        App.Start()
        assert.stub(_G.print).was.called(1)
        assert
            .stub(_G.print).was
            .called_with("menu-entry-swapper-extensions: needs PrettyUI enabled")
    end)

    it("stays quiet when PrettyUI is there", function()
        _G.prettyui = {}
        App.Start()
        assert.stub(_G.print).was_not.called()
    end)

    it("shuts down cleanly", function()
        assert.has_no.errors(App.Shutdown)
    end)
end)
