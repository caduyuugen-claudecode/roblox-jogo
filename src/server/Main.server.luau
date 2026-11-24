-- NAO ACORDE O CASEIRO - logica principal do servidor
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Mapa = require(script.Parent:WaitForChild("Mapa"))
local Monstro = require(script.Parent:WaitForChild("Monstro"))

Players.CharacterAutoLoads = false

-- Remotes
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local evEstado = Instance.new("RemoteEvent")
evEstado.Name = "Estado"
evEstado.Parent = remotes
local evAgachar = Instance.new("RemoteEvent")
evAgachar.Name = "Agachar"
evAgachar.Parent = remotes
remotes.Parent = ReplicatedStorage

-- Noite
Lighting.ClockTime = 0
Lighting.Brightness = 1
Lighting.Ambient = Color3.fromRGB(28, 28, 38)
Lighting.OutdoorAmbient = Color3.fromRGB(45, 45, 60)
Lighting.FogColor = Color3.fromRGB(10, 10, 18)
Lighting.FogEnd = 160
Lighting.GlobalShadows = true

local mapa = Mapa.construir()
local caseiro = Monstro.criar(mapa.camaMonstro)

local jogo = {
	fase = "intervalo",
	tempo = 0,
	barulho = 0,
	ultimaPos = nil,
	entregues = 0,
	monstro = "dormindo",
	msg = "",
	msgAte = 0,
	vitoria = false,
}
local carregando = {} -- [player] = peca
local pastaPecas = nil

local function avisar(texto, duracao)
	jogo.msg = texto
	jogo.msgAte = os.clock() + (duracao or 3)
end

local function fazerBarulho(qtd, pos)
	if jogo.fase ~= "rodada" then
		return
	end
	jogo.barulho = math.clamp(jogo.barulho + qtd, 0, 100)
	if pos then
		jogo.ultimaPos = pos
	end
end

local function personagemVivo(player)
	local char = player.Character
	if not char then
		return nil
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hum and hrp and hum.Health > 0 then
		return char, hum, hrp
	end
	return nil
end

local function atualizarVelocidade(player)
	local _, hum = personagemVivo(player)
	if not hum then
		return
	end
	local v = player:GetAttribute("Agachado") and Config.VELOCIDADE_AGACHADO or Config.VELOCIDADE_NORMAL
	if carregando[player] then
		v *= Config.MULT_CARREGANDO
	end
	hum.WalkSpeed = v
end

local function atualizarPlaca()
	mapa.placaNave.Text = "FOGUETE " .. jogo.entregues .. "/" .. Config.TOTAL_PECAS
end

local function soltarPeca(player, pos)
	local peca = carregando[player]
	carregando[player] = nil
	player:SetAttribute("Carregando", false)
	if not peca or not peca.Parent then
		return
	end
	for _, filho in ipairs(peca:GetChildren()) do
		if filho:IsA("WeldConstraint") then
			filho:Destroy()
		end
	end
	peca.Anchored = true
	peca.CFrame = CFrame.new(pos.X, 0.8, pos.Z)
	local prompt = peca:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = true
	end
end

local function criarPecas()
	if pastaPecas then
		pastaPecas:Destroy()
	end
	pastaPecas = Instance.new("Folder")
	pastaPecas.Name = "Pecas"
	pastaPecas.Parent = workspace

	local pontos = table.clone(mapa.pontosPecas)
	for i = #pontos, 2, -1 do
		local j = math.random(1, i)
		pontos[i], pontos[j] = pontos[j], pontos[i]
	end

	for i = 1, math.min(Config.TOTAL_PECAS, #pontos) do
		local peca = Instance.new("Part")
		peca.Name = "Peca"
		peca.Size = Vector3.new(1.5, 1.5, 1.5)
		peca.Material = Enum.Material.Neon
		peca.Color = Color3.fromRGB(0, 255, 200)
		peca.Anchored = true
		peca.CanCollide = false
		peca.Position = pontos[i]
		peca.Parent = pastaPecas

		local luz = Instance.new("PointLight")
		luz.Color = peca.Color
		luz.Range = 8
		luz.Brightness = 1.5
		luz.Parent = peca

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Pegar"
		prompt.ObjectText = "Peça do foguete"
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt.Parent = peca

		prompt.Triggered:Connect(function(player)
			if jogo.fase ~= "rodada" or carregando[player] then
				return
			end
			local _, _, hrp = personagemVivo(player)
			if not hrp then
				return
			end
			prompt.Enabled = false
			peca.Anchored = false
			peca.Massless = true
			peca.CFrame = hrp.CFrame * CFrame.new(0, 0.5, 1.3)
			local solda = Instance.new("WeldConstraint")
			solda.Part0 = hrp
			solda.Part1 = peca
			solda.Parent = peca
			carregando[player] = peca
			player:SetAttribute("Carregando", true)
			atualizarVelocidade(player)
			fazerBarulho(Config.BARULHO_PEGAR, hrp.Position)
		end)
	end
end

-- Entrega no foguete
local promptNave = Instance.new("ProximityPrompt")
promptNave.ActionText = "Entregar peça"
promptNave.ObjectText = "Foguete"
promptNave.HoldDuration = 0.3
promptNave.MaxActivationDistance = 14
promptNave.RequiresLineOfSight = false
promptNave.Parent = mapa.nave

promptNave.Triggered:Connect(function(player)
	local peca = carregando[player]
	if not peca or jogo.fase ~= "rodada" then
		return
	end
	carregando[player] = nil
	peca:Destroy()
	player:SetAttribute("Carregando", false)
	atualizarVelocidade(player)
	jogo.entregues += 1
	atualizarPlaca()
	avisar(player.DisplayName .. " entregou uma peça! (" .. jogo.entregues .. "/" .. Config.TOTAL_PECAS .. ")", 3)
	if jogo.entregues >= Config.TOTAL_PECAS then
		jogo.vitoria = true
	end
end)

local function pegarJogador(player)
	local _, hum, hrp = personagemVivo(player)
	if not hum then
		return
	end
	soltarPeca(player, hrp.Position)
	player:SetAttribute("Pego", true)
	hum.Health = 0
	avisar(player.DisplayName .. " foi pego pelo Caseiro!", 3)
	fazerBarulho(Config.BARULHO_PEGO, hrp.Position)
end

-- Armadilhas barulhentas
for _, objeto in ipairs(mapa.barulhentos) do
	local ultimo = 0
	objeto.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and jogo.fase == "rodada" and os.clock() - ultimo > 3 then
			ultimo = os.clock()
			fazerBarulho(Config.BARULHO_OBJETO, objeto.Position)
			avisar("CLANG! Alguém esbarrou em " .. string.lower(objeto.Name) .. "...", 2)
		end
	end)
