local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Remove existing GUI if re-executed
if CoreGui:FindFirstChild("MovementUtilityUI") then
    CoreGui.MovementUtilityUI:Destroy()
end

-- Global States & Waypoints
getgenv().Flying = false
getgenv().FlySpeed = 50
getgenv().WalkSpeed = 16
getgenv().JumpPower = 50
getgenv().Gravity = 196.2
getgenv().ModifyStats = true

local waypoint1 = nil
local waypoint2 = nil

-- Retrieve Roblox Master Control Module for Unified Mobile/PC Input
local ControlModule = nil
pcall(function()
    local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts", 3)
    if PlayerScripts then
        local PlayerModule = PlayerScripts:WaitForChild("PlayerModule", 3)
        if PlayerModule then
            ControlModule = require(PlayerModule:WaitForChild("ControlModule", 3))
        end
    end
end)

-- ScreenGui Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MovementUtilityUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 160, 0, 285)
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
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0, 6)
UIPadding.PaddingBottom = UDim.new(0, 8)
UIPadding.PaddingLeft = UDim.new(0, 8)
UIPadding.PaddingRight = UDim.new(0, 8)
UIPadding.Parent = MainFrame

-- Top Bar Container (Header + Minimize Button)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 18)
TopBar.BackgroundTransparency = 1
TopBar.LayoutOrder = 1
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -22, 1, 0)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Movement Hub"
TitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 18, 0, 18)
MinimizeBtn.Position = UDim2.new(1, -18, 0, 0)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Text = "-"
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.TextSize = 14
MinimizeBtn.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 4)
MinCorner.Parent = MinimizeBtn

-- UI Component Helpers
local function CreateButton(name, text, layoutOrder)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(1, 0, 0, 26)
    btn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 12
    btn.LayoutOrder = layoutOrder
    btn.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    return btn
end

local function CreateTextBox(name, placeholder, layoutOrder)
    local box = Instance.new("TextBox")
    box.Name = name
    box.Size = UDim2.new(1, 0, 0, 24)
    box.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    box.Text = ""
    box.Font = Enum.Font.SourceSans
    box.TextSize = 12
    box.LayoutOrder = layoutOrder
    box.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = box

    return box
end

local function CreateButtonRow(name1, text1, name2, text2, layoutOrder)
    local rowFrame = Instance.new("Frame")
    rowFrame.Name = name1 .. "Row"
    rowFrame.Size = UDim2.new(1, 0, 0, 24)
    rowFrame.BackgroundTransparency = 1
    rowFrame.LayoutOrder = layoutOrder
    rowFrame.Parent = MainFrame

    local btn1 = Instance.new("TextButton")
    btn1.Name = name1
    btn1.Size = UDim2.new(0.5, -2, 1, 0)
    btn1.Position = UDim2.new(0, 0, 0, 0)
    btn1.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    btn1.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn1.Text = text1
    btn1.Font = Enum.Font.SourceSansBold
    btn1.TextSize = 12
    btn1.Parent = rowFrame

    local corner1 = Instance.new("UICorner")
    corner1.CornerRadius = UDim.new(0, 6)
    corner1.Parent = btn1

    local btn2 = Instance.new("TextButton")
    btn2.Name = name2
    btn2.Size = UDim2.new(0.5, -2, 1, 0)
    btn2.Position = UDim2.new(0.5, 2, 0, 0)
    btn2.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    btn2.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn2.Text = text2
    btn2.Font = Enum.Font.SourceSansBold
    btn2.TextSize = 12
    btn2.Parent = rowFrame

    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0, 6)
    corner2.Parent = btn2

    return btn1, btn2
end

-- UI Elements Creation
local FlyBtn = CreateButton("FlyBtn", "Fly: OFF", 2)
local FlySpeedBox = CreateTextBox("FlySpeedBox", "Fly Speed (Default: 50)", 3)
local WalkSpeedBox = CreateTextBox("WalkSpeedBox", "Walk Speed (Default: 16)", 4)
local JumpPowerBox = CreateTextBox("JumpPowerBox", "Jump Power (Default: 50)", 5)
local GravityBox = CreateTextBox("GravityBox", "Gravity (Default: 196.2)", 6)

-- Waypoint Rows
local SetWp1Btn, SetWp2Btn = CreateButtonRow("SetWp1Btn", "Set W1", "SetWp2Btn", "Set W2", 7)
local TpWp1Btn, TpWp2Btn = CreateButtonRow("TpWp1Btn", "TP W1", "TpWp2Btn", "TP W2", 8)

-- Minimized "Open Menu" Button
local RestoreBtn = Instance.new("TextButton")
RestoreBtn.Name = "RestoreBtn"
RestoreBtn.Size = UDim2.new(0, 90, 0, 28)
RestoreBtn.Position = UDim2.new(0.5, -45, 0, 10)
RestoreBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
RestoreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RestoreBtn.Text = "Open Menu"
RestoreBtn.Font = Enum.Font.SourceSansBold
RestoreBtn.TextSize = 13
RestoreBtn.Visible = false
RestoreBtn.Parent = ScreenGui

