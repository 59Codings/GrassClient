local function loadGrassClient(config)
    config = config or {}
    
    local success, baseScript = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/59Codings/GrassClient/refs/heads/main/grass/base.lua")
    end)
    
    if not success then
        warn("Failed to download base.lua")
        return
    end
    
    local loaded, grassBase = pcall(function()
        return loadstring(baseScript)(config)
    end)
    
    if not loaded then
        warn("Failed to load base.lua")
        return
    end
    
    return grassBase
end

return loadGrassClient
