# 1. Escopo do MVP

## Entra no protótipo

- Morador registra ocorrência (falta de água, vazamento ou água contaminada) no app, com bairro, tipo e descrição
- Dados de clima via OpenWeather (dias sem chuva e temperatura)
- Nível dos reservatórios com previsão de 30 dias (notebook)
- CNN classificando imagens de satélite dos bairros-piloto
- Motor de alertas que cruza as quatro camadas e explica o resultado (motivo, confiança e limitações)
- Dashboard do gestor: lista de alertas e decisão humana (aprovar, ajustar ou descartar)

## Fica fora do MVP (só se sobrar tempo)

- Notificação push ao gestor
- Classificação automática do tipo de reclamação
- Anonimização dos relatos e política de privacidade
- Mapa de bairros com nível de risco
- Dados dos reservatórios em tempo real (o protótipo usa série histórica)

## Premissas e limitações declaradas

- As ocorrências dos moradores serão **simuladas** nos testes, pois não há base real de reclamações.
- A CNN classifica **uso do solo** em imagens de satélite; ela não mede volume de água. Entra como contexto, e não como medidor de escassez.
- Todo alerta passa por **supervisão humana**: quem decide o que fazer é sempre o gestor.
