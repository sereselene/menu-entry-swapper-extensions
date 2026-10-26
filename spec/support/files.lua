local lfs = require("lfs")

local Files = {}

local function collect(folder, found)
    local names = {}
    for name in lfs.dir(folder) do
        if name ~= "." and name ~= ".." then
            names[#names + 1] = name
        end
    end
    table.sort(names)
    for _, name in ipairs(names) do
        local path = folder .. "/" .. name
        if lfs.attributes(path, "mode") == "directory" then
            collect(path, found)
        else
            found[#found + 1] = path
        end
    end
    return found
end

function Files.List(folder)
    if lfs.attributes(folder, "mode") ~= "directory" then
        return {}
    end
    return collect(folder, {})
end

function Files.ReadWhole(path)
    local file = assert(io.open(path, "r"))
    local contents = file:read("a")
    file:close()
    return contents
end

return Files
