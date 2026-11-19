# 4. API de clima: OpenWeather x Open-Meteo

A OpenWeather era a opção inicial, porque o grupo já a tinha usado em outro trabalho.

## O que cada plano oferece (conferir na conta)

- **Plano gratuito:** clima atual e previsão de 5 dias com intervalos de 3 horas.
- **One Call API 3.0:** inclui histórico por data e resumo diário; é um plano separado ("One Call by Call"), com 1.000 chamadas gratuitas por dia, mas exige assinatura.

## Desafio: "dias sem chuva"

Essa informação depende de histórico. Duas saídas:

1. Usar a One Call 3.0 (histórico por data), se a conta do grupo tiver o plano ativo.
2. Guardar o histórico por conta própria: o app consulta o clima atual todo dia e grava se choveu; a contagem de dias sem chuva sai desse registro. Funciona no plano gratuito, mas o histórico só começa no dia em que for ligado. No protótipo, é possível pré-popular uma sequência simulada e declarar isso nas limitações.

## Decisão final

O app usa a **Open-Meteo** (dados reais, pública e sem chave de API), e não a OpenWeather. Motivos:

- O histórico de chuva (para contar os "dias sem chuva") vem na mesma API, sem plano pago nem cartão.
- Não é preciso guardar chave de API no projeto, o que evita expor credenciais no GitHub.
- O app guarda o último resultado em cache, então o painel de clima continua mostrando dados quando fica sem internet.

A OpenWeather foi avaliada na Sprint 1 e descartada por essas razões. Registro do ajuste de backlog no Trello.
