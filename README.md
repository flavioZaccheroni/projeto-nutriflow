# NutriFlow Pro

Aplicativo Flutter para nutricionistas com cadastro de pacientes, planos alimentares, PDF profissional, SQLite local e sincronizacao opcional com Supabase.

## Rodar localmente

```powershell
flutter pub get
flutter run -d windows
```

Sem Supabase configurado, o app roda em modo local e salva tudo no SQLite em `nutriflow_data/nutriflow.db`.

## Configurar Supabase

1. Crie um projeto no Supabase.
2. Abra o SQL Editor do Supabase.
3. Cole e execute o conteudo de `supabase_schema.sql`.
4. No Supabase, copie:
   - Project URL
   - anon public key

No Windows, rode o app com:

```powershell
flutter run -d windows `
  --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY
```

Depois entre com e-mail e senha na tela inicial. O app cria conta, autentica e sincroniza pacientes, planos alimentares, refeicoes, alimentos e historico.

## Build Windows com Supabase

```powershell
flutter build windows `
  --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY
```

O executavel sera gerado em `build/windows/x64/runner/Release/nutriflow_pro.exe`.

## Validacao

```powershell
dart analyze
flutter test
flutter build windows
```
