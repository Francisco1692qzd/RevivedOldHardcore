local G = getgenv()
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- [1] MODEL LOADER
G.LoadGithubModel = function(url)
    if not (writefile and getcustomasset and request) then return nil end
    local rawUrl = url:gsub("github.com", "raw.githubusercontent.com"):gsub("/blob/", "/")
    local response = request({Url = rawUrl, Method = "GET"})
    if response.StatusCode ~= 200 then return nil end
    
    local fileName = "shocker_final_fix.rbxm"
    writefile(fileName, response.Body)
    local assetId = getcustomasset(fileName)
    
    local success, result = pcall(function()
        return game:GetObjects(assetId)[1]
    end)
    return success and result or nil
end

-- [2] ENTITY: SHOCKER
local function SpawnShocker()
    local LP = game.Players.LocalPlayer
    local Char = LP.Character or LP.CharacterAdded:Wait()
    local Hum = Char:WaitForChild("Humanoid")
    local Root = Char:WaitForChild("HumanoidRootPart")
    local cam = workspace.CurrentCamera
    local cameraShaker = require(game.ReplicatedStorage.CameraShaker)
    local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
        cam.CFrame = cam.CFrame * cf
    end)
    camShake:Start()
    
    local modelUrl = "https://github.com/Francisco1692qzd/RevivedOldHardcore/blob/main/oldShocker.rbxm"
    local entity = G.LoadGithubModel(modelUrl)

    if not entity then return end

    local mainPart = entity:FindFirstChild("OOGA BOOGAAAA")
    if not mainPart then return end

    -- Configuração Vital
    entity.PrimaryPart = mainPart
    mainPart.Anchored = true
    mainPart.CanCollide = false
    
    entity:PivotTo(Root.CFrame * CFrame.new(0, 0, -12))
    entity.Parent = workspace

    local spawnSound = entity:FindFirstChild("PlaySound")
    local attackSound = mainPart:FindFirstChild("HORROR SCREAM 15")
    
    if spawnSound then spawnSound:Play() end

    local lookingTime = 0
    local hasAttacked = false

    local function isPlayerLooking()
        local _, onScreen = cam:WorldToViewportPoint(mainPart.Position)
        if onScreen then
            local camToEntity = (mainPart.Position - cam.CFrame.Position).Unit
            return camToEntity:Dot(cam.CFrame.LookVector) > 0.5 
        end
        return false
    end

	for i, v in pairs(entity:GetChildren()) do
		if (v:IsA("Sound") and v.Name == "PlaySound") then
			if v.PlayOnRemove == true then v.PlayOnRemove = false end
		end
	end

    task.spawn(function()
        while entity and entity.Parent and not hasAttacked do
            task.wait(0.05) 
            
            if isPlayerLooking() then
                lookingTime = lookingTime + 0.05
            else
                if lookingTime > 0.1 and lookingTime < 1.9 then
                    -- Lógica de Ignorado (Unanchor)
                    mainPart.Anchored = false
                    task.wait(6)
                    entity:Destroy()
                    break
                end
            end

            -- [CORREÇÃO DO ATAQUE]
            if lookingTime >= 1.9 and not hasAttacked then
                hasAttacked = true
                
                -- 1. Toca o som primeiro
                if attackSound then attackSound:Play() end
                
                -- 2. Prepara a física para o movimento
                mainPart.Anchored = true -- Mantemos True para o Tween CFrame funcionar
                
                -- 3. Cria o Tween
                local attackTween = game:GetService("TweenService"):Create(mainPart, 
                    TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), 
                    {CFrame = Root.CFrame}
                )
                
                attackTween:Play()
                
                -- 4. Dano instantâneo após um pequeno delay do impacto visual
                task.delay(0.37, function()
                    if Hum and Hum.Health > 0 then
                        Hum:TakeDamage(25)
                        camShake:Shake(cameraShaker.Presets.Explosion)
                        game.ReplicatedStorage.GameStats["Player_" .. Char.Name].Total.DeathCause.Value = "Shocker"
                            local hints = {
                                "You died to who you call Shocker...",
                                "Dont look at it or it stuns you!"
                            }
							if ReplicatedStorage:FindFirstChild("RemotesFolder") then
								local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
			                    firesignal(remotesFolder.DeathHint.OnClientEvent, hints, "Blue")
							elseif ReplicatedStorage:FindFirstChild("Bricks") then
								local remotesFolder = ReplicatedStorage:FindFirstChild("Bricks")
			                    firesignal(remotesFolder.DeathHint.OnClientEvent, hints)
							end
                    end
                end)

                -- 5. Finalização garantida
                attackTween.Completed:Wait()
                task.wait(0.75)
                if entity then entity:Destroy() end
                break
            end
        end
    end)
end

task.spawn(SpawnShocker)
