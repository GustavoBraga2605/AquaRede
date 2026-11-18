# 4. API de clima: OpenWeather

A API escolhida é a OpenWeather, que o grupo já usou em outro trabalho.

## O que cada plano oferece (conferir na conta)

- **Plano gratuito:** clima atual e previsão de 5 dias com intervalos de 3 horas.
- **One Call API 3.0:** inclui histórico por data e resumo diário; é um plano separado ("One Call by Call"), com 1.000 chamadas gratuitas por dia, mas exige assinatura.

## Desafio: "dias sem chuva"

Essa informação depende de histórico. Duas saídas:

1. Usar a One Call 3.0 (histórico por data), se a conta do grupo tiver o plano ativo.
2. Guardar o histórico por conta própria: o app consulta o clima atual todo dia e grava se choveu; a contagem de dias sem chuva sai desse registro. Funciona no plano gratuito, mas o histórico só começa no dia em que for ligado. No protótipo, é possível pré-popular uma sequência simulada e declarar isso nas limitações.

## Decisão

> TODO: escolher uma das opções acima (sugestão para o MVP: opção 2, com a previsão de 5 dias para estimar a chuva futura).
