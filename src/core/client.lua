local PluginDetails = require("src/plugin")

local Client = {}

local PREFIX = PluginDetails.NAME .. ": "

local warnedKeys = {}

function Client.Warn(key, message)
    if warnedKeys[key] then
        return
    end
    warnedKeys[key] = true
    print(PREFIX .. message)
end

function Client.Call(label, action, ...)
    local results = table.pack(pcall(action, ...))
    if not results[1] then
        Client.Warn(label, label .. " failed: " .. tostring(results[2]))
        return nil
    end
    return table.unpack(results, 2, results.n)
end

function Client.Subscribe(eventName, key, callback)
    return Client.Call("subscribing to " .. eventName, function()
        Event[eventName].Subscribe(key, callback)
        return true
    end) == true
end

function Client.Unsubscribe(eventName, key)
    Client.Call("unsubscribing from " .. eventName, function()
        Event[eventName].Unsubscribe(key)
    end)
end

return Client
