-- ========================================================
-- STANDALONE DUAL-WAYPOINT TELEPORT SCRIPT (2x2 GRID)
-- ========================================================
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local waypoint1 = nil
local waypoint2 = nil

-- UI Setup
local playerGui = localPlayer:WaitForChild("PlayerGui")
local existingGui = playerGui:FindFirstChild("StandaloneWaypointUI")
if existingGui then existingGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StandaloneWaypointUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999999
screenGui.Parent = playerGui

-- Container Panel (Top Right)
local container = Instance.new("Frame")
container.Name = "WaypointContainer"
container.Size = UDim2.new(0, 160, 0, 88)
container.Position = UDim2.new(1, -170, 0, 50)
container.BackgroundTransparency = 1
container.ZIndex = 20
container.Parent = screenGui

-- Helper function to create uniform dark-themed grid buttons
local function createButton(name, text, posXScale, posXOffset, posYOffset)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0.5, -4, 0, 40)
    btn.Position = UDim2.new(posXScale, posXOffset, 0, posYOffset)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.ZIndex = 21
    btn.Parent = container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(45, 45, 45)
    stroke.Thickness = 1.5
    stroke.Parent = btn

    return btn
end

-- Create 2x2 Side-by-Side Grid (Row 1: Set W1 & W2 | Row 2: TP W1 & W2)
local setWp1Btn = createButton("SetWp1Btn", "Set W1", 0, 0, 0)
local setWp2Btn = createButton("SetWp2Btn", "Set W2", 0.5, 4, 0)
local tpWp1Btn  = createButton("TPWp1Btn",  "TP W1",  0, 0, 48)
local tpWp2Btn  = createButton("TPWp2Btn",  "TP W2",  0.5, 4, 48)

local function flashStatus(btn, statusText, color, defaultText)
    btn.Text = statusText
    btn.TextColor3 = color
    task.delay(1.5, function()
        btn.Text = defaultText
        btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    end)
end

-- ========================================================
-- BUTTON LISTENERS
-- ========================================================

-- Set Waypoint 1
setWp1Btn.MouseButton1Click:Connect(function()
    local char = localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        waypoint1 = hrp.CFrame
        flashStatus(setWp1Btn, "W1 Saved", Color3.fromRGB(120, 200, 140), "Set W1")
    end
end)

-- Set Waypoint 2
setWp2Btn.MouseButton1Click:Connect(function()
    local char = localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        waypoint2 = hrp.CFrame
        flashStatus(setWp2Btn, "W2 Saved", Color3.fromRGB(120, 200, 140), "Set W2")
    end
end)

-- Teleport to Waypoint 1
tpWp1Btn.MouseButton1Click:Connect(function()
    local char = localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        if waypoint1 then
            hrp.CFrame = waypoint1
            flashStatus(tpWp1Btn, "TP'd W1", Color3.fromRGB(120, 200, 140), "TP W1")
        else
            flashStatus(tpWp1Btn, "No W1", Color3.fromRGB(200, 120, 120), "TP W1")
        end
    end
end)

-- Teleport to Waypoint 2
tpWp2Btn.MouseButton1Click:Connect(function()
    local char = localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        if waypoint2 then
            hrp.CFrame = waypoint2
            flashStatus(tpWp2Btn, "TP'd W2", Color3.fromRGB(120, 200, 140), "TP W2")
        else
            flashStatus(tpWp2Btn, "No W2", Color3.fromRGB(200, 120, 120), "TP W2")
        end
    end
end)
