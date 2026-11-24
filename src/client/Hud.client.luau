-- HUD: barra de barulho, tempo, pecas, estado do Caseiro e botao de agachar
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local evEstado = remotes:WaitForChild("Estado")
local evAgachar = remotes:WaitForChild("Agachar")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function canto(obj, raio)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, raio or 10)
	c.Parent = obj
end

local function texto(pai, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.5
	l.TextScaled = true
	for k, v in pairs(props) do
		l[k] = v
	end
	l.Parent = pai
	return l
end

-- Painel do topo
local painel = Instance.new("Frame")
painel.AnchorPoint = Vector2.new(0.5, 0)
painel.Position = UDim2.new(0.5, 0, 0, 8)
painel.Size = UDim2.new(0.55, 0, 0, 70)
painel.BackgroundColor3 = Color3.new(0, 0, 0)
painel.BackgroundTransparency = 0.45
painel.Parent = gui
canto(painel)

texto(painel, {
	Text = "BARULHO",
	Position = UDim2.new(0, 10, 0, 4),
	Size = UDim2.new(0.25, 0, 0, 18),
	TextXAlignment = Enum.TextXAlignment.Left,
})

local fundoBarra = Instance.new("Frame")
fundoBarra.Position = UDim2.new(0, 10, 0, 24)
fundoBarra.Size = UDim2.new(1, -20, 0, 16)
fundoBarra.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
fundoBarra.Parent = painel
canto(fundoBarra, 8)

local barra = Instance.new("Frame")
barra.Size = UDim2.new(0, 0, 1, 0)
barra.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
barra.Parent = fundoBarra
canto(barra, 8)

local info = texto(painel, {
	Text = "",
	Position = UDim2.new(0, 10, 0, 44),
	Size = UDim2.new(1, -20, 0, 20),
})

-- Mensagem central
local mensagem = texto(gui, {
	Text = "",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.32, 0),
	Size = UDim2.new(0.85, 0, 0, 46),
	TextStrokeTransparency = 0,
	Visible = false,
})

-- Instrucoes do intervalo
local instrucoes = texto(gui, {
	Text = "Peguem as peças brilhantes e levem ao FOGUETE no quintal.\nAndar em pé faz barulho. Agache para andar em silêncio.\nPular e esbarrar em panelas e garrafas faz MUITO barulho.",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0.42, 0),
	Size = UDim2.new(0.8, 0, 0, 80),
	TextScaled = true,
	Visible = false,
})

-- Aviso de carregando / pego
local rodape = texto(gui, {
	Text = "",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -150),
	Size = UDim2.new(0.7, 0, 0, 30),
	TextColor3 = Color3.fromRGB(120, 255, 220),
	Visible = false,
})

-- Botao de agachar (celular) + tecla C/Ctrl (PC)
local botao = Instance.new("TextButton")
botao.AnchorPoint = Vector2.new(1, 1)
botao.Position = UDim2.new(1, -150, 1, -40)
botao.Size = UDim2.new(0, 120, 0, 60)
botao.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
botao.BackgroundTransparency = 0.2
botao.Font = Enum.Font.GothamBold
botao.TextScaled = true
botao.TextColor3 = Color3.new(1, 1, 1)
botao.Text = "🤫 AGACHAR"
botao.Parent = gui
canto(botao, 14)

local agachado = false
local function setAgachar(valor)
	agachado = valor
	evAgachar:FireServer(valor)
	botao.Text = valor and "🧍 LEVANTAR" or "🤫 AGACHAR"
	botao.BackgroundColor3 = valor and Color3.fromRGB(40, 140, 80) or Color3.fromRGB(60, 60, 70)
end

botao.Activated:Connect(function()
	setAgachar(not agachado)
end)

ContextActionService:BindAction("Agachar", function(_, estado)
	if estado == Enum.UserInputState.Begin then
		setAgachar(not agachado)
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.C, Enum.KeyCode.LeftControl)

player.CharacterAdded:Connect(function()
	setAgachar(false)
end)

local TEXTO_MONSTRO = {
	dormindo = "😴 Caseiro dormindo",
	desconfiado = "👂 Caseiro desconfiado...",
	cacando = "😡 O CASEIRO ESTÁ CAÇANDO!",
	voltando = "🚶 Caseiro voltando pra cama",
}

local function formatarTempo(t)
	return string.format("%d:%02d", math.floor(t / 60), t % 60)
end

evEstado.OnClientEvent:Connect(function(e)
	local b = e.barulho or 0
	barra.Size = UDim2.new(math.clamp(b / 100, 0, 1), 0, 1, 0)
	if b >= Config.LIMITE_CACANDO then
		barra.BackgroundColor3 = Color3.fromRGB(235, 60, 60)
	elseif b >= Config.LIMITE_DESCONFIADO then
		barra.BackgroundColor3 = Color3.fromRGB(240, 200, 60)
	else
		barra.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
	end

	if e.fase == "rodada" then
		info.Text = "⏱ " .. formatarTempo(e.tempo) .. "   🔧 " .. e.entregues .. "/" .. e.total .. "   " .. (TEXTO_MONSTRO[e.monstro] or "")
	elseif e.fase == "intervalo" then
		info.Text = "Preparando a próxima rodada..."
	else
		info.Text = "Fim da rodada"
	end

	instrucoes.Visible = e.fase == "intervalo"

	mensagem.Text = e.msg or ""
	mensagem.Visible = (e.msg or "") ~= ""

	if e.fase == "rodada" and player:GetAttribute("Pego") then
		rodape.Text = "Você foi pego. Espere a próxima rodada."
		rodape.TextColor3 = Color3.fromRGB(255, 120, 120)
		rodape.Visible = true
	elseif player:GetAttribute("Carregando") then
		rodape.Text = "🔧 Carregando peça → leve até o FOGUETE"
		rodape.TextColor3 = Color3.fromRGB(120, 255, 220)
		rodape.Visible = true
	else
		rodape.Visible = false
	end
end)
