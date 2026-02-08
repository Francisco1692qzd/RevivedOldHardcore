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
    Shocker = "https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/refs/heads/main/oldShocker.lua"
}

-- [SISTEMA DE SINCRONIA GLOBAL]
local startTimeValue = workspace:FindFirstChild("OldHardcoreStartTime")
if not startTimeValue then
    startTimeValue = Instance.new("NumberValue")
    startTimeValue.Name = "OldHardcoreStartTime"
    startTimeValue.Value = 0 
    startTimeValue.Parent = workspace
end

-- Função que espera baseada no relógio do servidor
local function SyncWait(seconds)
    if startTimeValue.Value == 0 then return end
    local targetTime = startTimeValue.Value + seconds
    while workspace:GetServerTimeNow() < targetTime do
        task.wait(0.5) -- Checagem leve para não pesar
    end
end

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

-- [FUNÇÃO DE CARREGAMENTO COM ANTI-SEEK]
local function LoadEntity(name)
    if workspace:FindFirstChild("SeekMoving") then
        print("XENO: " .. name .. " spawn cancelado (Seek ativo).")
        return
    end

    local url = entityURLs[name]
    if url then
        task.spawn(function()
            pcall(function() loadstring(game:HttpGet(url))() end)
        end)
    end
end

-- [CONTROLE DE INÍCIO]
local openedthefirstdoor = false

game.ReplicatedStorage.GameData.LatestRoom.Changed:Connect(function()
    if not openedthefirstdoor and game.ReplicatedStorage.GameData.LatestRoom.Value == 1 then
        openedthefirstdoor = true
        
        -- Sincroniza o tempo de início para todos no servidor
        if startTimeValue.Value == 0 then
            startTimeValue.Value = workspace:GetServerTimeNow()
        end
        
        ShowCaption("Old Hardcore Initiated.", 5)
        task.wait(3)
        ShowCaption("Idc or whatever, have fun " .. game.Players.LocalPlayer.Name .. ".", 4)
        task.wait(5)
        ShowCaption("If you got your stamina broken when not crouching, just enter a closet while crouched.", 6)

        -- [CRONOGRAMA DE ENTIDADES SINCRONIZADO]
        
        -- 1. RIPPER: Loop Infinito
        task.spawn(function()
            local cycle = 0
            while true do
                SyncWait(cycle + 120)
                game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait()
                LoadEntity("Ripper")
                
                SyncWait(cycle + 360) -- 120 + 240
                game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait()
                LoadEntity("Ripper")
                
                cycle = cycle + 360
            end
        end)

        -- 2. REBOUND: 2 Vezes
        task.spawn(function()
            SyncWait(320)
            game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait()
            LoadEntity("Rebound")
            
            SyncWait(770) -- 320 + 450
            game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait()
            LoadEntity("Rebound")
        end)

        -- 3. DEER GOD: 1 Vez
        task.spawn(function()
            SyncWait(420)
            LoadEntity("DeerGod")
        end)

        -- 4. CEASE: Loop Infinito
        task.spawn(function()
            local cycle = 0
            while true do
                SyncWait(cycle + 160)
                LoadEntity("Cease")
                
                SyncWait(cycle + 390) -- 160 + 230
                LoadEntity("Cease")
                
                cycle = cycle + 390
            end
        end)

        -- 5. SHOCKER: Aleatório (Mantido individual por design)
        task.spawn(function()
            while true do
                task.wait(math.random(30, 70))
                LoadEntity("Shocker")
            end
        end)
    end
end)

-- [VERIFICAÇÃO DE PORTA 0]
if game.ReplicatedStorage.GameData.LatestRoom.Value ~= 0 then
    ShowCaption("EXECUTOR: Script Not Loaded. Please go to Door 0 to begin.", 6)
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.Health = 0
    end
    return
else
    ShowCaption("EXECUTOR: Script Loaded.", 6)
end
