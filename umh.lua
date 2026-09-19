local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

-- Remove existing GUI if script is re-executed
local parentGui = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
if parentGui:FindFirstChild("MasterUtilityMiningHub") then
    parentGui.MasterUtilityMiningHub:Destroy()
end

-- =========================================================
-- GLOBAL STATES & VARIABLES
-- =========================================================
getgenv().AuraMine = false
getgenv().SingleMine = false
getgenv().WalkSpeed = 16
getgenv().Gravity = 196.2
getgenv().ModifyStats = true
getgenv().IsTeleporting = false

local running = true

-- Position Lock State (Placement Lock with Minimal Gravity = 50)
local positionLockEnabled = false
local lockedPosition = nil
local positionLockGravity = 50

-- Auto Crate States
local crateEnabled = false
local currentCrate = "Omega"
local crateDelay = 0.1

-- Auto Equip Egg States (0.2s interval)
local eggEnabled = false
local selectedEgg = "Common Egg"
local equipInterval = 0.2

local eggs = {
    "Common Egg", "Unique Egg", "Epic Egg", "Omega Egg",
    "Legendary Egg", "Mythical Egg", "Season 1 Egg"
}

-- Waypoint Storage
getgenv().WP1_Pos = nil
getgenv().WP2_Pos = nil

-- Remote Event Resolver
local Remote = nil
local function EnsureRemote()
    if Remote and Remote.Parent then return Remote end
    pcall(function()
        local Network = ReplicatedStorage:WaitForChild("Network", 5)
        if Network then
            local a, b = Network:InvokeServer()
            if typeof(a) == "Instance" and a:IsA("RemoteEvent") then
                Remote = a
            elseif typeof(b) == "Instance" and b:IsA("RemoteEvent") then
                Remote = b
            else
                Remote = a
            end
        end
    end)
    if not Remote then
        pcall(function()
            local ClientScript = LocalPlayer.PlayerGui:FindFirstChild("ScreenGui") and LocalPlayer.PlayerGui.ScreenGui:FindFirstChild("ClientScript")
            if ClientScript and getsenv and getupvalue then
                local Data = getsenv(ClientScript).updatePasses
                local Values = getupvalue(Data, 8)
                Remote = Values and Values["RemoteEvent"]
            end
        end)
    end
    return Remote
end

-- =========================================================
-- REJOIN SERVER MECHANIC
-- =========================================================
local function RejoinServer()
    if #Players:GetPlayers() <= 1 then
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end

-- =========================================================
-- TELEPORT PAD FUNCTIONS
-- =========================================================
local function SetWaypointPad(wpNum)
    task.spawn(function()
        getgenv().IsTeleporting = true
        local remote = EnsureRemote()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and remote then
            local pos = hrp.CFrame.Position - Vector3.new(0, 2.5, 0)
            if wpNum == 1 then getgenv().WP1_Pos = pos else getgenv().WP2_Pos = pos end
            pcall(function()
                remote:FireServer("RemovePad", {{}})
                task.wait(0.15)
                remote:FireServer("PlaceTeleporter", {{pos}})
            end)
        end
        task.wait(0.2)
        getgenv().IsTeleporting = false
    end)
end

local function TeleportToPad(wpNum)
    task.spawn(function()
        local pos = (wpNum == 1) and getgenv().WP1_Pos or getgenv().WP2_Pos
        if not pos then return end
        getgenv().IsTeleporting = true
        local remote = EnsureRemote()
        if remote then
            pcall(function()
                remote:FireServer("RemovePad", {{}})
                task.wait(0.15)
                remote:FireServer("PlaceTeleporter", {{pos}})
                task.wait(0.15)
                remote:FireServer("TeleportToPad", {{}})
            end)
        end
        task.wait(0.3)
        getgenv().IsTeleporting = false
    end)
end

