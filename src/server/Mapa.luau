-- Constroi a casa, o quintal e o foguete por codigo
local Mapa = {}

local ALT = 12
local ESP = 1

local COR_PAREDE = Color3.fromRGB(150, 132, 110)
local COR_MADEIRA = Color3.fromRGB(105, 72, 45)
local COR_TECIDO = Color3.fromRGB(90, 40, 40)

local function bloco(nome, tamanho, cf, cor, material, pai)
	local p = Instance.new("Part")
	p.Name = nome
	p.Size = tamanho
	p.CFrame = cf
	p.Anchored = true
	p.Color = cor
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = pai
	return p
end

-- Parede ao longo do eixo X (z fixo), com vaos de porta {centro, largura}
local function paredeX(pai, z, x1, x2, portas)
	local cursor = x1
	table.sort(portas, function(a, b)
		return a[1] < b[1]
	end)
	local function seg(a, b)
		if b - a > 0.05 then
			bloco("Parede", Vector3.new(b - a, ALT, ESP), CFrame.new((a + b) / 2, ALT / 2, z), COR_PAREDE, nil, pai)
		end
	end
	for _, porta in ipairs(portas) do
		local a = porta[1] - porta[2] / 2
		seg(cursor, a)
		cursor = porta[1] + porta[2] / 2
	end
	seg(cursor, x2)
end

-- Parede ao longo do eixo Z (x fixo)
local function paredeZ(pai, x, z1, z2, portas)
	local cursor = z1
	table.sort(portas, function(a, b)
		return a[1] < b[1]
	end)
	local function seg(a, b)
		if b - a > 0.05 then
			bloco("Parede", Vector3.new(ESP, ALT, b - a), CFrame.new(x, ALT / 2, (a + b) / 2), COR_PAREDE, nil, pai)
		end
	end
	for _, porta in ipairs(portas) do
		local a = porta[1] - porta[2] / 2
		seg(cursor, a)
		cursor = porta[1] + porta[2] / 2
	end
	seg(cursor, z2)
end

local function luminaria(pai, pos, cor, alcance, brilho)
	local l = bloco("Luminaria", Vector3.new(1.5, 0.4, 1.5), CFrame.new(pos), cor, Enum.Material.Neon, pai)
	l.CanCollide = false
	local luz = Instance.new("PointLight")
	luz.Color = cor
	luz.Range = alcance
	luz.Brightness = brilho
	luz.Shadows = true
	luz.Parent = l
end

