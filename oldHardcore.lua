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

-- [SISTEMA DE STAMINA E INTERFACE]
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local Player = game.Players.LocalPlayer
local stamina, maxStamina, isExhausted, sprinting, crouching = 100, 100, false, false, false

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

-- [BOTÃO MOBILE]
local mobileBtn
if UIS.TouchEnabled then
    mobileBtn = Instance.new("ImageButton", sg)
    mobileBtn.Name = "SprintBtn"
    mobileBtn.Size = UDim2.new(0, 80, 0, 80)
    mobileBtn.Position = UDim2.new(0.85, 0, 0.80, 0)
    mobileBtn.BackgroundColor3 = Color3.new(0,0,0)
    mobileBtn.BackgroundTransparency = 0.5
    mobileBtn.Image = "rbxassetid://6031068833"
    Instance.new("UICorner", mobileBtn).CornerRadius = UDim.new(1,0)
    
    mobileBtn.MouseButton1Down:Connect(function() sprinting = true end)
    mobileBtn.MouseButton1Up:Connect(function() sprinting = false end)
end

-- [CONTROLES PC - RESTAURADOS]
UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.Q then 
        sprinting = true 
    elseif i.KeyCode == Enum.KeyCode.C or i.KeyCode == Enum.KeyCode.LeftControl then 
        crouching = not crouching 
    end
end)

UIS.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.Q then 
        sprinting = false 
    end
end)

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

-- [MOVIMENTAÇÃO LOGIC]
task.spawn(function()
    while task.wait(0.05) do
        local char = Player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if not hum then continue end
        local isMoving = hum.MoveDirection.Magnitude > 0
        local seekActive = workspace:FindFirstChild("SeekMoving")

        if seekActive then
            container.Visible = false
            stamina = 100
            isExhausted = false
            if breathSound then breathSound:Stop() end
        else
            container.Visible = true
            if isExhausted then
                hum.WalkSpeed = 12
                sprinting = false
                stamina = math.min(100, stamina + 0.4)
                bar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                if mobileBtn then mobileBtn.ImageColor3 = Color3.fromRGB(200, 50, 50) end
                if not breathSound.IsPlaying then breathSound:Play() end
                if stamina >= 100 then
                    isExhausted = false
                    bar.BackgroundColor3 = Color3.fromRGB(255, 222, 189)
                    if mobileBtn then mobileBtn.ImageColor3 = Color3.new(1,1,1) end
                    if breathSound then breathSound:Stop() end
                end
            elseif crouching then
                hum.WalkSpeed = 9
                stamina = math.min(100, stamina + 0.8)
                sprinting = false
            elseif sprinting and isMoving and stamina > 0 then
                hum.WalkSpeed = 19
                stamina = math.max(0, stamina - 1.2)
                if stamina <= 0 then isExhausted = true end
            else
                hum.WalkSpeed = 12
                stamina = math.min(100, stamina + 0.5)
            end
            bar.Size = UDim2.new(stamina / 100, 0, 1, 0)
        end
    end
end)

-- [SISTEMA DE LEGENDAS]
local function ShowCaption(text, duration)
    local pGui = Player:WaitForChild("PlayerGui")
    if pGui:FindFirstChild("OldHardcoreCaption") then pGui.OldHardcoreCaption:Destroy() end
    local screenGui = Instance.new("ScreenGui", pGui)
    screenGui.Name = "OldHardcoreCaption"
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 999
    local captionLabel = Instance.new("TextLabel", screenGui)
    captionLabel.Size = UDim2.new(0.6, 0, 0.05, 10)
    captionLabel.Position = UDim2.new(0.5, 0, 0.92, -60)
    captionLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    captionLabel.BackgroundTransparency = 1
    captionLabel.Text = text
    captionLabel.TextColor3 = Color3.fromRGB(255, 222, 189)
    captionLabel.TextSize = 30
    captionLabel.Font = Enum.Font.Oswald
    captionLabel.TextStrokeTransparency = 0
    local alertSound = Instance.new("Sound", game.SoundService)
    alertSound.SoundId = "rbxassetid://3848738542"
    alertSound:Play()
    game.Debris:AddItem(alertSound, 2)
    task.delay(duration or 4, function()
        if captionLabel then
            TS:Create(captionLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
            task.wait(0.5) screenGui:Destroy()
        end
    end)
end

-- [FUNÇÃO DE CARREGAMENTO]
local function LoadEntity(name)
    if workspace:FindFirstChild("SeekMoving") then return end
    local url = entityURLs[name]
    if url then task.spawn(function() pcall(function() loadstring(game:HttpGet(url))() end) end) end
end

-- [CONTROLE DE INÍCIO E CRONOGRAMA]
local opened = false
game.ReplicatedStorage.GameData.LatestRoom.Changed:Connect(function()
    if not opened and game.ReplicatedStorage.GameData.LatestRoom.Value == 1 then
        opened = true
        if startTimeValue.Value == 0 then startTimeValue.Value = workspace:GetServerTimeNow() end
        
        ShowCaption("Old Hardcore Initiated.", 5)
        task.wait(3)
        ShowCaption("Have fun " .. Player.Name .. ".", 4)
        task.wait(4)
        ShowCaption("Stamina and Mobile support ready.", 5)
        task.wait(5)
        ShowCaption("If you're standing up and can't sprint, enter a closet while crouched, then leave.", 6.7)

        -- RIPPER LOOP (300s)
        task.spawn(function() local c = 0 while true do SyncWait(c+80) game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait() LoadEntity("Ripper"); SyncWait(c+167) game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait() LoadEntity("Ripper"); c=c+300 end end)
        -- REBOUND LOOP (450s)
        task.spawn(function() local c = 0 while true do SyncWait(c+290) game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait() LoadEntity("Rebound"); SyncWait(c+410) game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait() LoadEntity("Rebound"); c=c+450 end end)
        -- SILENCE LOOP (600s)
        task.spawn(function() local c = 0 while true do SyncWait(c+455) LoadEntity("Silence"); SyncWait(c+600) LoadEntity("Silence"); c=c+600 end end)
        -- CEASE LOOP (390s)
        task.spawn(function() local c = 0 while true do SyncWait(c+160) LoadEntity("Cease"); SyncWait(c+390) LoadEntity("Cease"); c=c+390 end end)
        -- DEER GOD LOOP (500s)
        task.spawn(function() local c = 0 while true do SyncWait(c+420) LoadEntity("DeerGod"); c=c+500 end end)
        -- SHOCKER (RANDOM)
        task.spawn(function() while true do task.wait(math.random(30, 70)) LoadEntity("Shocker") end end)
    end
end)

-- [VERIFICAÇÃO DE PORTA 0]
if game.ReplicatedStorage.GameData.LatestRoom.Value ~= 0 and not workspace:FindFirstChild("ExecutedOldHard") then
    ShowCaption("EXECUTOR: Script Not Loaded. Please go to Door 0 to begin.", 6)
    if Player.Character then Player.Character.Humanoid.Health = 0 end
else
    ShowCaption("EXECUTOR: Script Loaded.", 6)
end
