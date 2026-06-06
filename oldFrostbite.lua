local rep = game.ReplicatedStorage
local remotesFolder = rep.Bricks or rep:FindFirstChild("RemotesFolder") or rep
local G = getgenv()

-- [[ Model Loader ]]
G.LoadGithubModel = function(url, retryCount)
    retryCount = retryCount or 0
    
    -- Max 3 retries
    if retryCount >= 3 then
        warn("Failed to load model after 3 attempts")
        return nil
    end
    
    if not (writefile and getcustomasset and request and isfile and delfile) then 
        warn("Missing required functions")
        return nil 
    end

    -- Generate consistent filename from URL
    local function generateFileName(url)
        local hash = 0
        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 2^32
        end
        return "old_Frostbite_" .. tostring(hash) .. ".rbxm"
    end

    local fileName = generateFileName(url)
    
    -- If retrying, delete potentially corrupted file
    if retryCount > 0 and isfile(fileName) then
        pcall(function() delfile(fileName) end)
        print("Retry " .. retryCount .. ": Deleted cached file")
        wait(1) -- Small delay before retry
    end

    -- Check if file exists and try to load it
    local success, exists = pcall(function()
        return isfile and isfile(fileName)
    end)

    if success and exists then
        local assetId = getcustomasset(fileName)
        local loadSuccess, result = pcall(function()
            local objects = game:GetObjects(assetId)
            if objects and #objects > 0 then
                return objects[1]
            end
            return nil
        end)

        if loadSuccess and result then
            local cloneSuccess, cloned = pcall(function()
                return result:Clone()
            end)
            if cloneSuccess and cloned then
                print("Model loaded from cache and cloned")
                return cloned
            end
        end
    end

    -- Download new model if not exists or failed to load
    print("Downloading model from: " .. url)
    local response = request({Url = url, Method = "GET"})
    if response.StatusCode ~= 200 then 
        warn("Download failed (HTTP " .. response.StatusCode .. "), retrying...")
        return G.LoadGithubModel(url, retryCount + 1)
    end

    writefile(fileName, response.Body)
    print("File saved: " .. fileName)
    
    local assetId = getcustomasset(fileName)
    local success, result = pcall(function()
        local objects = game:GetObjects(assetId)
        if objects and #objects > 0 then
            return objects[1]
        end
        return nil
    end)
    
    if success and result then 
        local cloneSuccess, cloned = pcall(function()
            return result:Clone()
        end)
        if cloneSuccess and cloned then
            print("Model downloaded and cloned successfully")
            return cloned
        end
    end
    
    -- Clean up corrupted file and retry
    warn("Failed to load model, retrying...")
    pcall(function() 
        if delfile and isfile(fileName) then 
            delfile(fileName) 
        end 
    end)
    
    return G.LoadGithubModel(url, retryCount + 1)
end

-- [[ Audio Loader ]]
G.LoadGithubAudio = function(url)
	if not (writefile and getcustomasset and request) then return nil end

	-- Generate consistent filename from URL
	local function generateFileName(url)
		local hash = 0
		for i = 1, #url do
			hash = (hash * 31 + string.byte(url, i)) % 2^32
		end
		return "ambienceandambiencefar_" .. tostring(hash) .. ".mp3"
	end

	local fileName = generateFileName(url)

	-- Check if file exists and return it
	local success, exists = pcall(function()
		return isfile and isfile(fileName)
	end)

	if success and exists then
		local assetSuccess, assetId = pcall(function()
			return getcustomasset(fileName)
		end)

		if assetSuccess then
			return assetId
		end
	end

	local cleanUrl = url .. "?t=" .. math.random(1, 100000)
	local response = request({
		Url = cleanUrl,
		Method = "GET",
		Headers = {
			["Accept"] = "audio/mpeg, audio/ogg, application/octet-stream"
		}
	})
	if response.StatusCode ~= 200 then return nil end

	writefile(fileName, response.Body)

	local success, assetId = pcall(function()
		return getcustomasset(fileName)
	end)
	if success then return assetId end
	return nil
end

local raw = "https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/main/oldfrostbite.rbxm"
local AmbienceFrostbiteraw = "https://raw.githubusercontent.com/Francisco1692qzd/Fracture-Mode/main/AmbienceFrostbite.mp3"