end

-- Personagens
local function prepararPersonagem(player, char)
	local hum = char:WaitForChild("Humanoid")
	local hrp = char:WaitForChild("HumanoidRootPart")

	local cabeca = char:FindFirstChild("Head")
	if cabeca then
		local lanterna = Instance.new("SpotLight")
		lanterna.Face = Enum.NormalId.Front
		lanterna.Range = 26
		lanterna.Angle = 70
		lanterna.Brightness = 1.4
		lanterna.Parent = cabeca
		local brilho = Instance.new("PointLight")
		brilho.Range = 7
		brilho.Brightness = 0.4
		brilho.Parent = cabeca
	end

	hum.StateChanged:Connect(function(_, novo)
		if novo == Enum.HumanoidStateType.Jumping then
			fazerBarulho(Config.BARULHO_PULO, hrp.Position)
		end
	end)
	hum.Died:Connect(function()
		if carregando[player] then
			soltarPeca(player, hrp.Position)
		end
		player:SetAttribute("Pego", true)
	end)
	atualizarVelocidade(player)
end

local function carregarPersonagem(player)
	player:SetAttribute("Pego", false)
	player:SetAttribute("Agachado", false)
	player:SetAttribute("Carregando", false)
	carregando[player] = nil
	player:LoadCharacter()
	player:SetAttribute("Pego", false)
	local char = player.Character
	if char then
		char:PivotTo(mapa.spawn * CFrame.new(math.random(-5, 5), 0, math.random(-3, 3)))
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		prepararPersonagem(player, char)
	end)
	task.spawn(carregarPersonagem, player)
end)

Players.PlayerRemoving:Connect(function(player)
	local _, _, hrp = personagemVivo(player)
	if hrp then
		soltarPeca(player, hrp.Position)
	else
		carregando[player] = nil
	end
end)

evAgachar.OnServerEvent:Connect(function(player, valor)
	player:SetAttribute("Agachado", valor == true)
	atualizarVelocidade(player)
end)

-- Barulho de passos + decaimento
RunService.Heartbeat:Connect(function(dt)
	if jogo.fase ~= "rodada" then
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local _, _, hrp = personagemVivo(player)
		if hrp and not player:GetAttribute("Agachado") then
			local v = hrp.AssemblyLinearVelocity
			if Vector3.new(v.X, 0, v.Z).Magnitude > 3 then
				fazerBarulho(Config.BARULHO_ANDAR * dt, hrp.Position)
			end
		end
	end
	jogo.barulho = math.max(0, jogo.barulho - Config.BARULHO_DECAI * dt)
end)

