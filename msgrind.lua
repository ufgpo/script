-- ========================================================
-- AUTO-REJOIN & ANTI-AFK HANDLER
-- ========================================================
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- Anti-AFK (Bypasses 20-minute idle kick)
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

-- Auto-Rejoin (Standard Disconnect & Error Catch)
GuiService.ErrorMessageChanged:Connect(function()
    task.wait(2)
    TeleportService:Teleport(game.PlaceId, localPlayer)
end)

task.spawn(function()
    local promptOverlay = game.CoreGui:WaitForChild("RobloxPromptGui", 5)
    if promptOverlay then
        local overlay = promptOverlay:WaitForChild("promptOverlay", 5)
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

-- ========================================================
-- MAIN MINING SCRIPT
-- ========================================================
local Character = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character.PrimaryPart

game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if root then Character = root end
end)

local function RefreshCharacter()
    pcall(function()
        if not Character or Character.Parent == nil then
            local char = game.Players.LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then Character = root end
        end
    end)
    return Character ~= nil and Character.Parent ~= nil
end

local function ParseNum(s)
    if not s then return nil end
    s = tostring(s):gsub(",", ""):gsub("%s+", "")
    local mult = 1
    local last = s:sub(-1):upper()
    if last == "K" then mult = 1e3; s = s:sub(1,-2)
    elseif last == "M" then mult = 1e6; s = s:sub(1,-2)
    elseif last == "B" then mult = 1e9; s = s:sub(1,-2)
    elseif last == "T" then mult = 1e12; s = s:sub(1,-2)
    elseif last == "Q" then mult = 1e15; s = s:sub(1,-2) end
    local n = tonumber(s)
    return n and n * mult or nil
end

local function GetInventory()
    local ok, cur, cap = pcall(function()
        local t = Character.Parent.Backpack.Decore.Count.SurfaceGui.Amount.Text
        local seg = string.split(t, "/")
        return ParseNum(seg[1]), ParseNum(seg[2])
    end)
    if not ok then return nil, nil end
    return cur, cap
end

local function GetInventoryAmount()
    local cur = GetInventory()
    return cur
end

local Sell = 30_000
local REBIRTH_COST = 10000000

local FIRES_PER_BLOCK = 1
local HEARTBEAT_THROTTLE = 4
local SELL_FILL = 0.9
local INV_STALL = 0.35
local COIN_STALL = 0.3
local REBIRTH_PUSH = 0.6
local SELL_FIRE_GAP = 0.08
local MOVE_GAP = 0.2
local REBIRTH_FIRE_GAP = 0.08
local SELL_TIMEOUT = 8
local REBIRTH_TIMEOUT = 3
local REPORT = false
local DEBUG = false

local function LOG(...)
    if DEBUG then print(...) end
end

local Collapse = false
local TeleportPos = nil
local Counter = 0
local ScriptIsBroken = false
local IsSelling = false
local LoopRunning = false
local NeedSell = false
local Heartbeat = os.clock()
local LastRbLand = 0
local LastInvValue = 0
local LastInvRise = os.clock()

local function SellThreshold(cap)
    if cap and cap > 0 then
        return math.min(Sell, cap * SELL_FILL)
    end
    return Sell
end

local function CheckInventory(mining)
    if NeedSell then return end
    local cur, cap = GetInventory()
    if not cur then return end

    if cur > LastInvValue then
        LastInvValue = cur
        LastInvRise = os.clock()
    elseif cur < LastInvValue then
        LastInvValue = cur
        LastInvRise = os.clock()
        return
    end

    local threshold = SellThreshold(cap)

    if cur >= threshold then
        NeedSell = true
        return
    end

    if mining and cur >= threshold * 0.6 and os.clock() - LastInvRise >= INV_STALL then
        NeedSell = true
    end
end

