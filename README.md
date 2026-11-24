# NÃO ACORDE O CASEIRO (Roblox)

Terror cooperativo de 1 a vários jogadores. O foguete de vocês caiu no quintal de uma casa de fazenda. Peguem as 6 peças espalhadas pela casa e levem ao foguete, sem acordar o Caseiro.

- Barulho é compartilhado pelo time: andar em pé, pular, pegar peças e esbarrar em panelas/garrafas enche a barra.
- 40+ = o Caseiro levanta e vai até o último barulho. 75+ = ele caça quem estiver à vista.
- Agachado = silêncio (e mais difícil de ser visto). Botão na tela no celular, tecla C no PC.
- 5 minutos por rodada.

Cada push na `main` monta o jogo (Rojo) e publica no Roblox (GitHub Actions + Open Cloud).

- `src/server`: Main (regras), Mapa (casa), Monstro (Caseiro)
- `src/client`: HUD
- `src/shared/Config.luau`: números de balanceamento
- `roblox.json`: Universe ID e Place ID
