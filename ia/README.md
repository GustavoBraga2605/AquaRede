# IA: CNN de imagens de satélite

Notebook para o Google Colab (use GPU) que treina uma CNN com o EuroSAT RGB reagrupado em quatro classes úteis para a AquaRede.

| Arquivo | Conteúdo |
|---|---|
| `aquarede_cnn.ipynb` | Notebook completo: dataset, reagrupamento das classes, treino, avaliação, exportação e função `prever()` |
| `aquarede_cnn.keras` | Modelo treinado |
| `classes.json` | Ordem das classes: `agua`, `urbano`, `vegetacao_densa`, `campo_aberto` |

As métricas (acurácia, relatório por classe e matriz de confusão) estão nas saídas do notebook. O resultado para os bairros-piloto é salvo em `app/assets/dados/satelite_bairros.json`, que o app lê. A explicação completa está no [README da raiz](../README.md#a-cnn-de-satélite).