do
    repeat wait() until game:IsLoaded()
    game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("ScreenGui")
    while game:GetService("Players").LocalPlayer.PlayerGui.ScreenGui:FindFirstChild("LoadingFrame") do
        pcall(function()
            for i, connection in pairs(getconnections(game:GetService("Players").LocalPlayer.PlayerGui.ScreenGui.LoadingFrame.Quality.LowQuality.MouseButton1Down)) do
                connection:Fire()
            end
        end)
        wait()
    end
end

local function optimizeGraphics()
    pcall(function()
        settings():GetService("RenderSettings").QualityLevel = Enum.QualityLevel.Level01
    end)

    local lighting = game:GetService("Lighting")
    pcall(function() lighting.GlobalShadows = false end)
    pcall(function() lighting.FogEnd = 1e10 end)
    pcall(function() lighting.Brightness = 1 end)
    pcall(function() lighting.TimeOfDay = "12:00:00" end)
    pcall(function() lighting.Outlines = false end)
    pcall(function() lighting.Technology = Enum.Technology.Compatibility end)

    local function applyToObj(obj)
        pcall(function()
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
                obj.CastShadow = false
                obj.Transparency = 0.1
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") or obj:IsA("Explosion") then
                obj.Enabled = false
            elseif obj:IsA("MeshPart") then
                obj.TextureID = ""
                obj.Material = Enum.Material.SmoothPlastic
            elseif obj:IsA("PostEffect") or obj:IsA("BlurEffect") or obj:IsA("BloomEffect") or obj:IsA("ColorCorrectionEffect") then
                obj.Enabled = false
            end
        end)
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        applyToObj(obj)
    end

    local descConn = workspace.DescendantAdded:Connect(applyToObj)
    task.delay(60, function()
        if descConn then
            descConn:Disconnect()
            descConn = nil
        end
    end)

    pcall(function()
        game:GetService("StarterGui"):SetCore("TopbarEnabled", false)
    end)

    local player = game.Players.LocalPlayer
    if player.Character then
        for _, obj in ipairs(player.Character:GetDescendants()) do
            pcall(function()
                if obj:IsA("Accessory") or obj:IsA("Clothing") or obj:IsA("CharacterMesh") or obj:IsA("Shirt") or obj:IsA("Pants") then
                    if obj.Name ~= "Backpack" and not obj:FindFirstChild("Decore") then
                        obj:Destroy()
                    end
                elseif obj:IsA("BasePart") then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Reflectance = 0
                    obj.Transparency = 0.1
                end
            end)
        end
    end

    pcall(function()
        game:GetService("Workspace").CurrentCamera.FieldOfView = 70
    end)
end

optimizeGraphics()

