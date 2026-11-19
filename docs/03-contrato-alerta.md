# 3. Contrato JSON do alerta

Formato padrão que o **motor de alertas** (Gustavo) produz e o **dashboard** (Kaio) consome. Exemplo completo em `contratos/alerta.exemplo.json`.

## Campos

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | texto | Identificador único do alerta |
| `bairro` | texto | Bairro do alerta |
| `gerado_em` | data/hora (ISO 8601) | Momento em que o alerta foi gerado |
| `nivel_risco` | texto | `baixo`, `medio`, `alto` ou `critico` |
| `score` | número (0 a 1) | Soma ponderada das camadas |
| `confianca` | número (0 a 1) | Confiança do sistema no alerta |
| `motivos` | lista | Evidências que geraram o alerta (ver abaixo) |
| `limitacoes` | lista de textos | O que o gestor precisa saber sobre os limites do alerta |
| `status_gestor` | texto | `pendente`, `aprovado`, `ajustado` ou `descartado` |
| `decisao_gestor` | objeto ou `null` | Preenchido pelo gestor (ver abaixo) |

### Cada item de `motivos`

| Campo | Descrição |
|---|---|
| `camada` | `comunidade`, `mananciais`, `clima` ou `satelite` |
| `evidencia` | Texto curto explicando o que foi observado |
| `peso` | Peso da camada no score |

### `decisao_gestor`

```json
{ "responsavel": "nome", "observacao": "texto livre", "decidido_em": "2026-11-13T10:30:00-03:00" }
```

## Pesos iniciais das camadas (TODO: ajustar após os testes)

| Camada | Peso |
|---|---|
| comunidade | 0.35 |
| mananciais | 0.30 |
| clima | 0.20 |
| satelite | 0.15 |

`score = soma(peso × valor da camada normalizado entre 0 e 1)`
