-- welcome to old hardcore.
repeat task.wait() until game:IsLoaded()

-- [TRAVA DE EXECUÇÃO ÚNICA]
if not workspace:FindFirstChild("ExecutedOldHard") then
    local modeInit = Instance.new("BoolValue")
    modeInit.Name = "ExecutedOldHard"
    modeInit.Value = true
    modeInit.Parent = workspace
end

local entityURLs = {
    Ripper = "https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/refs/heads/main/oldRipper.lua",
    Rebound = "https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/refs/heads/main/oldRebound.lua",
    DeerGod = "https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/refs/heads/main/oldDeerGod.lua",
    Cease = "https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/refs/heads/main/oldCease.lua",
    Shocker = "https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/refs/heads/main/oldShocker.lua",
    Silence = "https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/refs/heads/main/oldSilence.lua"
}

-- [SISTEMA DE SINCRONIA GLOBAL]
local startTimeValue = workspace:FindFirstChild("OldHardcoreStartTime")
if not startTimeValue then
    startTimeValue = Instance.new("NumberValue")
    startTimeValue.Name = "OldHardcoreStartTime"
    startTimeValue.Value = 0 
    startTimeValue.Parent = workspace
end

local function SyncWait(seconds)
    if startTimeValue.Value == 0 then return end
    local targetTime = startTimeValue.Value + seconds
    while workspace:GetServerTimeNow() < targetTime do
        task.wait(0.5)
    end
end

-- [SISTEMA DE STAMINA E MOVIMENTAÇÃO]
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local Player = game.Players.LocalPlayer

local stamina = 100
local maxStamina = 100
local isExhausted = false
local sprinting = false
local crouching = false

local WALK_SPEED = 12
local RUN_SPEED = 19
local CROUCH_SPEED = 9

local sg = Instance.new("ScreenGui", Player.PlayerGui)
sg.Name = "StaminaGui"
sg.ResetOnSpawn = false

local container = Instance.new("Frame", sg)
container.Size = UDim2.new(0, 250, 0, 10)
container.Position = UDim2.new(0.98, 0, 0.95, 0)
container.AnchorPoint = Vector2.new(1, 1)
container.BackgroundColor3 = Color3.new(0, 0, 0)
container.BackgroundTransparency = 0.4
container.BorderSizePixel = 0

local stroke = Instance.new("UIStroke", container)
stroke.Thickness = 1.5
local bar = Instance.new("Frame", container)
bar.Size = UDim2.new(1, 0, 1, 0)
bar.BackgroundColor3 = Color3.fromRGB(255, 222, 189)
bar.BorderSizePixel = 0

local breathSound
local function SetupCharacter(char)
    local head = char:WaitForChild("Head")
    breathSound = Instance.new("Sound")
    breathSound.SoundId = "rbxassetid://8258601891"
    breathSound.Volume = 2.3
    breathSound.Looped = true
    breathSound.Parent = head
end

Player.CharacterAdded:Connect(SetupCharacter)
if Player.Character then SetupCharacter(Player.Character) end

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.Q then sprinting = true 
    elseif i.KeyCode == Enum.KeyCode.C or i.KeyCode == Enum.KeyCode.LeftControl then crouching = not crouching end
end)

UIS.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.Q then sprinting = false end
end)

task.spawn(function()
    while task.wait(0.05) do
        local char = Player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if not hum then continue end
        local isMoving = hum.MoveDirection.Magnitude > 0
        local seekActive = workspace:FindFirstChild("SeekMoving")

        if seekActive then
            container.Visible = false
            stamina = maxStamina
            isExhausted = false
            if breathSound then breathSound:Stop() end
        else
            container.Visible = true
            if isExhausted then
                hum.WalkSpeed = WALK_SPEED
                sprinting = false
                stamina = math.min(maxStamina, stamina + 0.4)
                bar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                if not breathSound.IsPlaying then breathSound:Play() end
                if stamina >= maxStamina then
                    isExhausted = false
                    bar.BackgroundColor3 = Color3.fromRGB(255, 222, 189)
                    if breathSound then breathSound:Stop() end
                end
            elseif crouching then
                hum.WalkSpeed = CROUCH_SPEED
                stamina = math.min(maxStamina, stamina + 0.8)
                sprinting = false
            elseif sprinting and isMoving and stamina > 0 then
                hum.WalkSpeed = RUN_SPEED
                stamina = math.max(0, stamina - 1.2)
                if stamina <= 0 then isExhausted = true end
            else
                hum.WalkSpeed = WALK_SPEED
                stamina = math.min(maxStamina, stamina + 0.5)
            end
            bar.Size = UDim2.new(stamina / maxStamina, 0, 1, 0)
            local targetAlpha = (stamina >= maxStamina and not isExhausted) and 1 or 0
            container.BackgroundTransparency = targetAlpha + 0.4
            bar.BackgroundTransparency = targetAlpha
            stroke.Transparency = targetAlpha
        end
    end
end)