-- =========================================================
-- SCREEN GUI SETUP (EVENLY BALANCED 2-COLUMN LAYOUT)
-- =========================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MasterUtilityMiningHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = parentGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(480, 280)
MainFrame.Position = UDim2.new(0.5, -240, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = Color3.fromRGB(255, 200, 0)
MainStroke.Transparency = 0.3
MainStroke.Parent = MainFrame

-- Left Column Container (Automation & Teleports)
local LeftContainer = Instance.new("ScrollingFrame")
LeftContainer.Name = "LeftContainer"
LeftContainer.Size = UDim2.new(0.5, -15, 1, -36)
LeftContainer.Position = UDim2.fromOffset(10, 30)
LeftContainer.BackgroundTransparency = 1
LeftContainer.BorderSizePixel = 0
LeftContainer.ScrollBarThickness = 3
LeftContainer.CanvasSize = UDim2.fromOffset(0, 280)
LeftContainer.ClipsDescendants = false
LeftContainer.Parent = MainFrame

local LeftLayout = Instance.new("UIListLayout")
LeftLayout.Parent = LeftContainer
LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
LeftLayout.Padding = UDim.new(0, 6)

-- Right Column Container (Movement & Utilities)
local RightContainer = Instance.new("ScrollingFrame")
RightContainer.Name = "RightContainer"
RightContainer.Size = UDim2.new(0.5, -15, 1, -36)
RightContainer.Position = UDim2.new(0.5, 5, 0, 30)
RightContainer.BackgroundTransparency = 1
RightContainer.BorderSizePixel = 0
RightContainer.ScrollBarThickness = 3
RightContainer.CanvasSize = UDim2.fromOffset(0, 310)
RightContainer.Parent = MainFrame

local RightLayout = Instance.new("UIListLayout")
RightLayout.Parent = RightContainer
RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
RightLayout.Padding = UDim.new(0, 6)

local function CreateHeader(text, order, parent)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 200, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.Parent = parent
    return lbl
end

-- =========================================================
-- TOP BAR (TITLE / MINIMIZE / CLOSE)
-- =========================================================
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 28)
TopBar.Position = UDim2.fromOffset(0, 0)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.fromOffset(10, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "UTILITY & MINING HUB"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 12
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.fromOffset(18, 18)
MinimizeBtn.Position = UDim2.new(1, -44, 0, 5)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
MinimizeBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
MinimizeBtn.Text = "-"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 14
MinimizeBtn.Parent = TopBar

Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 4)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.fromOffset(18, 18)
CloseBtn.Position = UDim2.new(1, -22, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Text = "×"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = TopBar

Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

local RestoreBtn = Instance.new("TextButton")
RestoreBtn.Name = "RestoreBtn"
RestoreBtn.Size = UDim2.fromOffset(100, 30)
RestoreBtn.Position = UDim2.new(0.5, -50, 0.05, 0)
RestoreBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
RestoreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RestoreBtn.Text = "Open Menu"
RestoreBtn.Font = Enum.Font.GothamBold
RestoreBtn.TextSize = 12
RestoreBtn.Visible = false
RestoreBtn.Active = true
RestoreBtn.Parent = ScreenGui

Instance.new("UICorner", RestoreBtn).CornerRadius = UDim.new(0, 6)

local RestoreStroke = Instance.new("UIStroke")
RestoreStroke.Thickness = 1.5
RestoreStroke.Color = Color3.fromRGB(255, 200, 0)
RestoreStroke.Transparency = 0.4
RestoreStroke.Parent = RestoreBtn

-- =========================================================
-- LEFT COLUMN: MINING & AUTOMATION & WAYPOINTS
-- =========================================================
CreateHeader("MINING AUTOMATION", 1, LeftContainer)

local ToggleAuraBtn = Instance.new("TextButton")
ToggleAuraBtn.Size = UDim2.new(1, -4, 0, 24)
ToggleAuraBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
ToggleAuraBtn.BorderSizePixel = 0
ToggleAuraBtn.Text = "Aura Mine: OFF"
ToggleAuraBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleAuraBtn.TextSize = 11
ToggleAuraBtn.Font = Enum.Font.GothamBold
ToggleAuraBtn.LayoutOrder = 2
ToggleAuraBtn.Parent = LeftContainer

Instance.new("UICorner", ToggleAuraBtn).CornerRadius = UDim.new(0, 5)

local ToggleSingleBtn = Instance.new("TextButton")
ToggleSingleBtn.Size = UDim2.new(1, -4, 0, 24)
ToggleSingleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
ToggleSingleBtn.BorderSizePixel = 0
ToggleSingleBtn.Text = "Single Mine (Underfoot): OFF"
ToggleSingleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleSingleBtn.TextSize = 11
ToggleSingleBtn.Font = Enum.Font.GothamBold
ToggleSingleBtn.LayoutOrder = 3
ToggleSingleBtn.Parent = LeftContainer

Instance.new("UICorner", ToggleSingleBtn).CornerRadius = UDim.new(0, 5)

CreateHeader("CRATE & EGG FARM", 4, LeftContainer)

local CrateInput = Instance.new("TextBox")
CrateInput.Size = UDim2.new(1, -4, 0, 24)
CrateInput.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
CrateInput.BorderSizePixel = 0
CrateInput.TextColor3 = Color3.fromRGB(255, 255, 255)
CrateInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
CrateInput.PlaceholderText = "Crate name..."
CrateInput.Text = currentCrate
CrateInput.TextSize = 11
CrateInput.Font = Enum.Font.Gotham
CrateInput.ClearTextOnFocus = false
CrateInput.LayoutOrder = 5
CrateInput.Parent = LeftContainer

Instance.new("UICorner", CrateInput).CornerRadius = UDim.new(0, 5)

local CrateToggle = Instance.new("TextButton")
CrateToggle.Size = UDim2.new(1, -4, 0, 24)
CrateToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CrateToggle.BorderSizePixel = 0
CrateToggle.Text = "Auto Crate: OFF"
CrateToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
CrateToggle.TextSize = 11
CrateToggle.Font = Enum.Font.GothamBold
CrateToggle.LayoutOrder = 6
CrateToggle.Parent = LeftContainer

Instance.new("UICorner", CrateToggle).CornerRadius = UDim.new(0, 5)

local EggSelector = Instance.new("TextButton")
EggSelector.Size = UDim2.new(1, -4, 0, 24)
EggSelector.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
EggSelector.BorderSizePixel = 0
EggSelector.Text = "  " .. selectedEgg .. "   ▼"
EggSelector.TextColor3 = Color3.fromRGB(235, 235, 240)
EggSelector.TextSize = 11
EggSelector.Font = Enum.Font.GothamMedium
EggSelector.TextXAlignment = Enum.TextXAlignment.Left
EggSelector.AutoButtonColor = false
EggSelector.LayoutOrder = 7
EggSelector.Parent = LeftContainer

Instance.new("UICorner", EggSelector).CornerRadius = UDim.new(0, 5)

local EggList = Instance.new("ScrollingFrame")
EggList.Size = UDim2.new(1, -4, 0, 80)
EggList.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
EggList.BorderSizePixel = 0
EggList.Visible = false
EggList.ZIndex = 20
EggList.ScrollBarThickness = 3
EggList.CanvasSize = UDim2.new(0, 0, 0, #eggs * 24)
EggList.LayoutOrder = 8
EggList.Parent = LeftContainer

Instance.new("UICorner", EggList).CornerRadius = UDim.new(0, 5)

for i, name in ipairs(eggs) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -4, 0, 24)
    b.Position = UDim2.new(0, 2, 0, (i - 1) * 24)
    b.BackgroundTransparency = 1
    b.Text = "  " .. name
    b.TextColor3 = Color3.fromRGB(225, 225, 230)
    b.TextSize = 11
    b.Font = Enum.Font.Gotham
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.ZIndex = 21
    b.Parent = EggList

    b.MouseButton1Click:Connect(function()
        selectedEgg = name
        EggSelector.Text = "  " .. name .. "   ▼"
        EggList.Visible = false
    end)
end

EggSelector.MouseButton1Click:Connect(function()
    EggList.Visible = not EggList.Visible
end)

local EggToggle = Instance.new("TextButton")
EggToggle.Size = UDim2.new(1, -4, 0, 24)
EggToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
EggToggle.BorderSizePixel = 0
EggToggle.Text = "Auto Equip Egg: OFF"
EggToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
EggToggle.TextSize = 11
EggToggle.Font = Enum.Font.GothamBold
EggToggle.LayoutOrder = 9
EggToggle.Parent = LeftContainer

Instance.new("UICorner", EggToggle).CornerRadius = UDim.new(0, 5)

-- =========================================================
-- RIGHT COLUMN: MOVEMENT & POSITION LOCK & TELEPORTS
-- =========================================================
CreateHeader("PLAYER MOVEMENT", 1, RightContainer)

local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.new(1, -4, 0, 24)
SpeedBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
SpeedBox.BorderSizePixel = 0
SpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedBox.PlaceholderText = "Walk Speed (Default: 16)"
SpeedBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
SpeedBox.Text = ""
SpeedBox.Font = Enum.Font.Gotham
SpeedBox.TextSize = 11
SpeedBox.LayoutOrder = 2
SpeedBox.Parent = RightContainer

Instance.new("UICorner", SpeedBox).CornerRadius = UDim.new(0, 5)

local GravityBox = Instance.new("TextBox")
GravityBox.Size = UDim2.new(1, -4, 0, 24)
GravityBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
GravityBox.BorderSizePixel = 0
GravityBox.TextColor3 = Color3.fromRGB(255, 255, 255)
GravityBox.PlaceholderText = "Gravity (Default: 196.2)"
GravityBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
GravityBox.Text = ""
GravityBox.Font = Enum.Font.Gotham
GravityBox.TextSize = 11
GravityBox.LayoutOrder = 3
GravityBox.Parent = RightContainer

Instance.new("UICorner", GravityBox).CornerRadius = UDim.new(0, 5)

local PositionLockToggle = Instance.new("TextButton")
PositionLockToggle.Size = UDim2.new(1, -4, 0, 24)
PositionLockToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
PositionLockToggle.BorderSizePixel = 0
PositionLockToggle.Text = "Position Lock: OFF"
PositionLockToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
PositionLockToggle.TextSize = 11
PositionLockToggle.Font = Enum.Font.GothamBold
PositionLockToggle.LayoutOrder = 4
PositionLockToggle.Parent = RightContainer

Instance.new("UICorner", PositionLockToggle).CornerRadius = UDim.new(0, 5)

CreateHeader("TELEPORT PADS & SERVER", 5, RightContainer)

-- Pad 1 Controls
local WP1Frame = Instance.new("Frame")
WP1Frame.Size = UDim2.new(1, -4, 0, 24)
WP1Frame.BackgroundTransparency = 1
WP1Frame.LayoutOrder = 6
WP1Frame.Parent = RightContainer

local WP1Layout = Instance.new("UIListLayout")
WP1Layout.Parent = WP1Frame
WP1Layout.FillDirection = Enum.FillDirection.Horizontal
WP1Layout.Padding = UDim.new(0, 4)

local SetWP1Btn = Instance.new("TextButton")
SetWP1Btn.Size = UDim2.new(0.5, -2, 1, 0)
SetWP1Btn.BackgroundColor3 = Color3.fromRGB(50, 60, 80)
SetWP1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
SetWP1Btn.Text = "Pad 1 Set"
SetWP1Btn.Font = Enum.Font.GothamBold
SetWP1Btn.TextSize = 10
SetWP1Btn.Parent = WP1Frame
Instance.new("UICorner", SetWP1Btn).CornerRadius = UDim.new(0, 5)

local TPWP1Btn = Instance.new("TextButton")
TPWP1Btn.Size = UDim2.new(0.5, -2, 1, 0)
TPWP1Btn.BackgroundColor3 = Color3.fromRGB(46, 120, 87)
TPWP1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
TPWP1Btn.Text = "TP Pad 1"
TPWP1Btn.Font = Enum.Font.GothamBold
TPWP1Btn.TextSize = 10
TPWP1Btn.Parent = WP1Frame
Instance.new("UICorner", TPWP1Btn).CornerRadius = UDim.new(0, 5)

-- Pad 2 Controls
local WP2Frame = Instance.new("Frame")
WP2Frame.Size = UDim2.new(1, -4, 0, 24)
WP2Frame.BackgroundTransparency = 1
WP2Frame.LayoutOrder = 7
WP2Frame.Parent = RightContainer

local WP2Layout = Instance.new("UIListLayout")
WP2Layout.Parent = WP2Frame
WP2Layout.FillDirection = Enum.FillDirection.Horizontal
WP2Layout.Padding = UDim.new(0, 4)

local SetWP2Btn = Instance.new("TextButton")
SetWP2Btn.Size = UDim2.new(0.5, -2, 1, 0)
SetWP2Btn.BackgroundColor3 = Color3.fromRGB(50, 60, 80)
SetWP2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
SetWP2Btn.Text = "Pad 2 Set"
SetWP2Btn.Font = Enum.Font.GothamBold
SetWP2Btn.TextSize = 10
SetWP2Btn.Parent = WP2Frame
Instance.new("UICorner", SetWP2Btn).CornerRadius = UDim.new(0, 5)

local TPWP2Btn = Instance.new("TextButton")
TPWP2Btn.Size = UDim2.new(0.5, -2, 1, 0)
TPWP2Btn.BackgroundColor3 = Color3.fromRGB(46, 120, 87)
TPWP2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
TPWP2Btn.Text = "TP Pad 2"
TPWP2Btn.Font = Enum.Font.GothamBold
TPWP2Btn.TextSize = 10
TPWP2Btn.Parent = WP2Frame
Instance.new("UICorner", TPWP2Btn).CornerRadius = UDim.new(0, 5)

-- Rejoin Button
local RejoinBtn = Instance.new("TextButton")
RejoinBtn.Size = UDim2.new(1, -4, 0, 24)
RejoinBtn.BackgroundColor3 = Color3.fromRGB(140, 80, 30)
RejoinBtn.BorderSizePixel = 0
RejoinBtn.Text = "Rejoin Same Server"
RejoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RejoinBtn.TextSize = 11
RejoinBtn.Font = Enum.Font.GothamBold
RejoinBtn.LayoutOrder = 8
RejoinBtn.Parent = RightContainer

Instance.new("UICorner", RejoinBtn).CornerRadius = UDim.new(0, 5)

-- =========================================================
-- DRAGGING MECHANISM
-- =========================================================
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
            guiObject.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

MakeDraggable(MainFrame)
MakeDraggable(RestoreBtn)

-- =========================================================
-- EVENT BINDINGS
-- =========================================================
MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    RestoreBtn.Visible = true
end)

RestoreBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    RestoreBtn.Visible = false
end)

CloseBtn.MouseButton1Click:Connect(function()
    crateEnabled = false
    eggEnabled = false
    positionLockEnabled = false
    getgenv().AuraMine = false
    getgenv().SingleMine = false
    getgenv().ModifyStats = false
    running = false
    ScreenGui:Destroy()
end)

CrateInput.FocusLost:Connect(function()
    local text = CrateInput.Text:match("^%s*(.-)%s*$")
    if text ~= "" then currentCrate = text end
end)

CrateToggle.MouseButton1Click:Connect(function()
    local text = CrateInput.Text:match("^%s*(.-)%s*$")
    if text ~= "" then currentCrate = text end

    crateEnabled = not crateEnabled
    if crateEnabled then
        CrateToggle.Text = "Auto Crate: ON (" .. currentCrate .. ")"
        CrateToggle.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
    else
        CrateToggle.Text = "Auto Crate: OFF"
        CrateToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    end
end)

EggToggle.MouseButton1Click:Connect(function()
    eggEnabled = not eggEnabled
    if eggEnabled then
        EggToggle.Text = "Auto Equip Egg: ON"
        EggToggle.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
    else
        EggToggle.Text = "Auto Equip Egg: OFF"
        EggToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    end
end)

