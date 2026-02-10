-- [CUSTOM ROOM LOADER - CANDLE ROOM DEFINITIVE EDITION]
local G = getgenv()
local LatestRoom = game.ReplicatedStorage.GameData.LatestRoom
local Player = game.Players.LocalPlayer
local TS = game:GetService("TweenService")

-- 1. GARANTINDO O XENO LOADER NO AMBIENTE
if not G.LoadGithubModel then
    G.LoadGithubModel = function(url)
        if not (writefile and getcustomasset and request) then return nil end
        local response = request({Url = url, Method = "GET"})
        if response.StatusCode ~= 200 then return nil end
        local fileName = "temp_model_" .. tick() .. ".rbxm"
        writefile(fileName, response.Body)
        local assetId = getcustomasset(fileName)
        local success, result = pcall(function()
            return game:GetObjects(assetId)[1]
        end)
        return success and result or nil
    end
end

-- 2. FUNÇÃO DE CAPTION
local function ShowCaption(text, duration)
    local pGui = Player:WaitForChild("PlayerGui")
    if pGui:FindFirstChild("OldHardcoreCaption") then pGui.OldHardcoreCaption:Destroy() end
    local screenGui = Instance.new("ScreenGui", pGui)
    screenGui.Name = "OldHardcoreCaption"
    screenGui.IgnoreGuiInset = true
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
    
    TS:Create(captionLabel, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    task.delay(duration or 4, function()
        if captionLabel then
            TS:Create(captionLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
            task.wait(0.5) screenGui:Destroy()
        end
    end)
end

-- 3. LÓGICA DE DETECÇÃO E SUBSTITUIÇÃO
local lastCheckedRoom = -1
local firstRoomInARow = false

local function CheckAndReplace()
    if lastCheckedRoom == LatestRoom.Value then return end
    lastCheckedRoom = LatestRoom.Value
    
    local roomNum = tostring(LatestRoom.Value)
    local roomsFolder = workspace:FindFirstChild("CurrentRooms") or workspace:FindFirstChild("Rooms")
    local roomModel = roomsFolder and roomsFolder:FindFirstChild(roomNum) or workspace:FindFirstChild(roomNum)
    
    if roomModel then
        local fakeDoor = roomModel:FindFirstChild("FakeDoor_Hotel")
        if fakeDoor and not firstRoomInARow then
            local targetCFrame = fakeDoor:GetPivot()
            firstRoomInARow = true
            
            local candleRoom = G.LoadGithubModel("https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/main/candleroom.rbxm")
            
            if candleRoom then
                candleRoom.Name = "CustomCandleRoom_" .. LatestRoom.Value
                candleRoom.Parent = roomModel
                
                local startPart = candleRoom:FindFirstChild("RoomStart") or candleRoom.PrimaryPart
                if startPart then
                    candleRoom.PrimaryPart = startPart
                    candleRoom:SetPrimaryPartCFrame(targetCFrame * CFrame.Angles(0, math.rad(180), 0))
                    fakeDoor:Destroy()
                    
                    local newDoorRoom = candleRoom:FindFirstChild("Door")
                    local newDoorOpenRoom = candleRoom:FindFirstChild("DoorOpenDoor")
                    local knob = newDoorRoom and newDoorRoom:FindFirstChild("Knob")
                    local promptnewDoor = knob and knob:FindFirstChild("DangIt") and knob.DangIt:FindFirstChild("ProximityPrompt")
                    
                    local eyeOutside = candleRoom:FindFirstChild("EyeOutside")
                    local eyeInside = candleRoom:FindFirstChild("Eye")
                    local eyeHitbox = candleRoom:FindFirstChild("EyePart")
                    local radio = candleRoom:FindFirstChild("Radio")
                    local crate = candleRoom:FindFirstChild("WoodenCrate")

                    if promptnewDoor then
                        promptnewDoor.Triggered:Connect(function()
                            local slam = TS:Create(newDoorRoom, TweenInfo.new(0.6, Enum.EasingStyle.Back), {CFrame = newDoorOpenRoom.CFrame})
                            slam:Play()
                            if newDoorRoom:FindFirstChild("SlamOpen") then newDoorRoom.SlamOpen:Play() end
                            newDoorRoom.CanCollide = false
                            promptnewDoor:Destroy()
                        end)
                    end

                    local eyeDeb = false
                    if eyeHitbox then
                        eyeHitbox.Touched:Connect(function(hit)
                            if not eyeDeb and hit.Parent:FindFirstChild("Humanoid") then
                                eyeDeb = true
                                if eyeInside and eyeOutside then
                                    TS:Create(eyeInside, TweenInfo.new(4.2), {CFrame = eyeOutside.CFrame}):Play()
                                end
                                
                                task.delay(2.4, function()
                                    local shelf = candleRoom:FindFirstChild("Modular_Bookshelf")
                                    local fallenTarget = shelf and shelf:FindFirstChild("Fallen")
                                    local base = shelf and shelf:FindFirstChild("Base")
                                    
                                    if shelf and fallenTarget then
                                        shelf.PrimaryPart = base or shelf:FindFirstChildWhichIsA("BasePart")
                                        local shelfTween = TS:Create(shelf.PrimaryPart, TweenInfo.new(1.2, Enum.EasingStyle.Bounce), {CFrame = fallenTarget.CFrame})
                                        fallenTarget.Transparency = 1
                                        shelfTween:Play()
                                        if base then
                                            if base:FindFirstChild("Fallen") then base.Fallen:Play() end
                                            task.wait(0.8)
                                            if base:FindFirstChild("Bang") then base.Bang:Play() end
                                        end
                                    end
                                end)
                                
                                task.wait(6)
                                TS:Create(game.Lighting, TweenInfo.new(5), {FogEnd = 150, FogColor = Color3.new(0,0,0)}):Play()
                                
                                -- [RESTORED AMBIENT SOUND]
                                local ambientSound = Instance.new("Sound", workspace)
                                ambientSound.SoundId = "rbxassetid://9119386571"
                                ambientSound.Volume = 1.5
                                ambientSound:Play()
                                game.Debris:AddItem(ambientSound, 20) -- Garante que o som limpe depois
                                
                                eyeHitbox:Destroy()
                            end
                        end)
                    end

                    if radio and radio:FindFirstChild("Sound") then
                        local radioSound = radio.Sound
                        task.delay(5, function()
                            local startTime = tick()
                            local duration = math.random(4, 6)
                            task.spawn(function()
                                while tick() - startTime < duration do
                                    radioSound.PlaybackSpeed = math.random(5, 25) / 10
                                    radioSound.Volume = math.random(6, 12) / 10
                                    task.wait(math.random(5, 12) / 100)
                                end
                                local dieTween = TS:Create(radioSound, TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                                    PlaybackSpeed = 0,
                                    Volume = 0
                                })
                                dieTween:Play()
                                dieTween.Completed:Connect(function() radioSound:Stop() end)
                            end)
                        end)
                    end

                    if crate then
                        local cratePrompt = crate:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if cratePrompt then
                            cratePrompt.Triggered:Connect(function()
                                ShowCaption("You find nothing... but an unvalued Candle...", 4)
                                cratePrompt:Destroy()
                                task.delay(2.3, function()
                                    local candle = G.LoadGithubModel("https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/main/oldCandle.rbxm")
                                    if candle then
                                        candle.Parent = Player.Character
                                        local hum = Player.Character:FindFirstChild("Humanoid")
                                        local idleAnim = Instance.new("Animation", candle)
                                        idleAnim.AnimationId = "rbxassetid://10479585177"
                                        local track
                                        candle.Equipped:Connect(function()
                                            track = hum:LoadAnimation(idleAnim)
                                            track.Looped = true
                                            track:Play()
                                        end)
                                        candle.Unequipped:Connect(function()
                                            if track then track:Stop() end
                                        end)
                                    end
                                end)
                                task.wait(5)
                                ShowCaption("I shall recommend to not hold for too long.", 5)
                            end)
                        end
                    end
                end
            end
        end
    end
end

CheckAndReplace()
LatestRoom.Changed:Connect(CheckAndReplace)
