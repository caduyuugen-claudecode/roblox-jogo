# roblox-jogo

Jogo de Roblox feito em Luau com Rojo. Cada push na branch `main` monta o jogo e publica no Roblox automaticamente (GitHub Actions + Open Cloud).

- `src/server`, `src/client`, `src/shared`: código do jogo
- `default.project.json`: estrutura do jogo (Rojo)
- `roblox.json`: Universe ID e Place ID
- Segredo necessário no repositório: `ROBLOX_API_KEY`
