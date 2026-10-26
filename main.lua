local App = require("src/app")

App.Start()

function PluginShutdown()
    App.Shutdown()
end

return {}
