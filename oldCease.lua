-- XENO GITHUB MODEL LOADER (.rbxm / .rbxmx)
local G = getgenv()

G.LoadGithubModel = function(url)
    if not (writefile and getcustomasset and request and isfile) then return nil end
    
    -- Create consistent filename from URL
    local function getHash(str)
        local hash = 0
        for i = 1, #str do
            hash = (hash * 31 + string.byte(str, i)) % 2^32
        end
        return tostring(hash)
    end
    
    local fileName = "cease_old_" .. getHash(url) .. ".rbxm"
    
    -- Check if file already exists
    if not isfile(fileName) then
        local response = request({Url = url, Method = "GET"})
        if response.StatusCode ~= 200 then return nil end
        writefile(fileName, response.Body)
    end
    
    local assetId = getcustomasset(fileName)
    local success, result = pcall(function()
        return game:GetObjects(assetId)[1]
    end)
    
    if success and result then 
        -- AUTOMATICALLY CLONE so you get a fresh instance every time
        return result:Clone()
    end
    
    -- Clean up corrupted file
    pcall(function() if delfile then delfile(fileName) end end)
    
    return nil
end

local function Cease()
    local ambruhspeed = 40
    local DEF_SPEED = 9999
    local storer = ambruhspeed
    local ambruhheight = Vector3.new(0, 3.4, 0)
    local repStorage = game.ReplicatedStorage
    local gameData = repStorage.GameData
    local latestRoom = gameData.LatestRoom -- Variável correta
    local currentRooms = workspace.CurrentRooms
    local entity = nil
    local killed = false
    local rawUrl = "https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/main/oldCease.rbxm"
    local cameraShaker = require(game.ReplicatedStorage.CameraShaker)
    local camera = workspace.CurrentCamera
    local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
        camera.CFrame = camera.CFrame * cf
    end)
    camShake:Start()
    camShake:Shake(cameraShaker.Presets.Earthquake)

    if G.LoadGithubModel then
        entity = G.LoadGithubModel(rawUrl)
        if entity then
            entity.Parent = workspace
        end
    end

    if not entity then return end

    local entityPart = entity:FindFirstChildWhichIsA("BasePart")
    local tweenLights = TweenInfo.new(1)
    local color = {Color = Color3.fromRGB(0, 0, 255)} -- Azul do Cease
    for i, v in pairs(currentRooms:GetDescendants()) do
        if v:IsA("Light") then
            game.TweenService:Create(v, tweenLights, color):Play()
            if v.Parent.Name == "LightFixture" then
                game.TweenService:Create(v.Parent, tweenLights, color):Play()
            end
        end
    end
    wait(2)

    local function canSeeTarget(target, size)
        if killed == true then return end
        local origin = entityPart.Position
        local direction = (target.HumanoidRootPart.Position - origin).unit * size
        local ray = Ray.new(origin, direction)
        local hit, pos = workspace:FindPartOnRay(ray, entityPart)
        if hit and hit:IsDescendantOf(target) then
            killed = true
            return true
        end
        return false
    end

    local function GetTime(dist, speed)
        return dist / speed
    end

    spawn(function()
        while entity ~= nil and entity.Parent ~= nil and entityPart ~= nil do 
            wait(0.01)
            local v = game.Players.LocalPlayer
            if v.Character ~= nil and v.Character:FindFirstChild("HumanoidRootPart") then
                -- Lógica de movimento preservada: se mexeu enquanto ele vê, morre
                if canSeeTarget(v.Character, 60) and v.Character.Humanoid.MoveDirection.Magnitude > 0 then
                    v.Character.Humanoid:TakeDamage(100)
                    game.ReplicatedStorage.GameStats["Player_".. v.Character.Name].Total.DeathCause.Value = "Cease"
                    firesignal(game.ReplicatedStorage.Bricks.DeathHint.OnClientEvent, {"You died to who you call Cease..","Do not move while its in your sight"})
                end
            end

            if v.Character ~= nil and (entityPart.Position - v.Character.HumanoidRootPart.Position).magnitude <= 60 then
                camShake:ShakeOnce(7, 15, 0.5, 1,1,6)
            end
        end
    end)

    ambruhspeed = DEF_SPEED
    
    -- CORREÇÃO DO LOOP: de 1 até o valor da última sala
    for i = 1, latestRoom.Value do 
        -- Procuramos o nome da sala como String (tostring(i))
        local room = currentRooms:FindFirstChild(tostring(i))
        if room then
            local nodes = room:FindFirstChild("Nodes")
            if nodes then
                -- Movendo pelos nós da sala
                for v = 1, #nodes:GetChildren() do
                    local node = nodes:FindFirstChild(tostring(v))
                    if node then
                        local dist = (entityPart.Position - node.Position).magnitude
                        -- Lógica de tempo original preservada
                        local jerk = game.TweenService:Create(entityPart, TweenInfo.new(GetTime(dist, ambruhspeed), Enum.EasingStyle.Linear), {CFrame = node.CFrame + ambruhheight})
                        jerk:Play()
                        jerk.Completed:Wait()
                        
                        -- Reseta para a velocidade normal após o primeiro movimento
                        ambruhspeed = storer 
                    end
                end
            end
        end
    end

    entityPart.Anchored = false
    entityPart.CanCollide = false
    game.Debris:AddItem(entity, 5)
end

spawn(Cease)
