local inputService = game:GetService('UserInputService')
local tweenService = game:GetService('TweenService')
local runService = game:GetService('RunService')
local coreGui = game:GetService('CoreGui')
local textService = game:GetService('TextService')
local httpService = game:GetService('HttpService')

local guiParent = coreGui

local VapeLib = {
    Categories = {},
    Objects = {},
    Modules = {},
    ModuleCallbacks = {},
    Theme = {
        Main = Color3.fromRGB(15, 15, 15),
        Accent = Color3.fromRGB(0, 200, 0),
        Text = Color3.fromRGB(220, 220, 220),
        Font = Enum.Font.SourceSans,
        Tween = TweenInfo.new(0.16, Enum.EasingStyle.Linear)
    }
}

local isfile = isfile or function(file)
    local suc, res = pcall(function() return readfile(file) end)
    return suc and res ~= nil and res ~= ""
end
local makefolder = makefolder or function() end
local isfolder = isfolder or function() return false end

local function saveConfig(folder, name, data)
    if not writefile then return end
    local path = ""
    for _, part in ipairs(folder:split("/")) do
        path = path .. (path == "" and "" or "/") .. part
        if not isfolder(path) then makefolder(path) end
    end
    writefile(folder .. "/" .. name .. ".json", httpService:JSONEncode(data))
end

local function loadConfig(folder, name)
    if not isfile(folder.."/"..name..".json") then return nil end
    local suc, res = pcall(function() return httpService:JSONDecode(readfile(folder.."/"..name..".json")) end)
    return suc and res or nil
end

local function addCorner(parent, radius)
    local corner = Instance.new('UICorner')
    corner.CornerRadius = radius or UDim.new(0, 2)
    corner.Parent = parent
    return corner
end

local tooltipGui
local function createTooltip()
    if tooltipGui then return end
    tooltipGui = Instance.new("ScreenGui")
    tooltipGui.Name = httpService:GenerateGUID(false)
    tooltipGui.DisplayOrder = 999
    tooltipGui.Parent = guiParent
    tooltipGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    tooltipGui.IgnoreGuiInset = true
    tooltipGui.ResetOnSpawn = false
    
    local tooltipFrame = Instance.new("Frame")
    tooltipFrame.Name = "Tooltip"
    tooltipFrame.Size = UDim2.fromOffset(100, 20)
    tooltipFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tooltipFrame.BorderSizePixel = 0
    tooltipFrame.Visible = false
    tooltipFrame.ZIndex = 1000
    tooltipFrame.Parent = tooltipGui
    addCorner(tooltipFrame, UDim.new(0, 4))
    
    local tooltipLabel = Instance.new("TextLabel")
    tooltipLabel.Name = "TextLabel"
    tooltipLabel.Size = UDim2.new(1, -10, 1, 0)
    tooltipLabel.Position = UDim2.fromOffset(5, 0)
    tooltipLabel.BackgroundTransparency = 1
    tooltipLabel.TextColor3 = VapeLib.Theme.Text
    tooltipLabel.TextSize = 13
    tooltipLabel.Font = VapeLib.Theme.Font
    tooltipLabel.TextXAlignment = Enum.TextXAlignment.Left
    tooltipLabel.ZIndex = 1001
    tooltipLabel.Parent = tooltipFrame
    
    runService.RenderStepped:Connect(function()
        if tooltipFrame.Visible then
            local mousePos = inputService:GetMouseLocation()
            tooltipFrame.Position = UDim2.fromOffset(mousePos.X + 15, mousePos.Y + 5)
        end
    end)
end

local function addTooltip(gui, text)
    if not text or text == "" then return end
    createTooltip()
    gui.MouseEnter:Connect(function()
        if not tooltipGui then return end
        local tooltipFrame = tooltipGui:FindFirstChild("Tooltip")
        if not tooltipFrame then return end
        local tooltipLabel = tooltipFrame:FindFirstChild("TextLabel")
        if not tooltipLabel then return end
        
        tooltipLabel.Text = text
        local textSize = textService:GetTextSize(text, 13, VapeLib.Theme.Font, Vector2.new(300, 1000))
        tooltipFrame.Size = UDim2.fromOffset(textSize.X + 10, textSize.Y + 6)
        tooltipFrame.Visible = true
    end)
    gui.MouseLeave:Connect(function()
        if tooltipGui and tooltipGui:FindFirstChild("Tooltip") then 
            tooltipGui.Tooltip.Visible = false 
        end
    end)
