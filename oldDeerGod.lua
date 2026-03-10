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

local function DeerGod()
    local ambruhspeed = 15
    local DEF_SPEED = 9999
    local storer = ambruhspeed
    local ambruhheight = Vector3.new(0, 3.4, 0)
    local repStorage = game.ReplicatedStorage
    local gameData = repStorage.GameData
    local latestRoom = gameData.LatestRoom
    local currentRooms = workspace.CurrentRooms
    local entity = nil
    local killed = false
    local rawUrl = "https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/main/oldDeerGod.rbxm"

    -- CORREÇÃO DE ESCOPO: Atribuindo o retorno à variável local correta
    if G.LoadGithubModel then
        entity = G.LoadGithubModel(rawUrl)
        if entity then
            entity.Parent = workspace
        end
    end

    if not entity then return end

    local entityPart = entity:FindFirstChildWhichIsA("BasePart")
    local function canSeeTarget(target, size)
        if killed == true then
            return
        end

        local origin = entityPart.Position
        local direction = (target.HumanoidRootPart.Position - origin).unit * size
        local ray = Ray.new(origin, direction)

        local hit, pos = workspace:FindPartOnRay(ray, entityPart)

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
    wait(1)
    spawn(function()
        while entity ~= nil and entityPart ~= nil do wait(0.01)
            local v = game.Players.LocalPlayer
            if v.Character ~= nil and v.Character.HumanoidRootPart then
                if canSeeTarget(v.Character, 50) and not v.Character:GetAttribute("Hiding") then
                    v.Character.Humanoid:TakeDamage(100)
                    game.ReplicatedStorage.GameStats["Player_".. v.Character.Name].Total.DeathCause.Value = "Deer God"
                    firesignal(game.ReplicatedStorage.Bricks.DeathHint.OnClientEvent, {"You died to who you call Dear god..","Avoid eye contact, and try running", "Closets wont work."})
                end
            end
        end
    end)

    ambruhspeed = DEF_SPEED
    for i = 1, latestRoom.Value + 1 do
        if currentRooms:FindFirstChild(i) then
            local room = currentRooms[i]
            if room and room:FindFirstChild("Nodes") then
                local nodes = room:FindFirstChild("Nodes")
                for v = 1, #nodes:GetChildren() do
                    if nodes:FindFirstChild(v) then
                        local node = nodes[v]
                        local dist = (entityPart.Position - node.Position).magnitude
                        local jerk = game.TweenService:Create(entityPart, TweenInfo.new(GetTime(dist, ambruhspeed), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0,false,0), {CFrame = node.CFrame + ambruhheight})
                        jerk:Play()
                        jerk.Completed:Wait()
                        ambruhspeed = storer
                    end
                end
            end
        end
    end
    game.TweenService:Create(entityPart, TweenInfo.new(1.5), {CFrame = entityPart.CFrame * CFrame.new(0,-80,0)}):Play()
    game.Debris:AddItem(entity, 1.5)
end
spawn(DeerGod)