PositionLockToggle.MouseButton1Click:Connect(function()
    positionLockEnabled = not positionLockEnabled
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if positionLockEnabled then
        if hrp then
            lockedPosition = Vector2.new(hrp.Position.X, hrp.Position.Z)
        end
        PositionLockToggle.Text = "Position Lock: ON"
        PositionLockToggle.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
    else
        lockedPosition = nil
        PositionLockToggle.Text = "Position Lock: OFF"
        PositionLockToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    end
end)

SetWP1Btn.MouseButton1Click:Connect(function() SetWaypointPad(1) end)
TPWP1Btn.MouseButton1Click:Connect(function() TeleportToPad(1) end)
SetWP2Btn.MouseButton1Click:Connect(function() SetWaypointPad(2) end)
TPWP2Btn.MouseButton1Click:Connect(function() TeleportToPad(2) end)
RejoinBtn.MouseButton1Click:Connect(function() RejoinServer() end)

SpeedBox.FocusLost:Connect(function()
    local val = tonumber(SpeedBox.Text)
    if val then getgenv().WalkSpeed = val end
end)

GravityBox.FocusLost:Connect(function()
    local val = tonumber(GravityBox.Text)
    if val then
        getgenv().Gravity = val
        workspace.Gravity = val
    end
end)

