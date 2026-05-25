local httpService = game:GetService("HttpService")
local runService = game:GetService("RunService")

local owner = "59Codings"
local repo = "GrassClient"
local path = "grass"
local branch = "main"
local apiUrl = string.format("https://api.github.com/repos/%s/%s/contents/%s?ref=%s", owner, repo, path, branch)

local function downloadFile(url, filePath)
    local success, response = pcall(function()
        return httpService:RequestAsync({
            Url = url,
            Method = "GET"
        })
    end)
    
    if not success or not response.Success then
        return false
    end
    
    local content = response.Body
    
    if response.Headers["content-type"] and response.Headers["content-type"]:find("application/json") then
        local decoded = httpService:JSONDecode(content)
        if decoded.content then
            content = decoded.content
        end
    end
    
    local dirPath = filePath:match("^(.*)/")
    if dirPath then
        local parts = dirPath:split("/")
        local currentPath = ""
        for _, part in ipairs(parts) do
            currentPath = currentPath .. (currentPath == "" and "" or "/") .. part
            if not isfolder(currentPath) then
                makefolder(currentPath)
            end
        end
    end
    
    writefile(filePath, content)
    return true
end

local function getGitHubFiles()
    local success, response = pcall(function()
        return httpService:RequestAsync({
            Url = apiUrl,
            Method = "GET"
        })
    end)
    
    if not success or not response.Success then
        return {}
    end
    
    local data = httpService:JSONDecode(response.Body)
    local files = {}
    
    if type(data) == "table" then
        for _, item in ipairs(data) do
            if item.type == "file" then
                table.insert(files, {
                    name = item.name,
                    path = "grass/" .. item.name,
                    url = item.download_url
                })
            elseif item.type == "dir" then
                local dirUrl = string.format("https://api.github.com/repos/%s/%s/contents/%s/%s?ref=%s", owner, repo, path, item.name, branch)
                local dirSuccess, dirResponse = pcall(function()
                    return httpService:RequestAsync({
                        Url = dirUrl,
                        Method = "GET"
                    })
                end)
                
                if dirSuccess and dirResponse.Success then
                    local dirData = httpService:JSONDecode(dirResponse.Body)
                    if type(dirData) == "table" then
                        for _, dirItem in ipairs(dirData) do
                            if dirItem.type == "file" then
                                table.insert(files, {
                                    name = dirItem.name,
                                    path = "grass/" .. item.name .. "/" .. dirItem.name,
                                    url = dirItem.download_url
                                })
                            end
                        end
                    end
                end
            end
        end
    end
    
    return files
end

local function verifyFiles(files)
    for _, file in ipairs(files) do
        if not isfile(file.path) then
            return false
        end
    end
    return true
end

local function syncFiles()
    local files = getGitHubFiles()
    
    if #files == 0 then
        return false
    end
    
    for _, file in ipairs(files) do
        downloadFile(file.url, file.path)
    end
    
    return verifyFiles(files)
end

local function loadPlaceScript()
    local placeId = tostring(game.PlaceId)
    local scriptPath = "grass/games/" .. placeId .. ".lua"
    
    if isfile(scriptPath) then
        local func, err = loadfile(scriptPath)
        if func then
            func()
        end
    end
end

local function main()
    if not syncFiles() then
        return
    end
    
    loadPlaceScript()
end

if runService:IsStudio() then
    main()
else
    main()
end