local RestoreCorner = Instance.new("UICorner")
RestoreCorner.CornerRadius = UDim.new(0, 6)
RestoreCorner.Parent = RestoreBtn

local RestoreStroke = Instance.new("UIStroke")
RestoreStroke.Color = Color3.fromRGB(255, 255, 255)
RestoreStroke.Thickness = 1.5
RestoreStroke.Transparency = 0.8
RestoreStroke.Parent = RestoreBtn

-- Minimize / Restore Events
MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    RestoreBtn.Visible = true
end)

RestoreBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    RestoreBtn.Visible = false
end)

--------------------------------------------------------
-- REUSABLE DRAGGING MECHANISM
--------------------------------------------------------
local function MakeDraggable(guiObject)
    local dragging = false
    local dragInput, dragStart, startPos

    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Make both the Main Frame and Minimized Button draggable
MakeDraggable(MainFrame)
MakeDraggable(RestoreBtn)

--------------------------------------------------------
-- STAT MODIFIER LOGIC
--------------------------------------------------------

-- Input Handlers
FlySpeedBox.FocusLost:Connect(function()
    local val = tonumber(FlySpeedBox.Text)
    if val then getgenv().FlySpeed = val end
end)

WalkSpeedBox.FocusLost:Connect(function()
    local val = tonumber(WalkSpeedBox.Text)
    if val then getgenv().WalkSpeed = val end
end)

JumpPowerBox.FocusLost:Connect(function()
    local val = tonumber(JumpPowerBox.Text)
    if val then getgenv().JumpPower = val end
end)

GravityBox.FocusLost:Connect(function()
    local val = tonumber(GravityBox.Text)
    if val then
        getgenv().Gravity = val
        workspace.Gravity = val
    end
end)

-- Loop to continuously enforce WalkSpeed, JumpPower, and Gravity
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
        if getgenv().Gravity then
            workspace.Gravity = getgenv().Gravity
        end
        task.wait(0.1)
    end
end)

--------------------------------------------------------
-- WAYPOINT TELEPORT LOGIC
--------------------------------------------------------
local function flashStatus(btn, statusText, color, defaultText)
    btn.Text = statusText
    btn.TextColor3 = color
    task.delay(1.5, function()
        btn.Text = defaultText
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
end

SetWp1Btn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        waypoint1 = hrp.CFrame
        flashStatus(SetWp1Btn, "Saved W1", Color3.fromRGB(120, 200, 140), "Set W1")
    end
end)

SetWp2Btn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        waypoint2 = hrp.CFrame
        flashStatus(SetWp2Btn, "Saved W2", Color3.fromRGB(120, 200, 140), "Set W2")
    end
end)

TpWp1Btn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        if waypoint1 then
            hrp.CFrame = waypoint1
            flashStatus(TpWp1Btn, "TP'd W1", Color3.fromRGB(120, 200, 140), "TP W1")
        else
            flashStatus(TpWp1Btn, "No W1", Color3.fromRGB(200, 120, 120), "TP W1")
        end
    end
end)

TpWp2Btn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        if waypoint2 then
            hrp.CFrame = waypoint2
            flashStatus(TpWp2Btn, "TP'd W2", Color3.fromRGB(120, 200, 140), "TP W2")
        else
            flashStatus(TpWp2Btn, "No W2", Color3.fromRGB(200, 120, 120), "TP W2")
        end
    end
end)

--------------------------------------------------------
-- FLIGHT PHYSICS LOGIC
--------------------------------------------------------
local bodyVelocity, bodyGyro

local function StopFlight()
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
end

local function StartFlight()
    local character = LocalPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    StopFlight()

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = hrp

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bodyGyro.P = 9e4
    bodyGyro.CFrame = hrp.CFrame
    bodyGyro.Parent = hrp

    humanoid.PlatformStand = true

    task.spawn(function()
        while getgenv().Flying and hrp and humanoid and bodyVelocity and bodyGyro do
            local camera = workspace.CurrentCamera
            bodyGyro.CFrame = camera.CFrame

            local moveInput = Vector3.new(0, 0, 0)
            if ControlModule then
                moveInput = ControlModule:GetMoveVector()
            else
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveInput = moveInput + Vector3.new(0, 0, -1) end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveInput = moveInput + Vector3.new(0, 0, 1) end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveInput = moveInput + Vector3.new(-1, 0, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveInput = moveInput + Vector3.new(1, 0, 0) end
            end

            local moveVec = (camera.CFrame.RightVector * moveInput.X) + (camera.CFrame.LookVector * -moveInput.Z)

            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveVec = moveVec + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveVec = moveVec - Vector3.new(0, 1, 0)
            end

            if moveVec.Magnitude > 0 then
                bodyVelocity.Velocity = moveVec.Unit * (getgenv().FlySpeed or 50)
            else
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end

            task.wait()
        end
        StopFlight()
    end)
end

FlyBtn.MouseButton1Click:Connect(function()
    getgenv().Flying = not getgenv().Flying

    if getgenv().Flying then
        FlyBtn.Text = "Fly: ON"
        FlyBtn.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
        StartFlight()
    else
        FlyBtn.Text = "Fly: OFF"
        FlyBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        StopFlight()
    end
end)