-- Visao do Caseiro
local function jogadorVisivel()
	local origem = caseiro.hrp.Position + Vector3.new(0, 4, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { caseiro.model, pastaPecas }
	local melhor, menor = nil, math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		local char, _, hrp = personagemVivo(player)
		if hrp then
			local alcance = player:GetAttribute("Agachado") and Config.MONSTRO_VISAO * 0.5 or Config.MONSTRO_VISAO
			local d = (hrp.Position - origem).Magnitude
			if d < alcance and d < menor then
				local r = workspace:Raycast(origem, hrp.Position - origem, params)
				if not r or r.Instance:IsDescendantOf(char) then
					melhor, menor = hrp.Position, d
				end
			end
		end
	end
	return melhor
end

-- IA do Caseiro
task.spawn(function()
	local calmo = 0
	while true do
		local dt = task.wait(0.2)
		local agora = os.clock()

		if jogo.fase ~= "rodada" then
			if jogo.monstro ~= "dormindo" then
				jogo.monstro = "dormindo"
				caseiro:teleportar(mapa.camaMonstro)
			end
			caseiro:parar()
		else
			local b = jogo.barulho
			if b >= Config.LIMITE_CACANDO then
				if jogo.monstro ~= "cacando" then
					avisar("O CASEIRO ACORDOU! CORRAM!", 3)
				end
				jogo.monstro = "cacando"
				calmo = 0
			elseif b >= Config.LIMITE_DESCONFIADO then
				if jogo.monstro == "dormindo" or jogo.monstro == "voltando" then
					jogo.monstro = "desconfiado"
					avisar("Ouviu algo... o Caseiro levantou.", 3)
				end
				calmo = 0
			elseif b < Config.LIMITE_CALMO and jogo.monstro ~= "dormindo" then
				calmo += dt
				if calmo > Config.TEMPO_PARA_DORMIR and jogo.monstro ~= "voltando" then
					jogo.monstro = "voltando"
				end
			end

			if jogo.monstro == "dormindo" then
				caseiro:parar()
			elseif jogo.monstro == "desconfiado" then
				caseiro.hum.WalkSpeed = Config.MONSTRO_VEL_ANDAR
				caseiro:irPara(jogo.ultimaPos or mapa.camaMonstro.Position, agora)
			elseif jogo.monstro == "cacando" then
				caseiro.hum.WalkSpeed = Config.MONSTRO_VEL_CACAR
				local alvo = jogadorVisivel() or jogo.ultimaPos or mapa.camaMonstro.Position
				caseiro:irPara(alvo, agora)
			elseif jogo.monstro == "voltando" then
				caseiro.hum.WalkSpeed = Config.MONSTRO_VEL_ANDAR
				local cama = mapa.camaMonstro.Position
				caseiro:irPara(cama, agora)
				if caseiro:distanciaAte(cama) < 4 then
					jogo.monstro = "dormindo"
					caseiro:teleportar(mapa.camaMonstro)
				end
			end

			-- Pegar quem estiver perto
			if jogo.monstro ~= "dormindo" then
				for _, player in ipairs(Players:GetPlayers()) do
					local _, _, hrp = personagemVivo(player)
					if hrp then
						local dy = math.abs(hrp.Position.Y - caseiro.hrp.Position.Y)
						if caseiro:distanciaAte(hrp.Position) < Config.MONSTRO_ALCANCE_PEGAR and dy < 7 then
							pegarJogador(player)
						end
					end
				end
			end
		end
	end
end)

-- Envia o estado para os jogadores
task.spawn(function()
	while true do
		task.wait(0.25)
		evEstado:FireAllClients({
			fase = jogo.fase,
			tempo = math.max(0, math.ceil(jogo.tempo)),
			barulho = math.floor(jogo.barulho),
			monstro = jogo.monstro,
			entregues = jogo.entregues,
			total = Config.TOTAL_PECAS,
			msg = (os.clock() < jogo.msgAte) and jogo.msg or "",
		})
	end
end)

local function contarVivos()
	local n = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if personagemVivo(player) and not player:GetAttribute("Pego") then
			n += 1
		end
	end
	return n
end

-- Ciclo de rodadas
while true do
	jogo.fase = "intervalo"
	jogo.vitoria = false
	jogo.entregues = 0
	jogo.barulho = 0
	jogo.ultimaPos = nil
	for player in pairs(carregando) do
		player:SetAttribute("Carregando", false)
	end
	table.clear(carregando)
	criarPecas()
	atualizarPlaca()
	jogo.monstro = "dormindo"
	caseiro:teleportar(mapa.camaMonstro)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(carregarPersonagem, player)
	end

	while #Players:GetPlayers() == 0 do
		task.wait(1)
	end

	for t = Config.TEMPO_INTERVALO, 1, -1 do
		jogo.tempo = t
		avisar("A rodada começa em " .. t .. "...", 1.1)
		task.wait(1)
	end

	jogo.fase = "rodada"
	jogo.tempo = Config.TEMPO_RODADA
	avisar("Silêncio... o Caseiro está dormindo.", 4)

	local resultado
	while true do
		task.wait(0.25)
		jogo.tempo -= 0.25
		if jogo.vitoria then
			resultado = "vitoria"
			break
		end
		if jogo.tempo <= 0 then
			resultado = "tempo"
			break
		end
		if #Players:GetPlayers() > 0 and contarVivos() == 0 then
			resultado = "todos"
			break
		end
	end

	jogo.fase = "fim"
	jogo.tempo = Config.TEMPO_FIM
	if resultado == "vitoria" then
		avisar("🚀 VITÓRIA! O foguete decolou!", Config.TEMPO_FIM)
	elseif resultado == "tempo" then
		avisar("⏰ O tempo acabou... o Caseiro acordou de vez.", Config.TEMPO_FIM)
	else
		avisar("💀 O Caseiro pegou todo mundo!", Config.TEMPO_FIM)
	end
	task.wait(Config.TEMPO_FIM)
end
