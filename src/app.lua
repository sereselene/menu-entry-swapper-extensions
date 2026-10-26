local Client = require("src/core/client")

local App = {}

function App.Start()
    if prettyui == nil then
        Client.Warn("dependencies", "needs PrettyUI enabled")
    end
end

function App.Shutdown() end

return App
