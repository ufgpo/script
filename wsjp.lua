-- ========================================================
-- STANDALONE WALK SPEED & JUMP POWER EDITOR WITH UI
-- ========================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Remove existing GUI if re-executed
if CoreGui:FindFirstChild("StatEditorUI") then
    CoreGui.StatEditorUI:Destroy()
end

getgenv().WalkSpeed = 16
getgenv().JumpPower = 50
getgenv().ModifyStats = true

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StatEditorUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 160, 0, 95)
MainFrame.Position = UDim2.new(0.5, -80, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.8
MainStroke.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = MainFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0, 8)
UIPadding.PaddingBottom = UDim.new(0, 8)
UIPadding.PaddingLeft = UDim.new(0, 8)
UIPadding.PaddingRight = UDim.new(0, 8)
UIPadding.Parent = MainFrame

-- Speed Input Box
local SpeedBox = Instance.new("TextBox")
SpeedBox.Name = "SpeedBox"
SpeedBox.Size = UDim2.new(1, 0, 0, 32)
SpeedBox.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
SpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedBox.PlaceholderText = "Speed (Default: 16)"
SpeedBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
SpeedBox.Text = ""
SpeedBox.Font = Enum.Font.SourceSans
SpeedBox.TextSize = 13
SpeedBox.LayoutOrder = 1
SpeedBox.Parent = MainFrame

local SpeedCorner = Instance.new("UICorner")
SpeedCorner.CornerRadius = UDim.new(0, 6)
SpeedCorner.Parent = SpeedBox

-- Jump Input Box
local JumpBox = Instance.new("TextBox")
JumpBox.Name = "JumpBox"
JumpBox.Size = UDim2.new(1, 0, 0, 32)
JumpBox.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
JumpBox.TextColor3 = Color3.fromRGB(255, 255, 255)
JumpBox.PlaceholderText = "Jump (Default: 50)"
JumpBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
JumpBox.Text = ""
JumpBox.Font = Enum.Font.SourceSans
JumpBox.TextSize = 13
JumpBox.LayoutOrder = 2
JumpBox.Parent = MainFrame

local JumpCorner = Instance.new("UICorner")
JumpCorner.CornerRadius = UDim.new(0, 6)
JumpCorner.Parent = JumpBox

-- Dragging Mechanism
local dragging = false
local dragInput, dragStart, startPos

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Input Focus Handlers
SpeedBox.FocusLost:Connect(function()
    local val = tonumber(SpeedBox.Text)
    if val then
        getgenv().WalkSpeed = val
    end
end)

JumpBox.FocusLost:Connect(function()
    local val = tonumber(JumpBox.Text)
    if val then
        getgenv().JumpPower = val
    end
end)

-- Background Thread to Maintain Character Stats Across Respawns
task.spawn(function()
    while getgenv().ModifyStats do
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if getgenv().WalkSpeed then
                    humanoid.WalkSpeed = getgenv().WalkSpeed
                end
                if getgenv().JumpPower then
                    humanoid.UseJumpPower = true
                    humanoid.JumpPower = getgenv().JumpPower
                end
            end
        end
        task.wait(0.1)
    end
end)