-- ========================================================
-- MATTE BLACK UI & FULLSCREEN HIDE OVERLAY
-- ========================================================
pcall(function()
    local existingGui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("MiningOverlayUI")
    if existingGui then existingGui:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MiningOverlayUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true -- Stretches over topbar
    ScreenGui.DisplayOrder = 999999 -- Sits above all game UIs
    ScreenGui.Parent = game.Players.LocalPlayer.PlayerGui

    -- Fullscreen Black Screen Overlay
    local blackScreen = Instance.new("TextButton")
    blackScreen.Name = "BlackScreenOverlay"
    blackScreen.Size = UDim2.new(1, 0, 1, 0)
    blackScreen.Position = UDim2.new(0, 0, 0, 0)
    blackScreen.BackgroundColor3 = Color3.fromRGB(15, 15, 15) -- Matte Black
    blackScreen.BorderSizePixel = 0
    blackScreen.Visible = false
    blackScreen.ZIndex = 100
    blackScreen.TextColor3 = Color3.fromRGB(180, 180, 180)
    blackScreen.Font = Enum.Font.SourceSansBold
    blackScreen.TextSize = 22
    blackScreen.Parent = ScreenGui

    -- Rebirth Stats Tracking
    local RebirthsStat = game.Players.LocalPlayer:WaitForChild("leaderstats", 10):WaitForChild("Rebirths", 10)
    local initialRebirths = RebirthsStat and RebirthsStat.Value or 0

    local function updateBlackScreenText()
        local currentRebirths = RebirthsStat and RebirthsStat.Value or 0
        local sessionRebirths = math.max(0, currentRebirths - initialRebirths)
        blackScreen.Text = "SCREEN HIDDEN\n\n🔄 Total Rebirths: " .. tostring(currentRebirths) .. "\n⭐ Session Rebirths: " .. tostring(sessionRebirths) .. "\n\n(Click anywhere to unhide)"
    end

    -- Container Frame in Top-Right
    local container = Instance.new("Frame")
    container.Name = "ButtonContainer"
    container.Size = UDim2.new(0, 160, 0, 105)
    container.Position = UDim2.new(1, -170, 0, 50)
    container.BackgroundTransparency = 1
    container.ZIndex = 20
    container.Parent = ScreenGui

    -- Rebirth Stat Display Frame
    local rebirthBox = Instance.new("Frame")
    rebirthBox.Name = "RebirthBox"
    rebirthBox.Size = UDim2.new(1, 0, 0, 50)
    rebirthBox.Position = UDim2.new(0, 0, 0, 0)
    rebirthBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    rebirthBox.BorderSizePixel = 0
    rebirthBox.ZIndex = 21
    rebirthBox.Parent = container

    local rbCorner = Instance.new("UICorner")
    rbCorner.CornerRadius = UDim.new(0, 8)
    rbCorner.Parent = rebirthBox

    local rbStroke = Instance.new("UIStroke")
    rbStroke.Color = Color3.fromRGB(45, 45, 45)
    rbStroke.Thickness = 1.5
    rbStroke.Parent = rebirthBox

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 0.4, 0)
    TitleLabel.Position = UDim2.new(0, 0, 0, 4)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "REBIRTHS"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 12
    TitleLabel.ZIndex = 22
    TitleLabel.Parent = rebirthBox

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(1, 0, 0.5, 0)
    ValueLabel.Position = UDim2.new(0, 0, 0.4, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(RebirthsStat and RebirthsStat.Value or 0)
    ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.TextSize = 16
    ValueLabel.ZIndex = 22
    ValueLabel.Parent = rebirthBox

    if RebirthsStat then
        updateBlackScreenText()
        RebirthsStat:GetPropertyChangedSignal("Value"):Connect(function()
            ValueLabel.Text = tostring(RebirthsStat.Value)
            updateBlackScreenText()
        end)
    end

    -- Toggle Hide Screen Button
    local hideButton = Instance.new("TextButton")
    hideButton.Name = "HideScreenBtn"
    hideButton.Size = UDim2.new(1, 0, 0, 45)
    hideButton.Position = UDim2.new(0, 0, 0, 58)
    hideButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    hideButton.TextColor3 = Color3.fromRGB(180, 180, 180)
    hideButton.Text = "Hide Screen: OFF"
    hideButton.Font = Enum.Font.SourceSansBold
    hideButton.TextSize = 15
    hideButton.ZIndex = 21
    hideButton.Parent = container

    local hideCorner = Instance.new("UICorner")
    hideCorner.CornerRadius = UDim.new(0, 8)
    hideCorner.Parent = hideButton

    local hideStroke = Instance.new("UIStroke")
    hideStroke.Color = Color3.fromRGB(45, 45, 45)
    hideStroke.Thickness = 1.5
    hideStroke.Parent = hideButton

    -- Button Actions
    hideButton.MouseButton1Click:Connect(function()
        updateBlackScreenText()
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

-- Remote Extraction Logic
local Remote

do
    local Data = getsenv(game:GetService("Players").LocalPlayer.PlayerGui.ScreenGui.ClientScript).updatePasses
    local Values = getupvalue(Data,8)
    Remote = Values["RemoteEvent"]
    Data, Values = nil
end

if Remote then
    pcall(function()
        game.Players.LocalPlayer.PlayerGui.ScreenGui.ClientScript.Event.Parent = game.Players.LocalPlayer.PlayerGui.ScreenGui
    end)
    pcall(function()
        game.Players.LocalPlayer.PlayerGui.ScreenGui.ClientScript:Destroy()
    end)
else
    game.Players.LocalPlayer:Kick("Failed to get upvalue")
end

Remote.OnClientEvent:Connect(function()
    return nil
end)

local CoinsAmount = game.Players.LocalPlayer.leaderstats.Coins
local RebirthsStat = game.Players.LocalPlayer.leaderstats.Rebirths
local BlocksMinedStat = game.Players.LocalPlayer.leaderstats:FindFirstChild("Blocks Mined")

local function GetCoinsAmount()
    local ok, v = pcall(function()
        return ParseNum(CoinsAmount.Value)
    end)
    return ok and v or nil
end

local function NextRebirthCost()
    return REBIRTH_COST * (RebirthsStat.Value + 1)
end

local lastRebirthTry = 0
CoinsAmount.Changed:Connect(function()
    if Collapse or ScriptIsBroken or IsSelling then return end
    if os.clock() - lastRebirthTry < 0.05 then return end
    local c = GetCoinsAmount()
    if c and c >= NextRebirthCost() then
        lastRebirthTry = os.clock()
        Remote:FireServer("Rebirth", {{}})
    end
end)

task.spawn(function()
    local ok, err = pcall(function()
        local InvLabel = Character.Parent:WaitForChild("Backpack", 15):WaitForChild("Decore", 15):WaitForChild("Count", 15):WaitForChild("SurfaceGui", 15):WaitForChild("Amount", 15)
        InvLabel:GetPropertyChangedSignal("Text"):Connect(function()
            CheckInventory(false)
        end)
        LOG("sell watcher connected")
    end)
    if not ok then LOG("sell watcher failed, polling only: ", err) end
end)

do
    game.Workspace.Gravity = 1000
    local HumanoidRootPart = game.Players.LocalPlayer.Character.HumanoidRootPart
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 0
    game.Players.LocalPlayer.Character.Humanoid.JumpPower = 0
    HumanoidRootPart.Anchored = true
    Remote:FireServer("MoveTo", {{"LavaSpawn"}})
    local part = Instance.new("Part", game.Workspace)
    part.Anchored = true
    part.Size = Vector3.new(10, 0.5, 100)
    part.Material = "ForceField"
    part.Position = Vector3.new(21, 9.5, 26285)
    wait(1)
    HumanoidRootPart.Anchored = false
    while HumanoidRootPart.Position.Z > 26220 do
        HumanoidRootPart.CFrame = CFrame.new(Vector3.new(HumanoidRootPart.Position.X,13.05,HumanoidRootPart.Position.Z-0.5))
        wait()
    end
    HumanoidRootPart.CFrame = CFrame.new(18, 10, 26220)
end

do
    local RunService = game:GetService("RunService").Stepped
    local HumanoidRootPart = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    while HumanoidRootPart.Position.Y > -2430 do
        local min = HumanoidRootPart.CFrame + Vector3.new(-1,-10,-1)
        local max = HumanoidRootPart.CFrame + Vector3.new(1,0,1)
        local region = Region3.new(min.Position, max.Position)
        local parts = workspace:FindPartsInRegion3WithWhiteList(region, {game.Workspace.Blocks}, 5)
        for each, block in pairs(parts) do
            Remote:FireServer("MineBlock",{{block.Parent}})
            Remote:FireServer("MineBlock",{{block.Parent}})
            Remote:FireServer("MineBlock",{{block.Parent}})
            RunService:Wait()
        end
        task.wait()
    end
    game.Workspace.Gravity = 196
end

Character.Anchored = true
task.wait(0.3)
Remote:FireServer(unpack({[1] = "PlaceTeleporter",[2] = {[1] = {[1] = Character.CFrame.Position}}}))
task.wait(0.3)
Remote:FireServer(unpack({[1] = "TeleportToPad",[2] = {[1] = {}}}))
task.wait(0.2)
TeleportPos = Character.CFrame.Position

local function IsNearTeleport()
    if TeleportPos == nil then return true end
    local ok, r = pcall(function()
        return (Character.CFrame.Position - TeleportPos).Magnitude < 8
    end)
    if not ok then return true end
    return r
end

local function FindColumnBlock()
    for _, Block in pairs(game.Workspace.Blocks:GetChildren()) do
        if Block.PrimaryPart
           and Block.PrimaryPart.Position.Z == 26220
           and Block.PrimaryPart.Position.X == 18 then
            return Block.PrimaryPart.Position
        end
    end
    return nil
end

local function RepositionPad()
    Remote:FireServer(unpack({[1] = "RemovePad",[2] = {[1] = {}}}))
    task.wait(0.1)
    local Target = FindColumnBlock()
    if Target then
        Remote:FireServer(unpack({[1] = "PlaceTeleporter",[2] = {[1] = {[1] = Target}}}))
        task.wait(0.1)
    end
    Remote:FireServer(unpack({[1] = "TeleportToPad",[2] = {[1] = {}}}))
    task.wait(0.1)
    pcall(function() TeleportPos = Character.CFrame.Position end)
end

local MineParams = OverlapParams.new()
MineParams.FilterType = Enum.RaycastFilterType.Include
MineParams.FilterDescendantsInstances = {game.Workspace.Blocks}

local function DoSellSequence()
    IsSelling = true
    local coinsBefore = GetCoinsAmount() or 0
    local rbBefore = RebirthsStat.Value
    local tStart = os.clock()

    local lastMove = os.clock()
    local lastSell = 0
    local sellFires = 0
    local arrived = false
    local sellStartPos = Character.Position
    Remote:FireServer("MoveTo", {{"LavaSell"}})
    Remote:FireServer("MoveTo", {{"LavaSell"}})

    while os.clock() - tStart < SELL_TIMEOUT and not Collapse and not ScriptIsBroken do
        local inv = GetInventoryAmount()
        if inv and inv < Sell then break end
        if (GetCoinsAmount() or 0) > coinsBefore then break end

        if os.clock() - lastMove >= MOVE_GAP then
            lastMove = os.clock()
            Remote:FireServer("MoveTo", {{"LavaSell"}})
        end
        if not arrived then
            local ok, far = pcall(function()
                return (Character.Position - sellStartPos).Magnitude > 20
            end)
            if ok and far then arrived = true end
        end

        if (arrived or os.clock() - tStart > 0.4) and os.clock() - lastSell >= SELL_FIRE_GAP then
            lastSell = os.clock()
            sellFires = sellFires + 1
            Remote:FireServer("SellItems", {{}})
        end
        task.wait()
    end

    local tSellPhase = os.clock() - tStart
    local tRb = os.clock()
    local lastRb = 0
    local rbAttempts = 0
    local sawEnough = false
    local enoughAt = nil
    local lastCoin = GetCoinsAmount() or 0
    local lastCoinChange = os.clock()

    while os.clock() - tRb < REBIRTH_TIMEOUT and not Collapse and not ScriptIsBroken do
        if RebirthsStat.Value > rbBefore then break end

        local c = GetCoinsAmount() or 0

        if c >= NextRebirthCost() then
            sawEnough = true
            if not enoughAt then enoughAt = os.clock() - tRb end
        elseif sawEnough then
            break
        end
        if c ~= lastCoin then
            lastCoin = c
            lastCoinChange = os.clock()
        end

        local enough = c >= NextRebirthCost()
        local pushing = os.clock() - tRb < REBIRTH_PUSH
        local settled = os.clock() - lastCoinChange >= COIN_STALL

        if enough or pushing then
            if os.clock() - lastRb >= REBIRTH_FIRE_GAP then
                lastRb = os.clock()
                rbAttempts = rbAttempts + 1
                Remote:FireServer("Rebirth", {{}})
            end
        elseif settled then
            break
        end

        task.wait()
    end

    local tRbPhase = os.clock() - tRb
    local rbGap = (LastRbLand > 0) and (os.clock() - LastRbLand) or 0
    LastRbLand = os.clock()

    Remote:FireServer(unpack({[1] = "TeleportToPad",[2] = {[1] = {}}}))
    local tTp = os.clock()
    local lastTp = os.clock()
    while not IsNearTeleport() and os.clock() - tTp < 3 and not Collapse and not ScriptIsBroken do
        if os.clock() - lastTp >= 0.12 then
            lastTp = os.clock()
            Remote:FireServer(unpack({[1] = "TeleportToPad",[2] = {[1] = {}}}))
        end
        task.wait()
    end

    local tTpPhase = os.clock() - tTp

    pcall(function()
        local B = workspace:GetPartBoundsInBox(Character.CFrame, Vector3.new(10, 10, 10), MineParams)
        for i = 1, math.min(#B, 6) do
            if B[i] and B[i].Parent then
                Remote:FireServer("MineBlock", {{B[i].Parent}})
            end
        end
    end)

    if REPORT then
        LOG(string.format("[Trip] %.2fs | sell %.2fs | rb %.2fs | enough@%s | tp %.2fs | gap %.2fs | +%d | %d fires | %d sells",
            os.clock() - tStart,
            tSellPhase,
            tRbPhase,
            enoughAt and string.format("%.2fs", enoughAt) or "never",
            tTpPhase,
            rbGap,
            RebirthsStat.Value - rbBefore,
            rbAttempts,
            sellFires))
    end

    LastInvValue = 0
    LastInvRise = os.clock()
    IsSelling = false
    NeedSell = false
end

task.spawn(function()
    local RunService = game:GetService("RunService")
    local frame = 0
    RunService.Heartbeat:Connect(function()
        frame += 1
        if frame < HEARTBEAT_THROTTLE then return end
        frame = 0
        if Collapse or ScriptIsBroken or IsSelling or NeedSell then return end
        if not RefreshCharacter() then return end
        pcall(function()
            local blocks = workspace:GetPartBoundsInBox(Character.CFrame, Vector3.new(12, 12, 12), MineParams)
            for _, b in ipairs(blocks) do
                if b.Parent then
                    Remote:FireServer("MineBlock", {{b.Parent}})
                end
            end
        end)
    end)
    LOG("heartbeat miner loaded")
end)

local function RebirthLoop()
    if LoopRunning then return end
    LoopRunning = true
    Heartbeat = os.clock()
    pcall(function()
        game.Players.LocalPlayer.Character.Humanoid.PlatformStand = true
    end)

    local function Step()
        local parts = workspace:GetPartBoundsInBox(Character.CFrame, Vector3.new(10,10,10), MineParams)

        if not parts[1] then
            if not Collapse and not ScriptIsBroken then
                RepositionPad()
            end
            return
        end

        CheckInventory(true)
        if NeedSell and not Collapse and not ScriptIsBroken then
            DoSellSequence()
            return
        end

        for _, block in pairs(parts) do
            if Collapse or ScriptIsBroken or NeedSell then break end
            if block:IsA("BasePart") and block.Parent then
                for _ = 1, FIRES_PER_BLOCK do
                    Remote:FireServer("MineBlock", {{block.Parent}})
                end
            end
        end

        if NeedSell and not Collapse and not ScriptIsBroken then
            DoSellSequence()
        end
    end

    while not Collapse and not ScriptIsBroken do
        Heartbeat = os.clock()

        if RefreshCharacter() then
            local ok, err = pcall(Step)
            if not ok then
                LOG("[loop] " .. tostring(err))
                task.wait(0.1)
            end
        else
            task.wait(0.1)
        end

        task.wait()
    end

    LoopRunning = false
end

local function RestartLoop()
    task.spawn(function()
        local t = os.clock()
        while LoopRunning and os.clock() - t < 5 do task.wait(0.1) end
        if LoopRunning then return end
        RebirthLoop()
    end)
end

game.Workspace.Collapsed.Changed:connect(function()
    if game.Workspace.Collapsed.Value ~= true then return end
    if Collapse then return end

    LOG("collapsed")
    Collapse = true
    IsSelling = false
    NeedSell = false

    local ok, err = pcall(function()
        local plr = game.Players.LocalPlayer

        local function Root()
            local char = plr.Character
            return char and char:FindFirstChild("HumanoidRootPart")
        end

        pcall(function() Character.Anchored = true end)
        pcall(function() plr.Character.Humanoid.PlatformStand = false end)

        local tReset = os.clock()
        while game.Workspace.Collapsed.Value == true and os.clock() - tReset < 60 do
            task.wait(0.2)
        end

        local tBlocks = os.clock()
        while os.clock() - tBlocks < 30 do
            local n = 0
            pcall(function() n = #game.Workspace.Blocks:GetChildren() end)
            if n > 0 then break end
            task.wait(0.2)
        end

        task.wait(0.4)
        game.Workspace.Gravity = 1000

        pcall(function()
            plr.Character.Humanoid.WalkSpeed = 0
            plr.Character.Humanoid.JumpPower = 0
        end)

        Remote:FireServer("MoveTo", {{"LavaSpawn"}})
        task.wait(0.4)

        local tWalk = os.clock()
        while os.clock() - tWalk < 15 do
            local hrp = Root()
            if hrp then
                hrp.Anchored = false
                if hrp.Position.Z <= 26220 then break end
                hrp.CFrame = CFrame.new(Vector3.new(hrp.Position.X, 13.05, hrp.Position.Z - 0.5))
                task.wait()
            else
                task.wait(0.1)
            end
        end

        local hrp = Root()
        if hrp then hrp.CFrame = CFrame.new(18, 10, 26220) end

        local RunService = game:GetService("RunService").Stepped
        local tDig = os.clock()
        while os.clock() - tDig < 60 do
            hrp = Root()
            if hrp then
                if hrp.Position.Y <= -2430 then break end
                local min = hrp.CFrame + Vector3.new(-1,-10,-1)
                local max = hrp.CFrame + Vector3.new(1,0,1)
                local region = Region3.new(min.Position, max.Position)
                local parts = workspace:FindPartsInRegion3WithWhiteList(region, {game.Workspace.Blocks}, 5)
                for each, block in pairs(parts) do
                    Remote:FireServer("MineBlock",{{block.Parent}})
                    Remote:FireServer("MineBlock",{{block.Parent}})
                    Remote:FireServer("MineBlock",{{block.Parent}})
                    RunService:Wait()
                end
                task.wait()
            else
                task.wait(0.1)
            end
        end

        game.Workspace.Gravity = 196
        RefreshCharacter()
        pcall(function() Character.Anchored = true end)
        RepositionPad()
    end)

    if not ok then LOG("[collapse] " .. tostring(err)) end

    pcall(function() game.Workspace.Gravity = 196 end)
    Counter = 0
    ScriptIsBroken = false
    Collapse = false
    LOG("collapse recovery done, resuming")
    RestartLoop()
end)

if BlocksMinedStat then
    BlocksMinedStat:GetPropertyChangedSignal("Value"):Connect(function()
        Counter = 0
    end)
end

coroutine.wrap(function()
    while true do
        task.wait(1)

        if not IsSelling then
            Counter += 1
        end

        if LoopRunning and not Collapse and os.clock() - Heartbeat > 15 then
            LOG("stalled")
            LoopRunning = false
        end

        if Counter >= 10 then
            if not ScriptIsBroken and not Collapse then
                LOG("broke")
                ScriptIsBroken = true
                IsSelling = false
                NeedSell = false
                RepositionPad()
                Counter = 0
                ScriptIsBroken = false
                RestartLoop()
            else
                Counter = 0
            end
        end
    end
end)()

RebirthLoop()
