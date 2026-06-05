-- XENO GITHUB MODEL LOADER (.rbxm / .rbxmx)
local G = getgenv()

-- Garantindo que a função exista no ambiente Global
G.LoadGithubModel = function(url)
    if not (writefile and getcustomasset and request and isfile and delfile) then
        warn("Missing required functions: writefile, getcustomasset, request, isfile, or delfile")
        return nil
    end
    
    -- Generate a consistent filename based on URL (so we can check if already downloaded)
    local function getFileNameFromUrl(url)
        -- Extract model name from URL or create hash
        local modelName = url:match("([^/]+)%.rbxm$") or url:match("([^/]+)%.rbxmx$") or "model"
        -- Remove special characters
        modelName = modelName:gsub("[^%w_%-]", "_")
        return "deer_god_" .. modelName .. ".rbxm"
    end
    
    local fileName = getFileNameFromUrl(url)
    
    -- Check if file already exists
    local fileExists = false
    local fileCheckSuccess, fileExistsResult = pcall(function()
        return isfile(fileName)
    end)
    
    if fileCheckSuccess and fileExistsResult then
        fileExists = true
        print("File already exists: " .. fileName)
    end
    
    local responseBody = nil
    
    -- Only download if file doesn't exist
    if not fileExists then
        print("Downloading model from: " .. url)
        
        local response = request({
            Url = url,
            Method = "GET"
        })
        
        if response.StatusCode ~= 200 then
            warn("Failed to download model. Status code: " .. response.StatusCode)
            return nil
        end
        
        responseBody = response.Body
        
        -- Write the file
        local writeSuccess, writeError = pcall(function()
            writefile(fileName, responseBody)
        end)
        
        if not writeSuccess then
            warn("Failed to write file: " .. tostring(writeError))
            return nil
        end
        
        print("File saved: " .. fileName)
    else
        -- File exists, read it
        local readSuccess, fileContent = pcall(function()
            return readfile(fileName)
        end)
        
        if readSuccess then
            responseBody = fileContent
            print("Using cached file: " .. fileName)
        else
            warn("Failed to read existing file: " .. tostring(fileContent))
            -- File might be corrupted, delete and retry download
            pcall(function() delfile(fileName) end)
            return G.LoadGithubModel(url) -- Retry recursively
        end
    end
    
    -- Get custom asset
    local assetId
    local assetSuccess, assetResult = pcall(function()
        return getcustomasset(fileName)
    end)
    
    if not assetSuccess then
        warn("Failed to get custom asset: " .. tostring(assetResult))
        return nil
    end
    
    assetId = assetResult
    
    -- Load the model
    local model
    local loadSuccess, loadResult = pcall(function()
        return game:GetObjects(assetId)[1]
    end)
    
    if not loadSuccess then
        warn("Failed to load model: " .. tostring(loadResult))
        -- Clean up corrupted file
        pcall(function() delfile(fileName) end)
        return nil
    end
    
    model = loadResult
    
    if not model then
        warn("Model is nil after loading")
        return nil
    end
    
    print("Model loaded successfully: " .. fileName)
    return model
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
    if not game.ReplicatedStorage:FindFirstChild("ClientModules") then return end
    if not game.ReplicatedStorage.ClientModules:FindFirstChild("Module_Events") then return end
    if not workspace:FindFirstChild("CurrentRooms") then return end
    local required = require(game.ReplicatedStorage.ClientModules.Module_Events)
    local currentRooms = workspace:FindFirstChild("CurrentRooms")
    local latestRoomInt = game.ReplicatedStorage.GameData.LatestRoom
    local latestRoomModel = currentRooms:FindFirstChild(latestRoomInt.Value)
    required.flickerLights(latestRoomModel, 74)
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
                required.breakLights(room)
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