end

local function makeDraggable(gui, dragPart, connections)
    local dragging
    local dragInput
    local dragStart
    local startPos

    dragPart.InputBegan:Connect(function(input)
        if not dragPart.Active then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragPart.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    local con = inputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    if connections then table.insert(connections, con) end
end

function VapeLib:CreateWindow()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = httpService:GenerateGUID(false)
    screenGui.Parent = guiParent
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false

    local configFolder = "GrassClient/games"
    local configName = tostring(game.PlaceId)

    local mainApi = {
        ScreenGui = screenGui,
        Categories = {},
        Keybind = Enum.KeyCode.RightShift,
        AccentElements = {},
        Config = loadConfig(configFolder, configName) or {Windows = {}, Modules = {}, GUISettings = {}},
        ModulesEnabled = {},
        Keybinds = {},
        Connections = {}
    }

    local function connect(signal, callback)
        local con = signal:Connect(callback)
        table.insert(mainApi.Connections, con)
        return con
    end

    connect(inputService.InputBegan, function(input, gpe)
        if gpe then return end
        if mainApi.Keybind ~= nil and input.KeyCode == mainApi.Keybind then
            screenGui.Enabled = not screenGui.Enabled
        end
        
        for modName, bind in pairs(mainApi.Keybinds) do
            if input.KeyCode == bind then
                local modData = VapeLib.Modules[modName]
                if modData and modData.ToggleState then
                    modData.ToggleState(not mainApi.ModulesEnabled[modName])
                end
            end
        end
    end)

    local arrayGui = Instance.new("ScreenGui")
    arrayGui.Name = httpService:GenerateGUID(false)
    arrayGui.DisplayOrder = 500
    arrayGui.Parent = guiParent
    arrayGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    arrayGui.Enabled = false
    arrayGui.IgnoreGuiInset = true
    arrayGui.ResetOnSpawn = false

    local arrayContainer = Instance.new("Frame")
    arrayContainer.Name = "Arraylist"
    arrayContainer.Size = UDim2.fromOffset(200, 30)
    local savedArrayPos = mainApi.Config.Windows["Arraylist"]
    if savedArrayPos then
        arrayContainer.Position = UDim2.fromOffset(savedArrayPos.X, savedArrayPos.Y)
    else
        arrayContainer.Position = UDim2.new(1, -210, 0, 10)
    end
    arrayContainer.BackgroundTransparency = 1
    arrayContainer.Parent = arrayGui

    local arrayHeader = Instance.new("Frame")
    arrayHeader.Name = "Header"
    arrayHeader.Size = UDim2.new(1, 0, 0, 30)
    arrayHeader.BackgroundTransparency = 1
    arrayHeader.Parent = arrayContainer

    local arrayTitle = Instance.new("TextLabel")
    arrayTitle.Name = "000_Title"
    arrayTitle.Size = UDim2.new(1, 0, 1, 0)
    arrayTitle.BackgroundTransparency = 1
    arrayTitle.Text = "Grass Client"
    arrayTitle.TextColor3 = VapeLib.Theme.Accent
    arrayTitle.TextSize = 20
    arrayTitle.Font = Enum.Font.SourceSansBold
    arrayTitle.TextXAlignment = Enum.TextXAlignment.Right
    arrayTitle.Parent = arrayHeader
    table.insert(mainApi.AccentElements, arrayTitle)

    local pinBtn = Instance.new("ImageButton")
    pinBtn.Name = "Pin"
    pinBtn.Size = UDim2.fromOffset(16, 16)
    pinBtn.Position = UDim2.new(1, -25, 0.5, -8)
    pinBtn.BackgroundTransparency = 1
    pinBtn.Image = "rbxassetid://14406214596"
    pinBtn.ImageColor3 = VapeLib.Theme.Text
    pinBtn.Visible = false
    pinBtn.Parent = arrayHeader

    local pinned = mainApi.Config.PinnedArray or false
    local function updatePin()
        pinBtn.ImageColor3 = pinned and VapeLib.Theme.Accent or VapeLib.Theme.Text
        arrayHeader.Active = not pinned
    end
    
    pinBtn.MouseButton1Click:Connect(function()
        pinned = not pinned
        mainApi.Config.PinnedArray = pinned
        saveConfig("GrassClient", "config", mainApi.Config)
        updatePin()
    end)

    makeDraggable(arrayContainer, arrayHeader, mainApi.Connections)
    updatePin()

    arrayContainer.MouseEnter:Connect(function()
        pinBtn.Visible = true
    end)
    arrayContainer.MouseLeave:Connect(function()
        pinBtn.Visible = false
    end)

    arrayContainer:GetPropertyChangedSignal("Position"):Connect(function()
        if not pinned then
            mainApi.Config.Windows["Arraylist"] = {X = arrayContainer.AbsolutePosition.X, Y = arrayContainer.AbsolutePosition.Y}
            saveConfig("GrassClient", "config", mainApi.Config)
        end
    end)

    local arrayListEnabled = true
    arrayGui.Enabled = arrayListEnabled

    local arrayContent = Instance.new("Frame")
    arrayContent.Name = "Content"
    arrayContent.Size = UDim2.new(1, 0, 0, 0)
    arrayContent.Position = UDim2.fromOffset(0, 30)
    arrayContent.BackgroundTransparency = 1
    arrayContent.Parent = arrayContainer

    local arrayLayout = Instance.new("UIListLayout")
    arrayLayout.Parent = arrayContent
    arrayLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    arrayLayout.SortOrder = Enum.SortOrder.Name

    arrayLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        arrayContent.Size = UDim2.new(1, 0, 0, arrayLayout.AbsoluteContentSize.Y)
        arrayContainer.Size = UDim2.fromOffset(200, 30 + arrayLayout.AbsoluteContentSize.Y)
    end)

    function mainApi:UpdateArrayList()
        for _, child in pairs(arrayContent:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        local enabledList = {}
        for modName, modData in pairs(VapeLib.Modules) do
            if mainApi.ModulesEnabled[modName] then
                table.insert(enabledList, modName)
            end
        end
        table.sort(enabledList)

        for _, modName in ipairs(enabledList) do
            local label = Instance.new("TextLabel")
            label.Name = modName
            label.Size = UDim2.new(1, 0, 0, 20)
            label.BackgroundTransparency = 1
            label.Text = modName .. "  "
            label.TextColor3 = VapeLib.Theme.Accent
            label.TextSize = 16
            label.Font = VapeLib.Theme.Font
            label.TextXAlignment = Enum.TextXAlignment.Right
            label.Parent = arrayContent
            table.insert(self.AccentElements, label)
        end
    end

    local notifyGui = Instance.new("ScreenGui")
    notifyGui.Name = httpService:GenerateGUID(false)
    notifyGui.DisplayOrder = 1000
    notifyGui.Parent = guiParent
    notifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    notifyGui.IgnoreGuiInset = true
    notifyGui.ResetOnSpawn = false

    local notifyContainer = Instance.new("Frame")
    notifyContainer.Name = "Notifications"
    notifyContainer.Size = UDim2.new(0, 300, 1, 0)
    notifyContainer.Position = UDim2.new(1, -310, 0, 0)
    notifyContainer.BackgroundTransparency = 1
    notifyContainer.Parent = notifyGui
    
    local notifyLayout = Instance.new("UIListLayout")
    notifyLayout.Parent = notifyContainer
    notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifyLayout.Padding = UDim.new(0, 10)

    function mainApi:Notify(nOptions)
        local title = nOptions.Title or "Notification"
        local desc = nOptions.Description or ""
        local duration = tonumber(nOptions.Duration) or 5

        local nFrame = Instance.new("Frame")
        nFrame.Size = UDim2.new(1, 0, 0, 60)
        nFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        nFrame.BackgroundTransparency = 0.1
        nFrame.BorderSizePixel = 0
        nFrame.ClipsDescendants = false
        nFrame.Parent = notifyContainer
        addCorner(nFrame)

        local nTitle = Instance.new("TextLabel")
        nTitle.Size = UDim2.new(1, -20, 0, 20)
        nTitle.Position = UDim2.fromOffset(10, 5)
        nTitle.BackgroundTransparency = 1
        nTitle.Text = title
        nTitle.TextColor3 = VapeLib.Theme.Accent
        nTitle.TextSize = 15
        nTitle.Font = Enum.Font.SourceSansBold
        nTitle.TextXAlignment = Enum.TextXAlignment.Left
        nTitle.Parent = nFrame
        table.insert(self.AccentElements, nTitle)

        local nDesc = Instance.new("TextLabel")
        nDesc.Size = UDim2.new(1, -20, 0, 30)
        nDesc.Position = UDim2.fromOffset(10, 25)
        nDesc.BackgroundTransparency = 1
        nDesc.Text = desc
        nDesc.TextColor3 = VapeLib.Theme.Text
        nDesc.TextSize = 14
        nDesc.Font = VapeLib.Theme.Font
        nDesc.TextXAlignment = Enum.TextXAlignment.Left
        nDesc.TextWrapped = true
        nDesc.Parent = nFrame

        local nProgress = Instance.new("Frame")
        nProgress.Size = UDim2.new(1, 0, 0, 2)
        nProgress.Position = UDim2.new(0, 0, 1, -2)
        nProgress.BackgroundColor3 = VapeLib.Theme.Accent
        nProgress.BorderSizePixel = 0
        nProgress.Parent = nFrame
        table.insert(self.AccentElements, nProgress)

        nFrame.Position = UDim2.new(1.2, 0, 0, 0)
        tweenService:Create(nFrame, VapeLib.Theme.Tween, {Position = UDim2.new(0, 0, 0, 0)}):Play()
        tweenService:Create(nProgress, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()

        task.delay(duration, function()
            if not nFrame.Parent then return end
            tweenService:Create(nFrame, VapeLib.Theme.Tween, {Position = UDim2.new(1.2, 0, 0, 0)}):Play()
            task.wait(0.2)
            nFrame:Destroy()
        end)
    end

    function mainApi:UpdateAccent(color)
        VapeLib.Theme.Accent = color
        for _, data in pairs(self.AccentElements) do
            local element = typeof(data) == "Instance" and data or data.Instance
            if not element then continue end
            
            local shouldUpdate = true
            if typeof(data) == "table" and data.GetEnabled then
                shouldUpdate = data.GetEnabled()
            end

            if element:IsA("Frame") or element:IsA("TextButton") then
                element.BackgroundColor3 = shouldUpdate and color or (element:IsA("TextButton") and VapeLib.Theme.Main or Color3.fromRGB(45, 44, 45))
            elseif element:IsA("TextLabel") or element:IsA("TextBox") then
                element.TextColor3 = shouldUpdate and color or VapeLib.Theme.Text
            elseif element:IsA("ImageLabel") or element:IsA("ImageButton") then
                element.ImageColor3 = shouldUpdate and color or VapeLib.Theme.Text
            end
        end
    end

    local function createCategory(catName, index)
        local window = Instance.new("Frame")
        window.Name = catName .. "Window"
        window.Size = UDim2.fromOffset(200, 40)
        local savedPos = mainApi.Config.Windows[catName]
        if savedPos then
            window.Position = UDim2.fromOffset(savedPos.X, savedPos.Y)
        else
            window.Position = UDim2.fromOffset(50 + ((index - 1) * 220), 50)
        end
        window.BackgroundColor3 = VapeLib.Theme.Main
        window.BorderSizePixel = 0
        window.Visible = true
        window.ClipsDescendants = false
        window.Parent = screenGui
        addCorner(window)

        local header = Instance.new("Frame")
        header.Name = "Header"
        header.Size = UDim2.new(1, 0, 0, 40)
        header.BackgroundTransparency = 1
        header.Active = true
        header.Parent = window
        makeDraggable(window, header, mainApi.Connections)

        window:GetPropertyChangedSignal("Position"):Connect(function()
            mainApi.Config.Windows[catName] = {X = window.AbsolutePosition.X, Y = window.AbsolutePosition.Y}
            saveConfig("GrassClient", "config", mainApi.Config)
        end)

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -40, 1, 0)
        title.Position = UDim2.fromOffset(40, 0)
        title.BackgroundTransparency = 1
        title.Text = catName
        title.TextColor3 = VapeLib.Theme.Text
        title.TextSize = 17
        title.Font = Enum.Font.SourceSansBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = header

        local container = Instance.new("Frame")
        container.Name = "Container"
        container.Size = UDim2.new(1, 0, 0, 0)
        container.Position = UDim2.fromOffset(0, 40)
        container.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
        container.BorderSizePixel = 0
        container.ClipsDescendants = true
        container.Parent = window
        addCorner(container)

        local containerLayout = Instance.new("UIListLayout")
        containerLayout.Parent = container
        containerLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local windowExpanded = true
        containerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if windowExpanded then
                container.Size = UDim2.new(1, 0, 0, containerLayout.AbsoluteContentSize.Y)
                window.Size = UDim2.new(0, 200, 0, 40 + containerLayout.AbsoluteContentSize.Y)
            end
        end)

        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                windowExpanded = not windowExpanded
                local contentHeight = containerLayout.AbsoluteContentSize.Y
                tweenService:Create(window, VapeLib.Theme.Tween, {
                    Size = UDim2.new(0, 200, 0, windowExpanded and (40 + contentHeight) or 40)
                }):Play()
                tweenService:Create(container, VapeLib.Theme.Tween, {
                    Size = UDim2.new(1, 0, 0, windowExpanded and contentHeight or 0)
                }):Play()
            end
        end)

        local catApi = {
            Window = window,
            Modules = {}
        }

        function catApi:CreateModule(modOptions)
            modOptions = modOptions or {}
            local modName = modOptions.Name or "Module"
            local callback = modOptions.Function or function() end
            local tooltip = modOptions.Tooltip or ""

            local modFrame = Instance.new("TextButton")
            modFrame.Name = modName .. "Module"
            modFrame.Size = UDim2.new(1, 0, 0, 35)
            modFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
            modFrame.AutoButtonColor = false
            modFrame.BorderSizePixel = 0
            modFrame.Text = ""
            modFrame.Parent = container
            addTooltip(modFrame, tooltip)

            local divider = Instance.new("Frame")
            divider.Name = "Divider"
            divider.Size = UDim2.new(1, -20, 0, 1)
            divider.Position = UDim2.fromOffset(10, 0)
            divider.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            divider.BorderSizePixel = 0
            divider.Parent = container

            local modTitle = Instance.new("TextLabel")
            modTitle.Name = "Title"
            modTitle.Size = UDim2.new(1, -40, 1, 0)
            modTitle.Position = UDim2.fromOffset(10, 0)
            modTitle.BackgroundTransparency = 1
            modTitle.Text = modName
            modTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            modTitle.TextSize = 14
            modTitle.Font = Enum.Font.GothamBold
            modTitle.TextXAlignment = Enum.TextXAlignment.Left
            modTitle.Parent = modFrame

            local expandIcon = Instance.new("TextLabel")
            expandIcon.Name = "Expand"
            expandIcon.Size = UDim2.fromOffset(20, 20)
            expandIcon.Position = UDim2.new(1, -25, 0.5, -10)
            expandIcon.BackgroundTransparency = 1
            expandIcon.Text = "+"
            expandIcon.TextColor3 = VapeLib.Theme.Text
            expandIcon.TextSize = 18
            expandIcon.Font = Enum.Font.SourceSansBold
            expandIcon.Parent = modFrame

            local settingsFrame = Instance.new("Frame")
            settingsFrame.Name = "Settings"
            settingsFrame.Size = UDim2.new(1, 0, 0, 0)
            settingsFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
            settingsFrame.BorderSizePixel = 0
            settingsFrame.ClipsDescendants = true
            settingsFrame.Parent = container

            local settingsLayout = Instance.new("UIListLayout")
            settingsLayout.Parent = settingsFrame
            settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder

            settingsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if settingsFrame.Size.Y.Offset > 0 then
                    settingsFrame.Size = UDim2.new(1, 0, 0, settingsLayout.AbsoluteContentSize.Y)
                end
            end)

            local enabled = false
            local expanded = false
            local binding = false
            local currentBind = nil

            local modApi = {}
            modApi.Enabled = false

            local function toggle(state, skipSave)
                enabled = state
                modApi.Enabled = state
                modFrame.BackgroundColor3 = enabled and VapeLib.Theme.Accent or Color3.fromRGB(18, 18, 18)
                mainApi.ModulesEnabled[modName] = enabled
                mainApi:UpdateArrayList()
                task.spawn(callback, enabled, modApi)
                if not skipSave then
                    mainApi.Config.Modules[modName] = mainApi.Config.Modules[modName] or {}
                    mainApi.Config.Modules[modName].Enabled = enabled
                    saveConfig(configFolder, configName, mainApi.Config)
                end
            end
            function modApi:Toggle(state, skipSave)
                return toggle(state, skipSave)
            end

            local bindBtn = Instance.new("TextButton")
            bindBtn.Name = "Keybind"
            bindBtn.Size = UDim2.fromOffset(40, 20)
            bindBtn.Position = UDim2.new(1, -70, 0.5, -10)
            bindBtn.BackgroundTransparency = 1
            bindBtn.Text = "[NONE]"
            bindBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
            bindBtn.TextSize = 13
            bindBtn.Font = VapeLib.Theme.Font
            bindBtn.TextXAlignment = Enum.TextXAlignment.Right
            bindBtn.Parent = modFrame

            local function setBind(key, skipSave)
                currentBind = key
                bindBtn.Text = key == nil and "[NONE]" or "["..key.Name:upper().."]"
                mainApi.Keybinds[modName] = key
                if not skipSave then
                    mainApi.Config.Modules[modName] = mainApi.Config.Modules[modName] or {}
                    mainApi.Config.Modules[modName].Keybind = key and key.Name or nil
                    saveConfig(configFolder, configName, mainApi.Config)
                end
            end

            bindBtn.MouseButton1Click:Connect(function()
                binding = true
                bindBtn.Text = "[...]"
                local connection
                connection = inputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        binding = false
                        connection:Disconnect()
                        if input.KeyCode == Enum.KeyCode.Escape then
                            setBind(nil)
                        else
                            setBind(input.KeyCode)
                        end
                    end
                end)
            end)

            VapeLib.Modules[modName] = {
                Object = modFrame,
                CategoryWindow = window,
                ToggleState = toggle
            }

            modFrame.MouseButton1Click:Connect(function()
                if not binding then
                    toggle(not enabled)
                end
            end)

            if mainApi.Config.Modules[modName] then
                if mainApi.Config.Modules[modName].Enabled then
                    toggle(true, true)
                end
                if mainApi.Config.Modules[modName].Keybind then
                    local suc, res = pcall(function() return Enum.KeyCode[mainApi.Config.Modules[modName].Keybind] end)
                    if suc then setBind(res, true) end
                end
            end

            table.insert(mainApi.AccentElements, {
                Instance = modFrame,
                GetEnabled = function() return enabled end
            })

            modFrame.MouseButton2Click:Connect(function()
                expanded = not expanded
                expandIcon.Text = expanded and "-" or "+"
                tweenService:Create(settingsFrame, VapeLib.Theme.Tween, {
                    Size = UDim2.new(1, 0, 0, expanded and settingsLayout.AbsoluteContentSize.Y or 0)
                }):Play()
            end)

            function modApi:CreateToggle(tOptions)
                tOptions = tOptions or {}
                local tName = tOptions.Name or "Toggle"
                local tDefault = tOptions.Default or false
                local tCallback = tOptions.Function or function() end
                local tTooltip = tOptions.Tooltip or ""
                local tEnabled = tDefault

                local tFrame = Instance.new("TextButton")
                tFrame.Size = UDim2.new(1, 0, 0, 30)
                tFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                tFrame.AutoButtonColor = false
                tFrame.Text = ""
                tFrame.Parent = settingsFrame
                addTooltip(tFrame, tTooltip)

                local tTitle = Instance.new("TextLabel")
                tTitle.Size = UDim2.new(1, -40, 1, 0)
                tTitle.Position = UDim2.fromOffset(20, 0)
                tTitle.BackgroundTransparency = 1
                tTitle.Text = tName
                tTitle.TextColor3 = VapeLib.Theme.Text
                tTitle.TextSize = 14
                tTitle.Font = VapeLib.Theme.Font
                tTitle.TextXAlignment = Enum.TextXAlignment.Left
                tTitle.Parent = tFrame

                local tStatus = Instance.new("Frame")
                tStatus.Size = UDim2.fromOffset(12, 12)
                tStatus.Position = UDim2.new(1, -25, 0.5, -6)
                tStatus.BackgroundColor3 = Color3.fromRGB(45, 44, 45)
                tStatus.Parent = tFrame
                addCorner(tStatus, UDim.new(0, 3))

                local function tToggle(state, skipSave)
                    tEnabled = state
                    tStatus.BackgroundColor3 = tEnabled and VapeLib.Theme.Accent or Color3.fromRGB(45, 44, 45)
                    task.spawn(tCallback, tEnabled)
                    if not skipSave then
                        mainApi.Config.Modules[modName] = mainApi.Config.Modules[modName] or {}
                        mainApi.Config.Modules[modName][tName] = tEnabled
                        saveConfig(configFolder, configName, mainApi.Config)
                    end
                end

                tFrame.MouseButton1Click:Connect(function()
                    tToggle(not tEnabled)
                end)

                if mainApi.Config.Modules[modName] and mainApi.Config.Modules[modName][tName] then
                    tToggle(mainApi.Config.Modules[modName][tName], true)
                end

                table.insert(mainApi.AccentElements, {
                    Instance = tStatus,
                    GetEnabled = function() return tEnabled end
                })

                return {
                    Toggle = tToggle,
                    Enabled = function() return tEnabled end
                }
            end

            function modApi:CreateSlider(sOptions)
                sOptions = sOptions or {}
                local sName = sOptions.Name or "Slider"
                local sMin = sOptions.Min or 0
                local sMax = sOptions.Max or 100
                local sDefault = sOptions.Default or 50
                local sCallback = sOptions.Function or function() end
                local sTooltip = sOptions.Tooltip or ""
                local sValue = sDefault

                local sFrame = Instance.new("Frame")
                sFrame.Size = UDim2.new(1, 0, 0, 45)
                sFrame.BackgroundTransparency = 1
                sFrame.Parent = settingsFrame
                addTooltip(sFrame, sTooltip)

                local sTitle = Instance.new("TextLabel")
                sTitle.Size = UDim2.new(1, -20, 0, 20)
                sTitle.Position = UDim2.fromOffset(20, 5)
                sTitle.BackgroundTransparency = 1
                sTitle.Text = sName .. ": " .. sValue
                sTitle.TextColor3 = VapeLib.Theme.Text
                sTitle.TextSize = 14
                sTitle.Font = VapeLib.Theme.Font
                sTitle.TextXAlignment = Enum.TextXAlignment.Left
                sTitle.Parent = sFrame

                local sBkg = Instance.new("Frame")
                sBkg.Size = UDim2.new(1, -40, 0, 4)
                sBkg.Position = UDim2.fromOffset(20, 30)
                sBkg.BackgroundColor3 = Color3.fromRGB(45, 44, 45)
                sBkg.Parent = sFrame
                addCorner(sBkg)

                local sFill = Instance.new("Frame")
                local percent = (sValue - sMin) / (sMax - sMin)
                sFill.Size = UDim2.fromScale(percent, 1)
                sFill.BackgroundColor3 = VapeLib.Theme.Accent
                sFill.Parent = sBkg
                addCorner(sFill)
                table.insert(mainApi.AccentElements, sFill)

                local function sSetValue(value, skipSave)
                    sValue = math.clamp(value, sMin, sMax)
                    local newPercent = (sValue - sMin) / (sMax - sMin)
                    sFill.Size = UDim2.fromScale(newPercent, 1)
                    sTitle.Text = sName .. ": " .. sValue
                    task.spawn(sCallback, sValue)
                    if not skipSave then
                        mainApi.Config.Modules[modName] = mainApi.Config.Modules[modName] or {}
                        mainApi.Config.Modules[modName][sName] = sValue
                        saveConfig(configFolder, configName, mainApi.Config)
                    end
                end

                connect(sBkg.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local move = connect(inputService.InputChanged, function(input)
                            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                                local percent = math.clamp((input.Position.X - sBkg.AbsolutePosition.X) / sBkg.AbsoluteSize.X, 0, 1)
                                sSetValue(sMin + (percent * (sMax - sMin)))
                            end
                        end)
                        local endCon
                        endCon = connect(inputService.InputEnded, function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                move:Disconnect()
                                endCon:Disconnect()
                            end
                        end)
                        local percent = math.clamp((input.Position.X - sBkg.AbsolutePosition.X) / sBkg.AbsoluteSize.X, 0, 1)
                        sSetValue(sMin + (percent * (sMax - sMin)))
                    end
                end)

                if mainApi.Config.Modules[modName] and mainApi.Config.Modules[modName][sName] then
                    sSetValue(mainApi.Config.Modules[modName][sName], true)
                end

                return {
                    SetValue = sSetValue,
                    GetValue = function() return sValue end
                }
            end

            function modApi:CreateDropdown(dOptions)
                dOptions = dOptions or {}
                local dName = dOptions.Name or "Dropdown"
                local dList = dOptions.List or {}
                local dDefault = dOptions.Default or dList[1]
                local dCallback = dOptions.Function or function() end
                local dTooltip = dOptions.Tooltip or ""
                local selected = dDefault

                local dFrame = Instance.new("TextButton")
                dFrame.Size = UDim2.new(1, 0, 0, 30)
                dFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                dFrame.AutoButtonColor = false
                dFrame.Text = ""
                dFrame.Parent = settingsFrame
                addTooltip(dFrame, dTooltip)

                local dTitle = Instance.new("TextLabel")
                dTitle.Size = UDim2.new(1, -40, 1, 0)
                dTitle.Position = UDim2.fromOffset(20, 0)
                dTitle.BackgroundTransparency = 1
                dTitle.Text = dName .. ": " .. selected
                dTitle.TextColor3 = VapeLib.Theme.Text
                dTitle.TextSize = 14
                dTitle.Font = VapeLib.Theme.Font
                dTitle.TextXAlignment = Enum.TextXAlignment.Left
                dTitle.Parent = dFrame

                local dArrow = Instance.new("TextLabel")
                dArrow.Size = UDim2.fromOffset(20, 20)
                dArrow.Position = UDim2.new(1, -25, 0.5, -10)
                dArrow.BackgroundTransparency = 1
                dArrow.Text = "▼"
                dArrow.TextColor3 = VapeLib.Theme.Text
                dArrow.TextSize = 12
                dArrow.Font = VapeLib.Theme.Font
                dArrow.Parent = dFrame

                local dDropdown = Instance.new("Frame")
                dDropdown.Size = UDim2.new(1, 0, 0, 0)
                dDropdown.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                dDropdown.BorderSizePixel = 0
                dDropdown.ClipsDescendants = true
                dDropdown.Parent = settingsFrame
                addCorner(dDropdown)

                local dLayout = Instance.new("UIListLayout")
                dLayout.Parent = dDropdown
                dLayout.SortOrder = Enum.SortOrder.LayoutOrder

                local dExpanded = false
                dLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    if dExpanded then
                        dDropdown.Size = UDim2.new(1, 0, 0, dLayout.AbsoluteContentSize.Y)
                    end
                end)

                local function dSelect(value, skipSave)
                    selected = value
                    dTitle.Text = dName .. ": " .. selected
                    dExpanded = false
                    tweenService:Create(dDropdown, VapeLib.Theme.Tween, {
                        Size = UDim2.new(1, 0, 0, 0)
                    }):Play()
                    task.spawn(dCallback, selected)
                    if not skipSave then
                        mainApi.Config.Modules[modName] = mainApi.Config.Modules[modName] or {}
                        mainApi.Config.Modules[modName][dName] = selected
                        saveConfig(configFolder, configName, mainApi.Config)
                    end
                end

                dFrame.MouseButton1Click:Connect(function()
                    dExpanded = not dExpanded
                    if dExpanded then
                        for _, option in pairs(dDropdown:GetChildren()) do
                            if option:IsA("TextButton") then option:Destroy() end
                        end
                        for _, option in ipairs(dList) do
                            local optBtn = Instance.new("TextButton")
                            optBtn.Size = UDim2.new(1, 0, 0, 25)
                            optBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                            optBtn.AutoButtonColor = false
                            optBtn.BorderSizePixel = 0
                            optBtn.Text = option
                            optBtn.TextColor3 = VapeLib.Theme.Text
                            optBtn.TextSize = 14
                            optBtn.Font = VapeLib.Theme.Font
                            optBtn.Parent = dDropdown
                            
                            optBtn.MouseButton1Click:Connect(function()
                                dSelect(option)
                            end)
                        end
                        tweenService:Create(dDropdown, VapeLib.Theme.Tween, {
                            Size = UDim2.new(1, 0, 0, dLayout.AbsoluteContentSize.Y)
                        }):Play()
                    else
                        tweenService:Create(dDropdown, VapeLib.Theme.Tween, {
                            Size = UDim2.new(1, 0, 0, 0)
                        }):Play()
                    end
                end)

                if mainApi.Config.Modules[modName] and mainApi.Config.Modules[modName][dName] then
                    dSelect(mainApi.Config.Modules[modName][dName], true)
                end

                return {
                    Select = dSelect,
                    GetValue = function() return selected end
                }
            end

            return modApi
        end

        mainApi.Categories[catName] = catApi
        mainApi.Categories[catName:lower()] = catApi
        return catApi
    end

    local categoryNames = {"Combat", "Blatant", "Utility", "Render", "World"}
    for i, catName in ipairs(categoryNames) do
        createCategory(catName, i)
    end

    VapeLib.Categories = mainApi.Categories
    VapeLib.Notify = function(...)
        return mainApi:Notify(...)
    end
    VapeLib.UpdateArrayList = function(...)
        return mainApi:UpdateArrayList(...)
    end

    return mainApi
end

return VapeLib
