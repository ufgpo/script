-- ========================================================
-- STANDALONE UTILITY: ANTI-AFK, AUTO-REJOIN & BLACK SCREEN
-- ========================================================

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- --------------------------------------------------------
-- 1. ANTI-AFK (Prevents 20-minute idle kick)
-- --------------------------------------------------------
pcall(function()
    for _, conn in pairs(getconnections(localPlayer.Idled)) do
        conn:Disable()
    end
end)

localPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- --------------------------------------------------------
-- 2. AUTO-REJOIN (Triggers on disconnect / error prompts)
-- --------------------------------------------------------
GuiService.ErrorMessageChanged:Connect(function()
    task.wait(2)
    TeleportService:Teleport(game.PlaceId, localPlayer)
end)

task.spawn(function()
    local promptOverlay = CoreGui:WaitForChild("RobloxPromptGui", 10)
    if promptOverlay then
        local overlay = promptOverlay:WaitForChild("promptOverlay", 10)
        if overlay then
            overlay.ChildAdded:Connect(function(child)
                if child.Name == "ErrorPrompt" then
                    while true do
                        TeleportService:Teleport(game.PlaceId, localPlayer)
                        task.wait(3)
                    end
                end
            end)
        end
    end
end)

-- --------------------------------------------------------
-- 3. MATTE BLACK SCREEN COVER & TOGGLE UI
-- --------------------------------------------------------
pcall(function()
    local targetParent = gethui and gethui() or CoreGui or localPlayer:WaitForChild("PlayerGui")

    local existingGui = targetParent:FindFirstChild("UniversalBlackScreenUI")
    if existingGui then existingGui:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UniversalBlackScreenUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 99999999
    ScreenGui.Parent = targetParent

    -- Fullscreen Black Cover
    local blackScreen = Instance.new("TextButton")
    blackScreen.Name = "BlackScreenOverlay"
    blackScreen.Size = UDim2.new(1, 0, 1, 0)
    blackScreen.Position = UDim2.new(0, 0, 0, 0)
    blackScreen.BackgroundColor3 = Color3.fromRGB(12, 12, 12) -- Matte Black
    blackScreen.BorderSizePixel = 0
    blackScreen.Visible = false
    blackScreen.ZIndex = 100
    blackScreen.TextColor3 = Color3.fromRGB(180, 180, 180)
    blackScreen.Font = Enum.Font.SourceSansBold
    blackScreen.TextSize = 20
    blackScreen.Text = "SCREEN HIDDEN\n\nAnti-AFK & Auto-Rejoin Active\n\n(Click anywhere to unhide)"
    blackScreen.Parent = ScreenGui

    -- Top-Right Container Panel
    local container = Instance.new("Frame")
    container.Name = "ButtonContainer"
    container.Size = UDim2.new(0, 150, 0, 45)
    container.Position = UDim2.new(1, -160, 0, 20)
    container.BackgroundTransparency = 1
    container.ZIndex = 10
    container.Parent = ScreenGui

    -- Hide Screen Button
    local hideButton = Instance.new("TextButton")
    hideButton.Name = "HideScreenBtn"
    hideButton.Size = UDim2.new(1, 0, 1, 0)
    hideButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    hideButton.TextColor3 = Color3.fromRGB(180, 180, 180)
    hideButton.Text = "Hide Screen: OFF"
    hideButton.Font = Enum.Font.SourceSansBold
    hideButton.TextSize = 14
    hideButton.ZIndex = 11
    hideButton.Parent = container

    local hideCorner = Instance.new("UICorner")
    hideCorner.CornerRadius = UDim.new(0, 8)
    hideCorner.Parent = hideButton

    local hideStroke = Instance.new("UIStroke")
    hideStroke.Color = Color3.fromRGB(45, 45, 45)
    hideStroke.Thickness = 1.5
    hideStroke.Parent = hideButton

    -- Toggle Logic
    hideButton.MouseButton1Click:Connect(function()
        blackScreen.Visible = true
        hideButton.Text = "Hide Screen: ON"
        hideButton.TextColor3 = Color3.fromRGB(120, 200, 140)
    end)

    blackScreen.MouseButton1Click:Connect(function()
        blackScreen.Visible = false
        hideButton.Text = "Hide Screen: OFF"
        hideButton.TextColor3 = Color3.fromRGB(180, 180, 180)
    end)
end)
