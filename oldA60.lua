local G = getgenv()

G.LoadGithubMPEGAudio = function(url)
    if not (writefile and getcustomasset and request) then return nil end

    -- Generate consistent filename from URL
    local function generateFileName(url)
        local hash = 0
        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 2^32
        end
        return "old_a60_" .. tostring(hash) .. ".mpeg"
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
            --print("✅ Áudio Rebound carregado do cache!")
            return assetId
        end
    end

    -- Download new audio if not exists
    local response = request({
        Url = url,  -- Removed the cache bypass timestamp
        Method = "GET",
        Headers = {
            ["Accept"] = "audio/mpeg, audio/ogg, application/octet-stream"
        }
    })

    if response.StatusCode ~= 200 then
        warn("Xeno: Falha no download. Status: " .. response.StatusCode)
        return nil
    end
    
    writefile(fileName, response.Body)
    
    local success, assetId = pcall(function()
        return getcustomasset(fileName)
    end)

    if success then
        --print("✅ Áudio Rebound carregado com sucesso!")
        return assetId
    end
    
    --warn("Erro no getcustomasset: " .. tostring(assetId))
    return nil
end

G.LoadGithubAudio = function(url)
    if not (writefile and getcustomasset and request) then return nil end

    -- Generate consistent filename from URL
    local function generateFileName(url)
        local hash = 0
        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 2^32
        end
        return "old_a60_" .. tostring(hash) .. ".mp3"
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
            --print("✅ Áudio Rebound carregado do cache!")
            return assetId
        end
    end

    -- Download new audio if not exists
    local response = request({
        Url = url,  -- Removed the cache bypass timestamp
        Method = "GET",
        Headers = {
            ["Accept"] = "audio/mpeg, audio/ogg, application/octet-stream"
        }
    })

    if response.StatusCode ~= 200 then
        warn("Xeno: Falha no download. Status: " .. response.StatusCode)
        return nil
    end
    
    writefile(fileName, response.Body)
    
    local success, assetId = pcall(function()
        return getcustomasset(fileName)
    end)

    if success then
        --print("✅ Áudio Rebound carregado com sucesso!")
        return assetId
    end
    
    --warn("Erro no getcustomasset: " .. tostring(assetId))
    return nil
end

G.LoadGithubModel = function(url)
    if not (writefile and getcustomasset and request and isfile) then
        return nil
    end
    
    -- Generate a consistent filename based on the URL
    local function generateFileName(url)
        -- Create a simple hash from the URL
        local hash = 0
        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 2^32
        end
        return "oldm_a60" .. tostring(hash) .. ".rbxm"
    end
    
    local fileName = generateFileName(url)
    
    -- Check if file already exists
    local fileExists = false
    local success, exists = pcall(function()
        return isfile and isfile(fileName)
    end)
    
    if success and exists then
        fileExists = true
        -- Try to load existing model first
        local assetId = getcustomasset(fileName)
        local loadSuccess, result = pcall(function()
            return game:GetObjects(assetId)[1]
        end)
        
        if loadSuccess and result then
            -- AUTOMATICALLY CLONE so you get a fresh instance every time
            return result:Clone()
        end
    end
    
    -- If file doesn't exist or loading failed, download new one
    local response = request({Url = url, Method = "GET"})
    if response.StatusCode ~= 200 then return nil end
    
    writefile(fileName, response.Body)
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

