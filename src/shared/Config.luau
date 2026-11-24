-- Configuracoes do jogo "NAO ACORDE O CASEIRO"
return {
	TEMPO_RODADA = 300, -- segundos de rodada
	TEMPO_INTERVALO = 15, -- contagem antes da rodada
	TEMPO_FIM = 8, -- tela de resultado

	TOTAL_PECAS = 6,

	VELOCIDADE_NORMAL = 16,
	VELOCIDADE_AGACHADO = 7,
	MULT_CARREGANDO = 0.85,

	-- Barulho (0 a 100)
	BARULHO_ANDAR = 9, -- por segundo, por jogador andando em pe
	BARULHO_PULO = 10,
	BARULHO_PEGAR = 6,
	BARULHO_OBJETO = 25, -- esbarrar em panela/garrafa
	BARULHO_PEGO = 20,
	BARULHO_DECAI = 6, -- por segundo

	LIMITE_DESCONFIADO = 40,
	LIMITE_CACANDO = 75,
	LIMITE_CALMO = 20,
	TEMPO_PARA_DORMIR = 10, -- segundos em silencio para o Caseiro voltar pra cama

	MONSTRO_VEL_ANDAR = 10,
	MONSTRO_VEL_CACAR = 15,
	MONSTRO_VISAO = 60,
	MONSTRO_ALCANCE_PEGAR = 4.5,
}
