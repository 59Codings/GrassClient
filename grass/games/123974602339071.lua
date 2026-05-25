-- Compiled in 39ms
local grass = loadstring(readfile("grass/GrassLib.lua"))()

local replicatedStorage = game:GetService("ReplicatedStorage")
local replicatedFirst = game:GetService("ReplicatedFirst")
local screenGui = game:GetService("ScreenGui")
local players = game:GetService("Players")
local player = players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local rootPart = char:WaitForChild("HumanoidRootPart")

grass:CreateWindow()
local Fly

fly = grass.Categories.Blatant:CreateModule({
    Name = "Fly",
    Function = function(enabled, api)
        print("Fly:", enabled)
    end,
    Tooltip = "Fly"
})

