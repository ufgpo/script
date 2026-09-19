-- ========================================================
-- AUTO-REJOIN & ANTI-AFK HANDLER
-- ========================================================
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- Anti-AFK (Disables Idled connections & pings every 60s)
pcall(function()
    for _, conn in pairs(getconnections(localPlayer.Idled)) do
        conn:Disable()
    end
end)

localPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

task.spawn(function()
    while task.wait(60) do
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

-- Auto-Rejoin (Handles Disconnect Prompts)
local function Rejoin()
    while true do
        pcall(function()
            TeleportService:Teleport(game.PlaceId, localPlayer)
        end)
        task.wait(3)
    end
end

GuiService.ErrorMessageChanged:Connect(function()
    task.wait(1)
    Rejoin()
end)

task.spawn(function()
    local promptOverlay = game.CoreGui:WaitForChild("RobloxPromptGui", 10)
    if promptOverlay then
        local overlay = promptOverlay:WaitForChild("promptOverlay", 10)
        if overlay then
            overlay.ChildAdded:Connect(function(child)
                if child.Name == "ErrorPrompt" then
                    Rejoin()
                end
            end)
        end
    end
end)

-- ========================================================
-- POSITION LOCK SETTINGS & SAFE PLATFORM
-- ========================================================
local lockPos = Vector3.new(-281.5, 149, 339)
local freeMovePos = Vector3.new(-280, 180, 340)
local isLocked = true

local safePart = workspace:FindFirstChild("NDS_SafePlatform")
if not safePart then
    safePart = Instance.new("Part")
    safePart.Name = "NDS_SafePlatform"
    safePart.Size = Vector3.new(5, 1, 5)
    safePart.Position = lockPos
    safePart.Anchored = true
    safePart.Parent = workspace
else
    safePart.Position = lockPos
end

-- ========================================================
-- UPPER RIGHT MATTE BLACK UI & FULLSCREEN OVERLAY
-- ========================================================
local playerGui = localPlayer:WaitForChild("PlayerGui")
local existingGui = playerGui:FindFirstChild("NDS_LockUI")
if existingGui then existingGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NDS_LockUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true -- Stretches over the Roblox topbar
screenGui.DisplayOrder = 999999 -- Renders over all other game UIs
screenGui.Parent = playerGui

-- Fullscreen Clickable Overlay
local blackScreen = Instance.new("TextButton")
blackScreen.Name = "BlackScreenOverlay"
blackScreen.Size = UDim2.new(1, 0, 1, 0)
blackScreen.Position = UDim2.new(0, 0, 0, 0)
blackScreen.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
blackScreen.BorderSizePixel = 0
blackScreen.Visible = false
blackScreen.ZIndex = 100 -- Sits above the buttons when active
blackScreen.Text = "Screen Hidden\n(Click anywhere to unhide)"
blackScreen.TextColor3 = Color3.fromRGB(80, 80, 80)
blackScreen.Font = Enum.Font.SourceSans
blackScreen.TextSize = 18
blackScreen.Parent = screenGui

-- UI Container Frame
local container = Instance.new("Frame")
container.Name = "ButtonContainer"
container.Size = UDim2.new(0, 150, 0, 90)
container.Position = UDim2.new(1, -160, 0, 50)
container.BackgroundTransparency = 1
container.ZIndex = 20
container.Parent = screenGui

-- Toggle Lock Button
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleLock"
toggleButton.Size = UDim2.new(1, 0, 0, 40)
toggleButton.Position = UDim2.new(0, 0, 0, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
toggleButton.TextColor3 = Color3.fromRGB(120, 200, 140)
toggleButton.Text = "Position Lock: ON"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 15
toggleButton.ZIndex = 21
toggleButton.Parent = container

local corner1 = Instance.new("UICorner")
corner1.CornerRadius = UDim.new(0, 8)
corner1.Parent = toggleButton

local stroke1 = Instance.new("UIStroke")
stroke1.Color = Color3.fromRGB(45, 45, 45)
stroke1.Thickness = 1.5
stroke1.Parent = toggleButton

-- Toggle Hide Screen Button
local hideScreenButton = Instance.new("TextButton")
hideScreenButton.Name = "ToggleScreen"
hideScreenButton.Size = UDim2.new(1, 0, 0, 40)
hideScreenButton.Position = UDim2.new(0, 0, 0, 48)
hideScreenButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
hideScreenButton.TextColor3 = Color3.fromRGB(180, 180, 180)
hideScreenButton.Text = "Hide Screen: OFF"
hideScreenButton.Font = Enum.Font.SourceSansBold
hideScreenButton.TextSize = 15
hideScreenButton.ZIndex = 21
hideScreenButton.Parent = container

local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 8)
corner2.Parent = hideScreenButton

local stroke2 = Instance.new("UIStroke")
stroke2.Color = Color3.fromRGB(45, 45, 45)
stroke2.Thickness = 1.5
stroke2.Parent = hideScreenButton

-- Button Listeners
toggleButton.MouseButton1Click:Connect(function()
    isLocked = not isLocked
    if isLocked then
        toggleButton.Text = "Position Lock: ON"
        toggleButton.TextColor3 = Color3.fromRGB(120, 200, 140)
    else
        toggleButton.Text = "Position Lock: OFF"
        toggleButton.TextColor3 = Color3.fromRGB(200, 120, 120)

        local char = localPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(freeMovePos)
            end
        end
    end
end)

hideScreenButton.MouseButton1Click:Connect(function()
    blackScreen.Visible = true
    hideScreenButton.Text = "Hide Screen: ON"
    hideScreenButton.TextColor3 = Color3.fromRGB(120, 200, 140)
end)

-- Click anywhere on the black screen to un-hide
blackScreen.MouseButton1Click:Connect(function()
    blackScreen.Visible = false
    hideScreenButton.Text = "Hide Screen: OFF"
    hideScreenButton.TextColor3 = Color3.fromRGB(180, 180, 180)
end)

-- ========================================================
-- MAIN POSITION LOCK LOOP
-- ========================================================
local function disableCollision(char)
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function lockPosition(char)
    local hrp = char:WaitForChild("HumanoidRootPart", 10)
    local hum = char:WaitForChild("Humanoid", 10)

    if not hrp or not hum then return end

    while char and char.Parent and hum.Health > 0 do
        if isLocked then
            disableCollision(char)
            hrp.CFrame = CFrame.new(safePart.Position + Vector3.new(0, 3, 0))
        end
        task.wait(0.05)
    end
end

-- Run for current character and re-bind on every respawn
if localPlayer.Character then
    task.spawn(lockPosition, localPlayer.Character)
end

localPlayer.CharacterAdded:Connect(function(char)
    task.spawn(lockPosition, char)
end)