-- Character Modifiers & Position Lock Loop (Horizontal Lock + 50 Gravity Force)
RunService.Heartbeat:Connect(function()
    if not running then return end
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        
        if humanoid and getgenv().ModifyStats and getgenv().WalkSpeed then
            humanoid.WalkSpeed = getgenv().WalkSpeed
        end
        
        if positionLockEnabled and lockedPosition and hrp then
            local currentPos = hrp.Position
            -- Lock X and Z axes, apply 50 downward force on Y
            hrp.CFrame = CFrame.new(Vector3.new(lockedPosition.X, currentPos.Y, lockedPosition.Y), currentPos + hrp.CFrame.LookVector)
            hrp.AssemblyLinearVelocity = Vector3.new(0, -positionLockGravity, 0)
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end
    
    if getgenv().Gravity then
        workspace.Gravity = getgenv().Gravity
    end
end)

-- =========================================================
-- AUTOMATION LOOPS
-- =========================================================
task.spawn(function()
    while running do
        if crateEnabled and currentCrate ~= "" then
            pcall(function()
                local remote = EnsureRemote()
                if remote then
                    remote:FireServer("SpinCrate", { { currentCrate } })
                end
            end)
        end
        task.wait(crateDelay)
    end
end)

task.spawn(function()
    while running do
        if eggEnabled and selectedEgg ~= "" then
            pcall(function()
                local remote = EnsureRemote()
                if remote then
                    remote:FireServer("equipPet", {
                        { { selectedEgg, selectedEgg, 0, true } }
                    })
                end
            end)
        end
        task.wait(equipInterval) -- Set to 0.2 seconds
    end
end)