task.spawn(function()
	local camera = workspace.CurrentCamera
	local cameraShaker = rep:FindFirstChild("CameraShaker")
	if not cameraShaker then return end

	local shakerModule = require(cameraShaker)
	local camShake = shakerModule.new(Enum.RenderPriority.Camera.Value, function(cf)
		camera.CFrame = camera.CFrame * cf
	end)
	camShake:Start()

	local gameData = rep:WaitForChild("GameData")
	local latestRoom = gameData:WaitForChild("LatestRoom")
	local player = game.Players.LocalPlayer

	local entity = nil
	local height = Vector3.new(0, 4.6, 0)
	local killed = false
	local turn1 = true
	local turn2 = false
	local turn3 = false

	-- Load entity model
	if G.LoadGithubModel then
		entity = G.LoadGithubModel(raw)
		if entity then 
			entity.Parent = workspace
			entity.PrimaryPart = entity:FindFirstChildWhichIsA("BasePart") or entity:FindFirstChild("HumanoidRootPart")
		end
	end

	if not entity or not entity.PrimaryPart then
		warn("Failed to load Frostbite entity properly")
		return
	end

	-- Safe Random Node Placement Check
	local roomFolder = workspace.CurrentRooms:FindFirstChild(tostring(latestRoom.Value))
	local currentNodes = roomFolder and roomFolder:FindFirstChild("Nodes")
	if currentNodes then
		local children = currentNodes:GetChildren()
		if #children > 0 then
			local randomNode = children[math.random(1, #children)]
			entity.PrimaryPart.CFrame = randomNode.CFrame + height
		end
	end

	local ambienceId = G.LoadGithubAudio(AmbienceFrostbiteraw)

	-- Safe particle emitter access
	local staticEffect = entity.PrimaryPart:FindFirstChild("Static Effect")
	if staticEffect and staticEffect:IsA("Sound") then
		staticEffect:Play()
	end

	local part = entity.PrimaryPart:FindFirstChild("Part")
	if part and part:FindFirstChild("ParticleEmitter") then
		part.ParticleEmitter.Enabled = false
	end

	local attachment = entity.PrimaryPart:FindFirstChild("Attachment")
	if attachment then
		local face = attachment:FindFirstChild("face")
		local trauk1 = attachment:FindFirstChild("trauk1")
		if face then face.Enabled = false end
		if trauk1 then trauk1.Enabled = false end
	end

	if ambienceId then
		local ambience = entity.PrimaryPart:FindFirstChild("Ambience")
		local ambienceFar = entity.PrimaryPart:FindFirstChild("AmbienceFar")
		if ambience then
		 	ambience.SoundId = ambienceId
			ambience.TimePosition = 0
		end
		if ambienceFar then 
			ambienceFar.SoundId = ambienceId 
			ambienceFar.TimePosition = 0
		end
		if ambience then ambience:Stop() end
		if ambienceFar then ambienceFar:Stop() end
	end

	-- --- PHASE 1 ---
	task.spawn(function()
		while turn1 == true and entity.PrimaryPart and entity.PrimaryPart.Parent do
			task.wait(0.1)
			camShake:ShakeOnce(1.4, 26, 0, 3.2, 1, 6)
		end
	end)

	task.wait(5.315)
	turn1 = false

	if staticEffect then
		game.TweenService:Create(staticEffect, TweenInfo.new(2), {PlaybackSpeed = 0}):Play()
	end
	task.wait(3.65)

	-- --- PHASE 2 ---
	turn2 = true
	task.spawn(function()
		while turn2 == true and entity.PrimaryPart and entity.PrimaryPart.Parent do
			task.wait(0.1)
			camShake:ShakeOnce(4, 34, 0, 1.6, 1, 6)
		end
	end)

	local light = Instance.new("ColorCorrectionEffect", game.Lighting)
	light.Contrast = 0
	light.Brightness = 0
	light.Saturation = 0
	light.TintColor = Color3.fromRGB(255, 255, 255)
	game.TweenService:Create(light, TweenInfo.new(45), {
		TintColor = Color3.fromRGB(8, 46, 129),
		Brightness = -0.4,
		Saturation = 1,
		Contrast = -0.2
	}):Play()

	-- --- PASSIVE AMBIENT DAMAGE LOOP ---
	task.spawn(function()
		while entity and entity.PrimaryPart and entity.Parent and not killed do
			local char = player.Character
			local hum = char and char:FindFirstChildWhichIsA("Humanoid")
			
			if hum and hum.Health > 0 then
				-- Check if player has ANY active light source
				local hasActiveLight = false
				
				-- Check all tools in the character (equipped items)
				for _, tool in ipairs(char:GetChildren()) do
					if tool:IsA("Tool") then
						-- Check if this tool is a Lighter or Candle (by name or by having a PointLight)
						local toolName = tool.Name:lower()
						if toolName:find("lighter") or toolName:find("candle") then
							-- Look for any enabled PointLight inside the tool
							for _, descendant in ipairs(tool:GetDescendants()) do
								if descendant:IsA("PointLight") and descendant.Enabled == true then
									hasActiveLight = true
									break
								end
							end
						end
					end
					if hasActiveLight then break end
				end
				
				-- Also check Backpack for equipped/held items (some games store light here)
				if not hasActiveLight then
					local backpack = player:FindFirstChild("Backpack")
					if backpack then
						for _, tool in ipairs(backpack:GetChildren()) do
							if tool:IsA("Tool") then
								local toolName = tool.Name:lower()
								if toolName:find("lighter") or toolName:find("candle") then
									for _, descendant in ipairs(tool:GetDescendants()) do
										if descendant:IsA("PointLight") and descendant.Enabled == true then
											hasActiveLight = true
											break
										end
									end
								end
							end
							if hasActiveLight then break end
						end
					end
				end
				
				-- DEBUG: Print to console so you can see what's happening
				if hasActiveLight then
					-- NO DAMAGE when holding a Lighter or Candle with an active PointLight
					-- print("Light detected - NO DAMAGE") -- Uncomment for debugging
					task.wait(1)
				else
					-- Take damage when no active light source
					print("NO light detected - TAKING DAMAGE!") -- Debug line
					
					local stats = rep:FindFirstChild("GameStats")
					if stats and stats:FindFirstChild("Player_".. char.Name) then
						stats["Player_".. char.Name].Total.DeathCause.Value = "Frostbite"
					end
					
					local deathHint = remotesFolder:FindFirstChild("DeathHint")
					if deathHint then
						pcall(function()
							firesignal(deathHint.OnClientEvent, {
								"You died to the entity designated as Frostbite...",
								"Keep your heat up!"
							})
						end)
					end
					
					hum:TakeDamage(5)
					task.wait(1)
				end
			else
				task.wait(1)
			end
		end
	end)

	if part and part:FindFirstChild("ParticleEmitter") then
		part.ParticleEmitter.Enabled = true
	end

	if attachment then
		local trauk1 = attachment:FindFirstChild("trauk1")
		local face = attachment:FindFirstChild("face")
		if trauk1 then trauk1.Enabled = true end
		if face then face.Enabled = true end
	end

	if staticEffect then
		staticEffect:Stop()
	end

	local ambience = entity.PrimaryPart:FindFirstChild("Ambience")
	local ambienceFar = entity.PrimaryPart:FindFirstChild("AmbienceFar")
	if ambience then ambience:Play() end
	if ambienceFar then ambienceFar:Play() end

	-- Wait for player progress to change rooms
	latestRoom.Changed:Wait()

	-- --- PHASE 3 ---
	turn2 = false
	turn3 = true
	killed = true

	task.spawn(function()
		while turn3 == true and entity.PrimaryPart and entity.PrimaryPart.Parent do
			task.wait(0.1)
			camShake:ShakeOnce(5, 21, 0, 2.4, 1, 6)
		end
	end)

	if attachment then
		local trauk1 = attachment:FindFirstChild("trauk1")
		local face = attachment:FindFirstChild("face")
		if trauk1 then trauk1.Enabled = false end
		if face then face.Enabled = false end
	end

	if ambience then ambience:Stop() end
	if ambienceFar then ambienceFar:Stop() end

	if part and part:FindFirstChild("ParticleEmitter") then
		part.ParticleEmitter.Enabled = false
	end

	local despawnSound = entity.PrimaryPart:FindFirstChild("ahhh_despawn")
	if despawnSound and despawnSound:IsA("Sound") then
		despawnSound:Play()
		delay(1.9672, function()
			turn3 = false
		end)
		despawnSound.Ended:Wait()
	end

	task.wait(0.6)
	game.TweenService:Create(light, TweenInfo.new(32), {
		TintColor = Color3.fromRGB(255,255,255),
		Brightness = 0,
		Saturation = 0,
		Contrast = 0
	}):Play() game.Debris:AddItem(light,60)
	entity:Destroy()
	killed = true
end)
