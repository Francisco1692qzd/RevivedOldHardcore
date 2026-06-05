-- XENO GITHUB MODEL LOADER (.rbxm / .rbxmx)
local G = getgenv()

-- Garantindo que a função exista no ambiente Global
G.LoadGithubModel = function(url)
    if not (writefile and getcustomasset and request and isfile and delfile and readfile) then
        warn("Missing required functions: writefile, getcustomasset, request, isfile, delfile, or readfile")
        return nil
    end
    
    -- Generate a consistent filename based on URL
    local function getFileNameFromUrl(url)
        local modelName = url:match("([^/]+)%.rbxm$") or url:match("([^/]+)%.rbxmx$") or "model"
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
        
        local writeSuccess, writeError = pcall(function()
            writefile(fileName, response.Body)
        end)
        
        if not writeSuccess then
            warn("Failed to write file: " .. tostring(writeError))
            return nil
        end
        
        print("File saved: " .. fileName)
    else
        print("Using cached file: " .. fileName)
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
    -- Check all required services first
    local repStorage = game:GetService("ReplicatedStorage")
    local workspace = game:GetService("Workspace")
    
    if not repStorage then
        warn("ReplicatedStorage not found")
        return
    end
    
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
    local latestRoomInt = repStorage:FindFirstChild("GameData") and repStorage.GameData:FindFirstChild("LatestRoom")
    
    if not latestRoomInt then
        warn("LatestRoom not found in GameData")
        return
    end
    
    local latestRoomModel = currentRooms:FindFirstChild(tostring(latestRoomInt.Value))
    
    -- Initialize the events module first
    --[[if required.init then
        required.init()
    end--]]
    
    -- Flicker lights safely
    if latestRoomModel and required.flickerLights then
        local success, err = pcall(function()
            required.flickerLights(latestRoomModel, 74)
        end)
        if not success then
            warn("flickerLights failed: " .. tostring(err))
        end
    end
    
    -- Camera shaker setup
    local cameraShaker = repStorage:FindFirstChild("CameraShaker")
    if not cameraShaker then
        warn("CameraShaker module not found")
        return
    end
    
    local cameraShakerModule = require(cameraShaker)
    local camera = workspace.CurrentCamera
    
    if not camera then
        warn("CurrentCamera not found")
        return
    end
    
    local camShake = cameraShakerModule.new(Enum.RenderPriority.Camera.Value, function(cf)
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
    
    -- Load the model
    if G.LoadGithubModel then
        local success, result = pcall(function()
            return G.LoadGithubModel(rawUrl)
        end)
        if success and result then
            entity = result
            entity.Parent = workspace
        else
            warn("Failed to load model: " .. tostring(result))
        end
    end
    
    if not entity then 
        warn("Entity is nil, exiting DeerGod")
        return 
    end
    
    local entityPart = entity:FindFirstChildWhichIsA("BasePart")
    if not entityPart then
        warn("Entity has no BasePart")
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
    spawn(function()
        while entity ~= nil and entityPart ~= nil and entityPart.Parent ~= nil do 
            wait(0.1) -- Changed from 0.01 to 0.1 for performance
            
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
                            firesignal(deathHint.OnClientEvent, {
                                "You died to who you call Dear god..",
                                "Avoid eye contact, and try running",
                                "Closets wont work."
                            })
                        end
                    end
                end
            end
        end
    end)
    
    -- Camera shake thread
    spawn(function()
        while entity ~= nil and entityPart ~= nil and entityPart.Parent ~= nil do 
            wait(1)
            if camShake then
                camShake:Shake(cameraShakerModule.Presets.Earthquake)
            end
        end
    end)
    
    -- Movement logic
    ambruhspeed = DEF_SPEED
    
    local latestRoomValue = latestRoomInt.Value
    for i = 1, latestRoomValue + 1 do
        local room = currentRooms:FindFirstChild(tostring(i))
        if room and room:FindFirstChild("Nodes") then
            local nodes = room.Nodes
            
            -- Break lights in room
            if required.breakLights then
                pcall(function() required.breakLights(room) end)
            end
            
            -- Get all nodes and sort them by name or position
            local nodeList = {}
            for _, node in ipairs(nodes:GetChildren()) do
                table.insert(nodeList, node)
            end
            
            -- Sort nodes numerically if possible
            table.sort(nodeList, function(a, b)
                local numA = tonumber(a.Name) or 0
                local numB = tonumber(b.Name) or 0
                return numA < numB
            end)
            
            for _, node in ipairs(nodeList) do
                if entityPart and entityPart.Parent then
                    local dist = (entityPart.Position - node.Position).magnitude
                    local jerk = game.TweenService:Create(entityPart, TweenInfo.new(GetTime(dist, ambruhspeed), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0), {CFrame = node.CFrame + ambruhheight})
                    jerk:Play()
                    jerk.Completed:Wait()
                    ambruhspeed = storer
                else
                    break
                end
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
end

-- Start the script
spawn(DeerGod)
