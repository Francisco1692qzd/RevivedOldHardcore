-- XENO GITHUB MODEL LOADER (.rbxm / .rbxmx)
local G = getgenv()

-- Garantindo que a função exista no ambiente Global
G.LoadGithubModel = function(url, forceRefresh, retryCount)
    retryCount = retryCount or 0
    
    -- Max 3 retries
    if retryCount >= 3 then
        warn("Failed to load model after 3 attempts")
        return nil
    end
    
    if not (writefile and getcustomasset and request and isfile and delfile) then
        warn("Missing required functions: writefile, getcustomasset, request, isfile, or delfile")
        return nil
    end
    
    forceRefresh = forceRefresh or false
    
    -- Generate a consistent filename based on URL
    local function getFileNameFromUrl(url)
        local modelName = url:match("([^/]+)%.rbxm$") or url:match("([^/]+)%.rbxmx$") or "model"
        modelName = modelName:gsub("[^%w_%-]", "_")
        return "deer_god_" .. modelName .. ".rbxm"
    end
    
    local fileName = getFileNameFromUrl(url)
    
    -- If retrying, delete potentially corrupted file
    if retryCount > 0 then
        print("Retry " .. retryCount .. ": Cleaning up...")
        wait(1) -- Small delay before retry
        if isfile(fileName) then
            pcall(function() delfile(fileName) end)
            print("Retry " .. retryCount .. ": Deleted cached file")
        end
    end
    
    -- Force refresh: delete existing file
    if forceRefresh and isfile(fileName) then
        pcall(function() delfile(fileName) end)
        print("Force refresh: deleted cached file")
    end
    
    -- Check if file already exists
    local fileExists = isfile(fileName)
    
    if fileExists then
        print("Using cached file: " .. fileName)
    else
        print("Downloading model from: " .. url)
        
        local response = request({
            Url = url,
            Method = "GET"
        })
        
        if response.StatusCode ~= 200 then
            warn("Failed to download model. Status code: " .. response.StatusCode)
            return G.LoadGithubModel(url, forceRefresh, retryCount + 1)
        end
        
        local writeSuccess, writeError = pcall(function()
            writefile(fileName, response.Body)
        end)
        
        if not writeSuccess then
            warn("Failed to write file: " .. tostring(writeError))
            return G.LoadGithubModel(url, forceRefresh, retryCount + 1)
        end
        
        print("File saved: " .. fileName)
    end
    
    -- Get custom asset
    local assetId
    local assetSuccess, assetResult = pcall(function()
        return getcustomasset(fileName)
    end)
    
    if not assetSuccess then
        warn("Failed to get custom asset: " .. tostring(assetResult))
        pcall(function() delfile(fileName) end)
        return G.LoadGithubModel(url, forceRefresh, retryCount + 1)
    end
    
    assetId = assetResult
    
    -- Load the model (clone it so we can reuse the cached version)
    local model
    local loadSuccess, loadResult = pcall(function()
        local objects = game:GetObjects(assetId)
        if objects and #objects > 0 then
            return objects[1]:Clone() -- Clone to allow multiple instances
        end
        return nil
    end)
    
    if not loadSuccess or not loadResult then
        warn("Failed to load model: " .. tostring(loadResult))
        pcall(function() delfile(fileName) end)
        return G.LoadGithubModel(url, forceRefresh, retryCount + 1)
    end
    
    model = loadResult
    print("✅ Model loaded successfully: " .. fileName)
    return model
end

local deerGodThread = nil
local currentEntity = nil