-- [SISTEMA DE LEGENDAS]
local function ShowCaption(text, duration)
    local pGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    if pGui:FindFirstChild("OldHardcoreCaption") then pGui.OldHardcoreCaption:Destroy() end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "OldHardcoreCaption"
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 999
    screenGui.Parent = pGui
    local captionLabel = Instance.new("TextLabel")
    captionLabel.Size = UDim2.new(0.6, 0, 0.05, 10)
    captionLabel.Position = UDim2.new(0.5, 0, 0.92, -60)
    captionLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    captionLabel.BackgroundTransparency = 1
    captionLabel.Text = text
    captionLabel.TextColor3 = Color3.fromRGB(255, 222, 189)
    captionLabel.TextSize = 30
    captionLabel.Font = Enum.Font.Oswald
    captionLabel.TextStrokeTransparency = 0
    captionLabel.Parent = screenGui
    local alertSound = Instance.new("Sound")
    alertSound.SoundId = "rbxassetid://3848738542"
    alertSound.Parent = game.SoundService
    alertSound:Play()
    game.Debris:AddItem(alertSound, 2)
    task.delay(duration or 4, function()
        if captionLabel then
            local tween = game:GetService("TweenService"):Create(captionLabel, TweenInfo.new(0.5), {TextTransparency = 1})
            tween:Play()
            tween.Completed:Connect(function() screenGui:Destroy() end)
        end
    end)
end

-- [FUNÇÃO DE CARREGAMENTO]
local function LoadEntity(name)
    if workspace:FindFirstChild("SeekMoving") then return end
    local url = entityURLs[name]
    if url then
        task.spawn(function()
            pcall(function() loadstring(game:HttpGet(url))() end)
        end)
    end
end

-- [CONTROLE DE INÍCIO E CRONOGRAMA]
local openedthefirstdoor = false
game.ReplicatedStorage.GameData.LatestRoom.Changed:Connect(function()
    if not openedthefirstdoor and game.ReplicatedStorage.GameData.LatestRoom.Value == 1 then
        openedthefirstdoor = true
        if startTimeValue.Value == 0 then startTimeValue.Value = workspace:GetServerTimeNow() end
        
        ShowCaption("Old Hardcore Initiated.", 5)
        task.wait(3)
        ShowCaption("Idc or whatever, have fun " .. game.Players.LocalPlayer.Name .. ".", 4)

        -- Ripper (122, 200)
        task.spawn(function()
            SyncWait(80) game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait() LoadEntity("Ripper")
            SyncWait(167) game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait() LoadEntity("Ripper")
        end)

        -- Rebound (290, 340)
        task.spawn(function()
            SyncWait(290) game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait() LoadEntity("Rebound")
            SyncWait(410) game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait() LoadEntity("Rebound")
        end)

        -- Silence (455, 600)
        task.spawn(function()
            SyncWait(455) LoadEntity("Silence")
            SyncWait(600) LoadEntity("Silence")
        end)

        -- Deer God (420)
        task.spawn(function() SyncWait(420) LoadEntity("DeerGod") end)

        -- Cease (Loop)
        task.spawn(function()
            local c = 0 while true do
                SyncWait(c + 160) LoadEntity("Cease")
                SyncWait(c + 390) LoadEntity("Cease")
                c = c + 390
            end
        end)

        -- Shocker
        task.spawn(function()
            while true do task.wait(math.random(30, 70)) LoadEntity("Shocker") end
        end)
    end
end)

-- [VERIFICAÇÃO DE PORTA 0]
if game.ReplicatedStorage.GameData.LatestRoom.Value ~= 0 then
    ShowCaption("EXECUTOR: Script Not Loaded. Please go to Door 0 to begin.", 6)
    if Player.Character then Player.Character.Humanoid.Health = 0 end
else
    ShowCaption("EXECUTOR: Script Loaded.", 6)
end
