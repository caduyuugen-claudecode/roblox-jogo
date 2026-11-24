-- O Caseiro: modelo feito de pecas + andar com pathfinding
local PathfindingService = game:GetService("PathfindingService")

local Monstro = {}
Monstro.__index = Monstro

local HIP = 4 -- altura do chao ate a base do HumanoidRootPart

local function parte(nome, tamanho, cor, material, pai)
	local p = Instance.new("Part")
	p.Name = nome
	p.Size = tamanho
	p.Color = cor
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = false
	p.CanCollide = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = pai
	return p
end

function Monstro.criar(cfChao)
	local model = Instance.new("Model")
	model.Name = "Caseiro"

	local hrp = parte("HumanoidRootPart", Vector3.new(2, 2, 1), Color3.new(0, 0, 0), nil, model)
	hrp.Transparency = 1
	hrp.Massless = false
	hrp.CFrame = cfChao * CFrame.new(0, HIP + 1, 0)

	local pele = Color3.fromRGB(190, 175, 160)
	local roupa = Color3.fromRGB(40, 35, 45)

	local pecas = {
		{ "Tronco", Vector3.new(3, 4, 1.6), roupa, Enum.Material.Fabric, CFrame.new(0, 1, 0) },
		{ "Cabeca", Vector3.new(2.2, 2.4, 2.2), pele, nil, CFrame.new(0, 4.2, 0) },
		{ "PernaE", Vector3.new(1.2, 4, 1.2), roupa, Enum.Material.Fabric, CFrame.new(-0.8, -3, 0) },
		{ "PernaD", Vector3.new(1.2, 4, 1.2), roupa, Enum.Material.Fabric, CFrame.new(0.8, -3, 0) },
		{ "BracoE", Vector3.new(1, 5, 1), pele, nil, CFrame.new(-2, 0.5, 0) },
		{ "BracoD", Vector3.new(1, 5, 1), pele, nil, CFrame.new(2, 0.5, 0) },
		{ "OlhoE", Vector3.new(0.45, 0.3, 0.1), Color3.fromRGB(255, 120, 0), Enum.Material.Neon, CFrame.new(-0.5, 4.4, -1.12) },
		{ "OlhoD", Vector3.new(0.45, 0.3, 0.1), Color3.fromRGB(255, 120, 0), Enum.Material.Neon, CFrame.new(0.5, 4.4, -1.12) },
	}
	local tronco
	for _, d in ipairs(pecas) do
		local p = parte(d[1], d[2], d[3], d[4], model)
		p.CFrame = hrp.CFrame * d[5]
		local solda = Instance.new("WeldConstraint")
		solda.Part0 = hrp
		solda.Part1 = p
		solda.Parent = p
		if d[1] == "Tronco" then
			tronco = p
		end
	end
	-- o tronco colide com as paredes para o Caseiro nao atravessar
	tronco.CanCollide = true

	local olhoLuz = Instance.new("PointLight")
	olhoLuz.Color = Color3.fromRGB(255, 100, 0)
	olhoLuz.Range = 8
	olhoLuz.Brightness = 1
	olhoLuz.Parent = model:FindFirstChild("Cabeca")

	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = HIP
	hum.MaxHealth = 1e9
	hum.Health = 1e9
	hum.BreakJointsOnDeath = false
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.WalkSpeed = 10
	hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	hum.Parent = model

	model.PrimaryPart = hrp
	model.Parent = workspace
	pcall(function()
		hrp:SetNetworkOwner(nil)
	end)

	local self = setmetatable({
		model = model,
		hum = hum,
		hrp = hrp,
		caminho = PathfindingService:CreatePath({
			AgentRadius = 2,
			AgentHeight = 10,
			AgentCanJump = false,
			WaypointSpacing = 4,
		}),
		waypoints = nil,
		indice = 1,
		alvoAtual = nil,
		ultimoCalculo = 0,
	}, Monstro)
	return self
end

function Monstro:teleportar(cfChao)
	self.model:PivotTo(cfChao * CFrame.new(0, HIP + 1, 0))
	self.hrp.AssemblyLinearVelocity = Vector3.zero
	self.waypoints = nil
	self.alvoAtual = nil
	self.hum:MoveTo(self.hrp.Position)
end

function Monstro:parar()
	self.waypoints = nil
	self.alvoAtual = nil
	self.hum:MoveTo(self.hrp.Position)
end

local function plano(v)
	return Vector3.new(v.X, 0, v.Z)
end

function Monstro:irPara(pos, agora)
	local precisaRecalcular = (not self.alvoAtual)
		or (plano(self.alvoAtual) - plano(pos)).Magnitude > 6
		or (agora - self.ultimoCalculo) > 1.5
	if precisaRecalcular then
		self.alvoAtual = pos
		self.ultimoCalculo = agora
		local ok = pcall(function()
			self.caminho:ComputeAsync(self.hrp.Position, pos)
		end)
		if ok and self.caminho.Status == Enum.PathStatus.Success then
			self.waypoints = self.caminho:GetWaypoints()
			self.indice = 2
		else
			self.waypoints = nil
		end
	end

	if self.waypoints then
		local wp = self.waypoints[self.indice]
		while wp and (plano(wp.Position) - plano(self.hrp.Position)).Magnitude < 3 do
			self.indice += 1
			wp = self.waypoints[self.indice]
		end
		if wp then
			self.hum:MoveTo(wp.Position)
			return
		end
	end
	self.hum:MoveTo(pos)
end

function Monstro:distanciaAte(pos)
	return (plano(self.hrp.Position) - plano(pos)).Magnitude
end

return Monstro
