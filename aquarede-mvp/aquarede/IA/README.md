# AquaRede

Global Solution 2026.2 · Software Engineering (CitizenTech) · FIAP

Plataforma que transforma reclamação solta em evidência: junta o que os moradores relatam com o nível dos reservatórios, o clima e imagens de satélite, para que o poder público aja antes da torneira secar nos bairros mais vulneráveis de São Paulo.

**Equipe:** Gustavo Cordeiro Braga (RM 562247) e Kaio Correa Fernandes da Conceição (RM 563443)

## Estrutura da pasta

| Arquivo | Conteúdo |
|---|---|
| `docs/01-escopo-mvp.md` | O que entra e o que fica fora do protótipo |
| `docs/02-bairros-piloto.md` | Bairros usados nos testes |
| `docs/03-contrato-alerta.md` | Formato padrão do alerta (explicação dos campos) |
| `docs/04-clima-openweather.md` | Decisão sobre a API de clima e "dias sem chuva" |
| `contratos/alerta.exemplo.json` | Exemplo de alerta no formato do contrato |

## Como editar em dupla

- Crie uma branch por alteração (`git checkout -b ajuste-bairros`) e abra um Pull Request.
- Quem não escreveu a alteração revisa antes do merge (isso faz parte da Definição de Pronto no Trello).
- Mudou o contrato JSON? Avise o outro: o motor de alertas (Gustavo) produz o JSON e o dashboard (Kaio) consome.

## Itens para confirmar

Marcados com `TODO` nos arquivos: bairros-piloto, coordenadas, pesos das camadas e plano da API de clima.