local function Entity()
	local cameraShaker = require(game.ReplicatedStorage.CameraShaker)
	local camera = workspace.CurrentCamera
	local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
		camera.CFrame = camera.CFrame * cf
	end)
	camShake:Start()
	local rawURL = "https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/main/a60oldmodel.rbxm"
	local stingURL = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/main/Multimonster_sting.mp3.mpeg"
	local entity = nil
	local killed = false
	local reboundTimes = 6
	local DEF_SPEED = 99999
	local speed = 190
	local storer = speed
	local latestRoomInt = game.ReplicatedStorage.GameData.LatestRoom
	
	if entity == nil then
		entity = G.LoadGithubModel(rawURL)
		if entity then entity.Parent = workspace end
	end

	if entity == nil then return end

	entity.Ambience.TimePosition = 0
	entity.Breathing.TimePosition = 0

	local mainPart = entity:FindFirstChildWhichIsA("BasePart")

	local function GetTime(dist, spd)
		return dist / spd
	end

	local function canSeeTarget(target, size)
		if killed == true then
			return
		end

		local origin = mainPart.Position
		local direction = (target.HumanoidRootPart.Position - origin).unit * size
		local ray = Ray.new(origin, direction)

		local hit,pos=workspace:FindPartOnRay(ray,mainPart)
		if hit then
			if hit:IsDescendantOf(target) then
				killed = true
				return true
			end
		else
			return false
		end
	end

	wait(2)
	spawn(function()
		while entity ~= nil and entity.Parent ~= nil and mainPart.Parent ~= nil do wait(0.3)
			local v = game.Players.LocalPlayer
			if v.Character ~= nil then
				if canSeeTarget(v.Character, 80) and not v.Character:GetAttribute("Hiding") then
					loadstring(game:HttpGet("https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/a60jumpscare.lua"))()
					game.ReplicatedStorage.GameStats["Player_"..v.Character.Name].Total.DeathCause.Value = "A-60 (or Multimonster)"
					delay(0.68, function()
						v.Character.Humanoid:TakeDamage(145)
					end)
				end
			end
			if v.Character ~= nil and (mainPart.Position - v.Character.HumanoidRootPart.Position).magnitude <= 60 then
				camShake:ShakeOnce(17, 30, 0, 3,1,6)
			end
		end
	end)
	local gruh = workspace.CurrentRooms
	speed = DEF_SPEED
	local function forward()
		for i = 1, latestRoomInt.Value do
			if gruh:FindFirstChild(i) then
				local room = gruh[i]
				if room and room:FindFirstChild("Nodes") then
					local nodes = room["Nodes"]
					for v = 1, #nodes:GetChildren() do
						if nodes:FindFirstChild(v) then
							local node = nodes[v]
							local distance = (mainPart.Position - node.Position).magnitude
							local jerk = game.TweenService:Create(mainPart, TweenInfo.new(GetTime(distance, speed), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0,false,0), {CFrame = node.CFrame + Vector3.new(0,2.4,0)})
							jerk:Play()
							jerk.Completed:Wait()
							speed = storer
						end
					end
				end
			end
		end
	end
	local function back()
		for i = latestRoomInt.Value, 1, -1 do
			if gruh:FindFirstChild(i) then
				local room = gruh[i]
				if room and room:FindFirstChild("Nodes") then
					local nodes = room["Nodes"]
					for v = #nodes:GetChildren(), 1, -1 do
						if nodes:FindFirstChild(v) then
							local node = nodes[v]
							local distance = (mainPart.Position - node.Position).magnitude
							local jerk = game.TweenService:Create(mainPart, TweenInfo.new(GetTime(distance, speed), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0,false,0), {CFrame = node.CFrame + Vector3.new(0,2.4,0)})
							jerk:Play()
							jerk.Completed:Wait()
							speed = storer
						end
					end
				end
			end
		end
	end

	-- --- 🏃 THE REBOUNDS ---
    for i = 1, reboundTimes do
        pcall(forward)
        task.wait(1.6)
        pcall(back)
        task.wait(0.5)
    end

	entity:Destroy()
	local stingDissapear = G.LoadGithubAudio("https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/main/Multimonster_sting.mp3.mpeg")
    local light = Instance.new("ColorCorrectionEffect", game.Lighting)
    light.Brightness, light.Saturation, light.Contrast = -0.4, 0.4, -0.5
    light.TintColor = Color3.fromRGB(255, 0, 0)
    
    game.TweenService:Create(light, TweenInfo.new(20), {
        Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.fromRGB(255, 255, 255)
    }):Play()
    
    game.Debris:AddItem(light, 20)
    camShake:ShakeOnce(23, 45, 0, 16, 1, 6)
	local sting = Instance.new("Sound", workspace)
	local pitch = Instance.new("PitchShiftSoundEffect", sting)
	local dist = Instance.new("DistortionSoundEffect", sting)
	pitch.Octave = 0.5
	sting.SoundId = "rbxassetid://140615626179933"
	sting.Volume = 16
	sting.PlaybackSpeed = 0.73
end

pcall(Entity)
