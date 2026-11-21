# OmegaSub Android · Flutter

Aplicativo Android independente do OmegaSub Windows/Linux. Identifica filmes e episódios pelo nome do arquivo, tem modo automático como padrão, visual escuro e ícone original. O usuário não precisa criar conta ou inserir chave.

## Status real

**Versão 0.1 experimental.** Interface, identificação, seleção de vídeo, ranking e download de `.srt`/ZIP estão implementados. **A busca real ainda exige conectar um catálogo autorizado de legendas**. Não há provedor público funcional embutido: sem `OMEGASUB_CATALOG_URL`, o aplicativo informa claramente que falta configurar a fonte. Não confundir APK compilado com mecanismo de busca validado. O projeto não usa Subliminal, Python ou Chaquopy.

## GitHub Actions — gerar OmegaSub.apk

Envie **todo o conteúdo desta pasta** à raiz do repositório `JulianoHOmega/OmegaSub-Android`, incluindo `.github/workflows/android-apk.yml`. Após o commit, abra **Actions → Compilar OmegaSub Android**, aguarde e baixe o artefato `OmegaSub-Android`. Dentro estará `OmegaSub.apk` (APK de depuração para teste; não é release assinada para distribuição pública).

O workflow cria automaticamente os arquivos padrão de plataforma Android usando `flutter create`, aplica o ícone, executa análise/testes e compila. Não é necessário instalar Flutter no computador. Isso exige internet e depende da versão estável do Flutter e das dependências publicadas.

## Busca sem chave para usuários

O mecanismo suporta um catálogo JSON público HTTPS, mantido por quem distribui o aplicativo ou por uma fonte autorizada. O formato é:

```json
{"subtitles":[{"title":"Exemplo","year":2026,"language":"pt-br","release":"Exemplo.2026.1080p","provider":"Fonte autorizada","url":"https://example.org/exemplo.srt"}]}
```

Para episódios, inclua `season` e `episode`. URLs devem ser HTTPS e apontar para arquivos `.srt` ou `.zip` com `.srt`. **Não coloque legendas sem direito de redistribuição no catálogo.** Para ativar a fonte no build, altere a etapa `Compilar APK` do workflow para:

```
flutter build apk --debug --dart-define=OMEGASUB_CATALOG_URL=https://seu-dominio/catalog.json
```

A fonte pode ser um arquivo público autorizado no GitHub Pages. Isso não é equivalente ao catálogo global do Subliminal: são necessários acordos ou provedores públicos autorizados para alcançar cobertura semelhante. APIs oficiais como SubDL e OpenSubtitles exigem credenciais de aplicação; não inclua chaves privadas em APKs públicos.

## Desenvolvimento local

```
flutter create --platforms=android --project-name omegasub_android --org com.omegasub .
flutter pub get
dart run flutter_launcher_icons
flutter test
flutter build apk --debug
```

Se usar `flutter create` localmente, configure permissão `android.permission.INTERNET` e nome `OmegaSub` no AndroidManifest, como faz o workflow.

## Separação do projeto desktop

Este repositório não contém os arquivos do programa PC. Depois de confirmar que a cópia antiga está salva, é seguro remover do repositório desktop `android/`, `.github/workflows/build-android.yml` e `ANDROID-LEIA-ME.md`. Não remova `.github/workflows/build-windows.yml` nem `.github/workflows/build-linux.yml`.
