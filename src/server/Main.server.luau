-- Script principal do servidor. Placeholder: o jogo de verdade entra aqui.
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	print("Entrou:", player.Name)
end)

print("Servidor iniciado - versao de teste do pipeline")
