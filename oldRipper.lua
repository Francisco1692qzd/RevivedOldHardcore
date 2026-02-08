-- XENO GITHUB MODEL LOADER (.rbxm / .rbxmx)
local G = getgenv()

-- Garantindo que a função exista no ambiente Global
G.LoadGithubModel = function(url)
    if not (writefile and getcustomasset and request) then
        return nil
    end
    local response = request({Url = url, Method = "GET"})
    if response.StatusCode ~= 200 then return nil end
    local fileName = "temp_model_" .. tick() .. ".rbxm"
    writefile(fileName, response.Body)
    local assetId = getcustomasset(fileName)
    local success, result = pcall(function()
        return game:GetObjects(assetId)[1]
    end)
    if success and result then return result end
    return nil
end

local function Ripper()
    local breakMove = false
    local killed = false
    local repStorage = game.ReplicatedStorage
    local gameData = repStorage.GameData
    local latestRoom = gameData.LatestRoom
    local currentRooms = workspace.CurrentRooms
    local entity = nil
    local ambruhspeed = 100
    local DEF_SPEED = 99999 -- MANTIDO original
    local storer = ambruhspeed
    local ambruhheight = Vector3.new(0,1.2,0)
    local cameraShaker = require(repStorage.CameraShaker)
    local camera = workspace.CurrentCamera
    local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
        camera.CFrame = camera.CFrame * cf
    end)
    camShake:Start()
    camShake:Shake(cameraShaker.Presets.Earthquake)
    local rawUrl = "https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/main/oldRipper.rbxml.rbxm"

    -- CORREÇÃO DE ESCOPO: Atribuindo o retorno à variável local correta
    if G.LoadGithubModel then
        entity = G.LoadGithubModel(rawUrl)
        if entity then
            entity.Parent = workspace
        end
    end

    if not entity then return end -- Se falhar, para aqui sem quebrar o resto
    
    local tweenLights = TweenInfo.new(1)
    local color = {Color = Color3.fromRGB(255, 0, 0)}
    local spawnSound = Instance.new("Sound")
    spawnSound.Parent = workspace
    spawnSound.SoundId = "rbxassetid://9125713501"
    spawnSound.PlaybackSpeed = 0.6
    spawnSound.Volume = 10
    local pitchShift = Instance.new("PitchShiftSoundEffect")
    pitchShift.Parent = spawnSound
    pitchShift.Octave = 0.875
    spawnSound:Play() game.Debris:AddItem(spawnSound, 16)
    
    local entityPart = entity:FindFirstChildWhichIsA("BasePart")
    
    for i, v in pairs(currentRooms:GetDescendants()) do
        if v:IsA("Light") then
            game.TweenService:Create(v, tweenLights, color):Play()
            if v.Parent.Name == "LightFixture" then
                game.TweenService:Create(v.Parent, tweenLights, color):Play()
            end
        end
    end

    local function canSeeTarget(target, size)
        if killed == true then return end
        local origin = entityPart.Position
        local direction = (target.HumanoidRootPart.Position - origin).unit * size
        local ray = Ray.new(origin, direction)
        local hit = workspace:FindPartOnRay(ray, entityPart)
        if hit then
            if hit:IsDescendantOf(target) then
                killed = true
                return true
            end
        else
            return false
        end
    end

    local function GetTime(dist, speed)
        return dist / speed
    end

    spawn(function()
        while entityPart ~= nil and entity ~= nil do wait(0.2)
            local v = game.Players.LocalPlayer
            if v.Character ~= nil and v.Character.HumanoidRootPart then
                if canSeeTarget(v.Character, 50) and not v.Character:GetAttribute("Hiding") then
                    breakMove = true
                    -- Toda a sua lógica de GUI e Jumpscare preservada abaixo
                    local gui = Instance.new("ScreenGui", v:WaitForChild("PlayerGui"))
                    gui.Name = "Noise"
                    gui.IgnoreGuiInset = true
                    local img = Instance.new("ImageLabel", gui)
                    img.Size = UDim2.new(1, 0, 1, 0)
                    img.BackgroundTransparency = 1
                    img.Image = "rbxassetid://236542974"
                    img.ImageTransparency = 1

                    coroutine.wrap(function()
                        local char = v.Character
                        local ripper = entityPart
                        local clone = ripper and ripper:Clone()
                        if not clone then return end
                        clone.Parent = workspace
                        clone.Position = ripper.Position
                        for _, x in ipairs(clone:GetDescendants()) do
                            if x:IsA("ParticleEmitter") then
                                spawn(function() x.Rate = 9999; wait(0.25); x.TimeScale = 0.0 end)
                            elseif x:IsA("Sound") then x.Volume = 0 end
                        end
                        entity:Destroy()
                        local static = Instance.new("Sound", workspace)
                        static.SoundId = "rbxassetid://372770465"
                        static.Volume = 10
                        static.Pitch = 0.7
                        local anchor = Instance.new("Part", workspace)
                        anchor.Name = "ripperAnchor"
                        anchor.Anchored = true
                        anchor.CanCollide = false
                        anchor.Transparency = 1
                        anchor.CFrame = workspace.CurrentCamera.CFrame
                        char:FindFirstChild("HumanoidRootPart").Anchored = true
                        workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
                        local viewLoop = true
                        spawn(function()
                            while viewLoop do
                                workspace.CurrentCamera.CFrame = anchor.CFrame
                                img.Image = "rbxassetid://"..({8482795900,236542974,184251462,236777652})[math.random(1,4)]
                                game["Run Service"].RenderStepped:Wait()
                            end
                        end)
                        game.TweenService:Create(anchor, TweenInfo.new(0.3), {CFrame = CFrame.lookAt(anchor.Position, clone.Position)}):Play()
                        wait(1)
                        game.TweenService:Create(img, TweenInfo.new(2), {ImageTransparency = 0}):Play()
                        static:Play()
                        wait(2)
                        viewLoop = false
                        game.TweenService:Create(img, TweenInfo.new(1), {ImageTransparency = 1}):Play()
                        static:Destroy()
                        char:FindFirstChild("HumanoidRootPart").Anchored = false
                        game.ReplicatedStorage.GameStats["Player_" .. v.Character.Name].Total.DeathCause.Value = "Ripper"
                        game.ReplicatedStorage.GameStats["Player_" .. v.Character.Name]["1"].DeathCause.Value = "Ripper"
                        char:FindFirstChildWhichIsA("Humanoid"):TakeDamage(100)
                    end)()
                end
            end
            if v.Character ~= nil and v.Character.HumanoidRootPart and (entityPart.Position - v.Character.HumanoidRootPart.Position).magnitude <= 60 then
                camShake:Start()
                camShake:ShakeOnce(15, 25, 0, 2, 1, 6)
            end
            if breakMove then break end
        end
    end)

    -- MOVIMENTO POR NODES ORIGINAL
    entityPart.Ambush:Stop()
    entityPart.Ambush.Volume = 10
    wait(8)
    entityPart.Ambush:Play()
    game.TweenService:Create(entityPart.Ambush, TweenInfo.new(6), {Volume = 0.8}):Play()
    ambruhspeed = DEF_SPEED

    for i = 1, latestRoom.Value do
        local room = currentRooms:FindFirstChild(tostring(i))
        if room and room:FindFirstChild("Nodes") then
            local nodes = room.Nodes
            for v_idx = 1, #nodes:GetChildren() do
                local node = nodes:FindFirstChild(tostring(v_idx))
                if node then
                    if breakMove then break end
                    local dist = (entityPart.Position - node.Position).magnitude
                    local bruh = game.TweenService:Create(entityPart, TweenInfo.new(GetTime(dist, ambruhspeed), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0,false,0), {CFrame = node.CFrame + ambruhheight})
                    bruh:Play()
                    bruh.Completed:Wait()
                    ambruhspeed = storer
                    if room.Name == tostring(latestRoom.Value) then
                        pcall(function() room.Door.ClientOpen:FireServer() end)
                    end
                end
            end
        end
        if breakMove then break end
    end

    local slam = Instance.new("Sound", entityPart)
    slam.Volume = 10
    slam.SoundId = "rbxassetid://1837829565"
    pcall(function() workspace.CurrentRooms[latestRoom.Value].Door.ClientOpen:FireServer() end)
    camShake:Shake(cameraShaker.Presets.Explosion)
    slam:Play()
    wait(1)
    entityPart.Anchored = false
    entityPart.CanCollide = false
    game.Debris:AddItem(entity, 5)
end

spawn(Ripper)
