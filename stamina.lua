-- [SISTEMA DE MOVIMENTAÇÃO: EXAUSTÃO COMPLETA E RECARGA GRADUAL]
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local Player = game.Players.LocalPlayer

local stamina = 100
local maxStamina = 100
local isExhausted = false
local sprinting = false
local crouching = false
local wasSeekActive = false

local WALK_SPEED = 12
local RUN_SPEED = 19
local CROUCH_SPEED = 9

-- GUI (Canto Inferior Direito)
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

-- Controles
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
            sprinting = false
            isExhausted = false -- Reseta estado para não bugar no Seek
            stamina = maxStamina
            if breathSound then breathSound:Stop() end
        else
            container.Visible = true
            
            -- Lógica de Exaustão (RECARGA OBRIGATÓRIA)
            if isExhausted then
                hum.WalkSpeed = WALK_SPEED
                sprinting = false -- Bloqueia corrida
                stamina = math.min(maxStamina, stamina + 0.4) -- Sobe devagar
                bar.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Mantém vermelho
                
                if not breathSound.IsPlaying then breathSound:Play() end
                
                if stamina >= maxStamina then
                    isExhausted = false
                    bar.BackgroundColor3 = Color3.fromRGB(255, 222, 189)
                    if breathSound then breathSound:Stop() end
                end
            -- Lógica Normal
            elseif crouching then
                hum.WalkSpeed = CROUCH_SPEED
                stamina = math.min(maxStamina, stamina + 0.8)
                sprinting = false
            elseif sprinting and isMoving and stamina > 0 then
                hum.WalkSpeed = RUN_SPEED
                stamina = math.max(0, stamina - 1.2)
                
                if stamina <= 0 then
                    isExhausted = true
                end
            else
                hum.WalkSpeed = WALK_SPEED
                stamina = math.min(maxStamina, stamina + 0.5)
            end

            -- Atualização Visual Suave
            local targetSize = UDim2.new(stamina / maxStamina, 0, 1, 0)
            TS:Create(bar, TweenInfo.new(0.1), {Size = targetSize}):Play()
            
            -- Auto-Hide
            local targetAlpha = (stamina >= maxStamina and not isExhausted) and 1 or 0
            container.BackgroundTransparency = targetAlpha + 0.4
            bar.BackgroundTransparency = targetAlpha
            stroke.Transparency = targetAlpha
        end
    end
end)
