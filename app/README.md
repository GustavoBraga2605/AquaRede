# AquaRede: app Flutter

App do projeto AquaRede (painel de alertas de falta de água, com decisão humana). A explicação completa do projeto, do planejamento e das regras de alerta está no [README da raiz](../README.md).

## Rodar

```bash
cd app
flutter pub get
flutter test
flutter run -d chrome
```

Pré-requisitos: Flutter 3.35 ou superior e o Chrome. Não precisa de servidor nem de banco de dados. Se as pastas de plataforma não existirem, rode antes `flutter create . --platforms=web,android,ios --project-name aquarede`.