function Mapa.construir()
	local antigo = workspace:FindFirstChild("Mapa")
	if antigo then
		antigo:Destroy()
	end
	local pasta = Instance.new("Folder")
	pasta.Name = "Mapa"
	pasta.Parent = workspace

	-- Chao do quintal e da casa
	bloco("Grama", Vector3.new(260, 1, 260), CFrame.new(0, -0.6, 40), Color3.fromRGB(40, 70, 35), Enum.Material.Grass, pasta)
	bloco("Piso", Vector3.new(80, 1, 60), CFrame.new(0, -0.5, 0), COR_MADEIRA, Enum.Material.WoodPlanks, pasta)
	bloco("Teto", Vector3.new(82, 1, 62), CFrame.new(0, ALT + 0.5, 0), Color3.fromRGB(60, 50, 45), Enum.Material.Wood, pasta)

	-- Paredes externas (porta da frente na sala)
	paredeX(pasta, -30, -40, 40, {})
	paredeX(pasta, 30, -40, 40, { { -12, 8 } })
	paredeZ(pasta, -40, -30, 30, {})
	paredeZ(pasta, 40, -30, 30, {})

	-- Paredes internas
	paredeZ(pasta, 0, -30, 30, { { -15, 8 }, { 15, 8 } })
	paredeX(pasta, 0, -40, 0, { { -20, 8 } })
	paredeX(pasta, 0, 0, 40, { { 20, 8 } })

	-- SALA (x -40..0, z 0..30)
	bloco("Sofa", Vector3.new(14, 3, 5), CFrame.new(-28, 1.5, 25), COR_TECIDO, Enum.Material.Fabric, pasta)
	bloco("Mesa", Vector3.new(8, 3, 5), CFrame.new(-18, 1.5, 12), COR_MADEIRA, Enum.Material.Wood, pasta)
	bloco("Estante", Vector3.new(3, 8, 10), CFrame.new(-38, 4, 8), COR_MADEIRA, Enum.Material.Wood, pasta)
	luminaria(pasta, Vector3.new(-20, ALT - 0.3, 15), Color3.fromRGB(255, 190, 120), 22, 0.7)

	-- COZINHA (x -40..0, z -30..0)
	bloco("Balcao", Vector3.new(36, 4, 4), CFrame.new(-20, 2, -27), Color3.fromRGB(180, 180, 175), Enum.Material.Marble, pasta)
	bloco("Geladeira", Vector3.new(5, 8, 5), CFrame.new(-37, 4, -8), Color3.fromRGB(220, 220, 220), Enum.Material.Metal, pasta)
	bloco("MesaCozinha", Vector3.new(8, 3, 5), CFrame.new(-18, 1.5, -14), COR_MADEIRA, Enum.Material.Wood, pasta)
	luminaria(pasta, Vector3.new(-20, ALT - 0.3, -15), Color3.fromRGB(255, 230, 190), 22, 0.6)

	-- LAVANDERIA (x 0..40, z 0..30)
	bloco("MaquinaLavar", Vector3.new(5, 5, 5), CFrame.new(36, 2.5, 10), Color3.fromRGB(230, 230, 235), Enum.Material.Metal, pasta)
	bloco("Caixa", Vector3.new(4, 4, 4), CFrame.new(30, 2, 26), Color3.fromRGB(150, 115, 70), Enum.Material.Wood, pasta)
	bloco("Caixa", Vector3.new(4, 4, 4), CFrame.new(35, 2, 26), Color3.fromRGB(140, 105, 65), Enum.Material.Wood, pasta)
	bloco("Caixa", Vector3.new(4, 4, 4), CFrame.new(32.5, 6, 26), Color3.fromRGB(160, 120, 75), Enum.Material.Wood, pasta)
	luminaria(pasta, Vector3.new(20, ALT - 0.3, 15), Color3.fromRGB(200, 220, 255), 20, 0.5)

	-- QUARTO DO CASEIRO (x 0..40, z -30..0) - escuro, so uma luz vermelha fraca
	bloco("Cama", Vector3.new(10, 3, 14), CFrame.new(30, 1.5, -22), Color3.fromRGB(70, 60, 80), Enum.Material.Fabric, pasta)
	bloco("Travesseiro", Vector3.new(6, 1, 3), CFrame.new(30, 3.5, -27), Color3.fromRGB(200, 200, 200), Enum.Material.Fabric, pasta)
	bloco("Guarda-roupa", Vector3.new(10, 10, 4), CFrame.new(7, 5, -27), COR_MADEIRA, Enum.Material.Wood, pasta)
	luminaria(pasta, Vector3.new(38, 3, -10), Color3.fromRGB(255, 40, 30), 12, 0.6)

	-- Objetos barulhentos espalhados pelo chao (armadilhas)
	local barulhentos = {}
	local function armadilha(nome, tamanho, pos, cor, material)
		local p = bloco(nome, tamanho, CFrame.new(pos), cor, material, pasta)
		table.insert(barulhentos, p)
	end
	armadilha("Panela", Vector3.new(1.4, 0.8, 1.4), Vector3.new(-20, 0.4, -4), Color3.fromRGB(170, 170, 175), Enum.Material.Metal)
	armadilha("Brinquedo", Vector3.new(1, 0.8, 1), Vector3.new(-12, 0.4, 19), Color3.fromRGB(230, 200, 40), Enum.Material.SmoothPlastic)
	armadilha("Garrafa", Vector3.new(0.6, 1.2, 0.6), Vector3.new(20, 0.6, 12), Color3.fromRGB(60, 140, 70), Enum.Material.Glass)
	armadilha("Garrafa", Vector3.new(0.6, 1.2, 0.6), Vector3.new(4, 0.6, -12), Color3.fromRGB(110, 70, 40), Enum.Material.Glass)
	armadilha("Panela", Vector3.new(1.4, 0.8, 1.4), Vector3.new(20, 0.4, -4), Color3.fromRGB(170, 170, 175), Enum.Material.Metal)

	-- Foguete caido no quintal
	local base = CFrame.new(4, 6, 62) * CFrame.Angles(0, 0, math.rad(75))
	local corpo = bloco("Foguete", Vector3.new(14, 5, 5), base, Color3.fromRGB(235, 235, 240), Enum.Material.Metal, pasta)
	corpo.Shape = Enum.PartType.Cylinder
	local nariz = bloco("Nariz", Vector3.new(5, 5, 5), base * CFrame.new(7, 0, 0), Color3.fromRGB(200, 40, 40), Enum.Material.SmoothPlastic, pasta)
	nariz.Shape = Enum.PartType.Ball
	bloco("Aleta", Vector3.new(3, 0.6, 9), base * CFrame.new(-6, 0, 0), Color3.fromRGB(200, 40, 40), nil, pasta)
	bloco("Aleta", Vector3.new(3, 9, 0.6), base * CFrame.new(-6, 0, 0), Color3.fromRGB(200, 40, 40), nil, pasta)

	local placa = Instance.new("BillboardGui")
	placa.Name = "Placa"
	placa.Size = UDim2.new(0, 220, 0, 50)
	placa.StudsOffsetWorldSpace = Vector3.new(0, 12, 0)
	placa.AlwaysOnTop = true
	placa.Parent = corpo
	local texto = Instance.new("TextLabel")
	texto.Name = "Texto"
	texto.Size = UDim2.new(1, 0, 1, 0)
	texto.BackgroundTransparency = 1
	texto.TextScaled = true
	texto.Font = Enum.Font.GothamBold
	texto.TextColor3 = Color3.fromRGB(120, 255, 220)
	texto.TextStrokeTransparency = 0
	texto.Text = "FOGUETE 0/6"
	texto.Parent = placa

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(-12, -0.4, 46)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = pasta

	return {
		pasta = pasta,
		nave = corpo,
		placaNave = texto,
		spawn = CFrame.new(-12, 3, 46),
		camaMonstro = CFrame.new(20, 0, -20),
		barulhentos = barulhentos,
		pontosPecas = {
			-- sala
			Vector3.new(-34, 0.8, 15),
			Vector3.new(-18, 3.8, 12),
			Vector3.new(-6, 0.8, 25),
			Vector3.new(-28, 3.8, 25),
			-- cozinha
			Vector3.new(-10, 4.8, -27),
			Vector3.new(-18, 3.8, -14),
			Vector3.new(-33, 0.8, -18),
			Vector3.new(-5, 0.8, -5),
			-- lavanderia
			Vector3.new(25, 0.8, 20),
			Vector3.new(10, 0.8, 5),
			Vector3.new(36, 5.8, 10),
			Vector3.new(15, 0.8, 26),
			-- quarto do caseiro
			Vector3.new(36, 0.8, -5),
			Vector3.new(8, 0.8, -12),
			Vector3.new(30, 3.8, -26),
		},
	}
end

return Mapa
