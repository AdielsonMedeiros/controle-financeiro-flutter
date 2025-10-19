# Configuração de Segurança

## Arquivos Sensíveis

Os seguintes arquivos contêm informações sensíveis e não devem ser versionados:

### Android
- `android/key.properties` - Credenciais de assinatura da aplicação
- `android/app/google-services.json` - Configuração do Firebase
- `android/app/*.jks` - Arquivos de keystore

### iOS
- `ios/Runner/GoogleService-Info.plist` - Configuração do Firebase

## Configuração

### 1. Key Properties
Copie `android/key.properties.example` para `android/key.properties` e configure as variáveis:

```bash
cp android/key.properties.example android/key.properties
```

Configure as variáveis de ambiente ou edite o arquivo diretamente:
- `KEYSTORE_PASSWORD` - Senha do keystore
- `KEY_PASSWORD` - Senha da chave
- `KEY_ALIAS` - Alias da chave
- `KEYSTORE_FILE` - Caminho para o arquivo keystore

### 2. Firebase
- Baixe `google-services.json` do console do Firebase
- Coloque em `android/app/google-services.json`
- Para iOS, baixe `GoogleService-Info.plist` e coloque em `ios/Runner/`

## Variáveis de Ambiente (Recomendado)

Para maior segurança, use variáveis de ambiente:

```bash
export KEYSTORE_PASSWORD="sua_senha_keystore"
export KEY_PASSWORD="sua_senha_chave"
export KEY_ALIAS="upload"
export KEYSTORE_FILE="upload-keystore.jks"
```