local function DeerGod()
    -- Kill previous instance if running
    if deerGodThread then
        pcall(function()
            if currentEntity then
                currentEntity:Destroy()
                currentEntity = nil
            end
        end)
        deerGodThread = nil
    end
    
    -- Check all required services first
    local repStorage = game:GetService("ReplicatedStorage")
    local workspace = game:GetService("Workspace")
    
    if not repStorage:FindFirstChild("ClientModules") then
        warn("ClientModules not found")
        return
    end
    
    if not repStorage.ClientModules:FindFirstChild("Module_Events") then
        warn("Module_Events not found")
        return
    end
    
    if not workspace:FindFirstChild("CurrentRooms") then
        warn("CurrentRooms not found")
        return
    end
    
    local required = require(repStorage.ClientModules.Module_Events)
    local currentRooms = workspace.CurrentRooms
    local gameData = repStorage:FindFirstChild("GameData")
    
    if not gameData then
        warn("GameData not found")
        return
    end
    
    local latestRoomInt = gameData:FindFirstChild("LatestRoom")
    
    if not latestRoomInt then
        warn("LatestRoom not found in GameData")
        return
    end
    
    local latestRoomValue = latestRoomInt.Value
    local latestRoomModel = currentRooms:FindFirstChild(tostring(latestRoomValue))
    
    -- Initialize the events module first
    if required.init then
        pcall(function() required.init() end)
    end
    
    -- Flicker lights safely
    if latestRoomModel and required.flickerLights then
        pcall(function()
            required.flickerLights(latestRoomModel, 52)
        end)
    end
    
    -- Camera shaker setup
    local cameraShakerModule = repStorage:FindFirstChild("CameraShaker")
    if not cameraShakerModule then
        warn("CameraShaker module not found")
        return
    end
    
    local cameraShaker = require(cameraShakerModule)
    local camera = workspace.CurrentCamera
    
    if not camera then
        warn("CurrentCamera not found")
        return
    end
    
    local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
        if camera then
            camera.CFrame = camera.CFrame * cf
        end
    end)
    camShake:Start()
    
    local entity = nil
    local killed = false
    local ambruhspeed = 15
    local DEF_SPEED = 9999
    local storer = ambruhspeed
    local ambruhheight = Vector3.new(0, 3.4, 0)
    
    local rawUrl = "https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/main/oldDeerGod.rbxm"
    
    -- Load the model (force refresh = false for normal use)
    if G.LoadGithubModel then
        local success, result = pcall(function()
            return G.LoadGithubModel(rawUrl, false) -- Set to true if you want to force re-download
        end)
        if success and result then
            entity = result
            entity.Parent = workspace
            currentEntity = entity -- Store for cleanup
        else
            warn("Failed to load model: " .. tostring(result))
            return
        end
    end
    
    if not entity then 
        warn("Entity is nil, exiting DeerGod")
        return 
    end
    
    local entityPart = entity:FindFirstChildWhichIsA("BasePart")
    if not entityPart then
        warn("Entity has no BasePart")
        entity:Destroy()
        return
    end
    
    local function canSeeTarget(target, size)
        if killed == true then return false end
        
        local playerChar = target
        local humanoidRootPart = playerChar:FindFirstChild("HumanoidRootPart")
        
        if not humanoidRootPart or not entityPart or not entityPart.Parent then
            return false
        end
        
        local origin = entityPart.Position
        local direction = (humanoidRootPart.Position - origin).unit * size
        local ray = Ray.new(origin, direction)
        
        local hit = workspace:FindPartOnRay(ray, entityPart)
        
        if hit and hit:IsDescendantOf(playerChar) then
            killed = true
            return true
        end
        
        return false
    end
    
    local function GetTime(dist, speed)
        if speed <= 0 then speed = 1 end
        return dist / speed
    end
    
    wait(1)
    
    -- Death detection thread
    local deathThread = spawn(function()
        while entity ~= nil and entityPart ~= nil and entityPart.Parent ~= nil do 
            wait(0.1)
            
            local player = game.Players.LocalPlayer
            if not player then continue end
            
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
                local isHiding = character:GetAttribute("Hiding")
                
                if canSeeTarget(character, 50) and not isHiding then
                    character.Humanoid:TakeDamage(100)
                    
                    local gameStats = repStorage:FindFirstChild("GameStats")
                    if gameStats then
                        local playerStats = gameStats:FindFirstChild("Player_" .. character.Name)
                        if playerStats and playerStats:FindFirstChild("Total") then
                            local deathCause = playerStats.Total:FindFirstChild("DeathCause")
                            if deathCause then
                                deathCause.Value = "Deer God"
                            end
                        end
                    end
                    
                    local bricks = repStorage:FindFirstChild("Bricks")
                    if bricks then
                        local deathHint = bricks:FindFirstChild("DeathHint")
                        if deathHint and deathHint.OnClientEvent then
                            pcall(function()
                                firesignal(deathHint.OnClientEvent, {
                                    "You died to who you call Dear god..",
                                    "Avoid eye contact, and try running",
                                    "Closets wont work."
                                })
                            end)
                        end
                    end
                    break
                end
            end
        end
    end)
    
    -- Camera shake thread
    local shakeThread = spawn(function()
        while entity ~= nil and entityPart ~= nil and entityPart.Parent ~= nil do 
            wait(1.8)
            if camShake then
                pcall(function()
                    camShake:Shake(cameraShaker.Presets.Earthquake)
                end)
            end
        end
    end)
    
    -- Movement logic
    ambruhspeed = DEF_SPEED
    
    for i = 1, latestRoomValue + 1 do
        if not entityPart or not entityPart.Parent then break end
        
        local room = currentRooms:FindFirstChild(tostring(i))
        if room and room:FindFirstChild("Nodes") then
            local nodes = room.Nodes
            
            -- Break lights in room
            if required.breakLights then
                pcall(function() required.breakLights(room) end)
            end
            
            -- Get all nodes and sort them
            local nodeList = {}
            for _, node in ipairs(nodes:GetChildren()) do
                table.insert(nodeList, node)
            end
            
            table.sort(nodeList, function(a, b)
                local numA = tonumber(a.Name) or 0
                local numB = tonumber(b.Name) or 0
                return numA < numB
            end)
            
            for _, node in ipairs(nodeList) do
                if not entityPart or not entityPart.Parent then break end
                
                local dist = (entityPart.Position - node.Position).magnitude
                local tweenService = game:GetService("TweenService")
                local jerk = tweenService:Create(entityPart, TweenInfo.new(GetTime(dist, ambruhspeed), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0), {CFrame = node.CFrame + ambruhheight})
                jerk:Play()
                jerk.Completed:Wait()
                ambruhspeed = storer
            end
        end
    end
    
    -- Cleanup
    if entityPart then
        local tweenService = game:GetService("TweenService")
        local fallTween = tweenService:Create(entityPart, TweenInfo.new(1.5), {CFrame = entityPart.CFrame * CFrame.new(0, -80, 0)})
        fallTween:Play()
        fallTween.Completed:Wait()
    end
    
    game:GetService("Debris"):AddItem(entity, 1.5)
    currentEntity = nil
end

-- Start the script (kill previous if running)
if deerGodThread then
    pcall(function()
        if currentEntity then
            currentEntity:Destroy()
        end
    end)
end

deerGodThread = spawn(DeerGod)