local runningAura = false
local function StartAuraMining()
    if runningAura then return end
    runningAura = true

    task.spawn(function()
        while getgenv().AuraMine and running do
            if not getgenv().IsTeleporting then
                local remote = EnsureRemote()
                if remote then
                    local Character = LocalPlayer.Character
                    local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")

                    if HumanoidRootPart then
                        local minp = HumanoidRootPart.CFrame.Position - Vector3.new(5, 5, 5)
                        local maxp = HumanoidRootPart.CFrame.Position + Vector3.new(5, 5, 5)
                        local region = Region3.new(minp, maxp)

                        local blocksContainer = workspace:FindFirstChild("Blocks")
                        if blocksContainer then
                            local parts = workspace:FindPartsInRegion3WithWhiteList(region, {blocksContainer}, 50)
                            for _, block in ipairs(parts) do
                                if not getgenv().AuraMine or getgenv().IsTeleporting then break end
                                remote:FireServer("MineBlock", {{block.Parent}})
                                task.wait()
                            end
                        end
                    end
                else
                    task.wait(1)
                end
            else
                task.wait(0.1)
            end
            task.wait()
        end
        runningAura = false
    end)
end

ToggleAuraBtn.MouseButton1Click:Connect(function()
    getgenv().AuraMine = not getgenv().AuraMine
    if getgenv().AuraMine then
        ToggleAuraBtn.Text = "Aura Mine: ON"
        ToggleAuraBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
        StartAuraMining()
    else
        ToggleAuraBtn.Text = "Aura Mine: OFF"
        ToggleAuraBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    end
end)

local runningSingle = false
local function StartSingleMining()
    if runningSingle then return end
    runningSingle = true

    task.spawn(function()
        while getgenv().SingleMine and running do
            if not getgenv().IsTeleporting then
                local remote = EnsureRemote()
                if remote then
                    local Character = LocalPlayer.Character
                    local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")

                    if HumanoidRootPart then
                        local underFootPos = HumanoidRootPart.CFrame.Position - Vector3.new(0, 3, 0)
                        local minp = underFootPos - Vector3.new(1.5, 1.5, 1.5)
                        local maxp = underFootPos + Vector3.new(1.5, 1.5, 1.5)
                        local region = Region3.new(minp, maxp)

                        local blocksContainer = workspace:FindFirstChild("Blocks")
                        if blocksContainer then
                            local parts = workspace:FindPartsInRegion3WithWhiteList(region, {blocksContainer}, 10)
                            for _, block in ipairs(parts) do
                                if not getgenv().SingleMine or getgenv().IsTeleporting then break end
                                remote:FireServer("MineBlock", {{block.Parent}})
                                task.wait()
                            end
                        end
                    end
                else
                    task.wait(1)
                end
            else
                task.wait(0.1)
            end
            task.wait()
        end
        runningSingle = false
    end)
end

ToggleSingleBtn.MouseButton1Click:Connect(function()
    getgenv().SingleMine = not getgenv().SingleMine
    if getgenv().SingleMine then
        ToggleSingleBtn.Text = "Single Mine (Underfoot): ON"
        ToggleSingleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
        StartSingleMining()
    else
        ToggleSingleBtn.Text = "Single Mine (Underfoot): OFF"
        ToggleSingleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    end
end)
