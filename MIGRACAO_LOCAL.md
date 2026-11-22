# OmegaSub Android — Subliminal dentro do APK (experimental)

Este pacote substitui a API Render por Python embutido via Chaquopy. Mantém Flutter e o logotipo.

## Compilar
1. Envie o conteúdo deste ZIP para a raiz do repositório `OmegaSub-Android` no GitHub, preservando pastas.
2. Confirme que `.github/workflows/android-apk.yml` foi substituído.
3. Em **Actions → Compilar OmegaSub Android**, execute o workflow ou faça commit na `main`.
4. Se a compilação passar, baixe o artefato `OmegaSub-Android` e teste busca e download no celular.

**Status:** código preparado; a compatibilidade real de todas as dependências do Subliminal com Chaquopy e a compilação Android ainda precisam ser validadas pelo GitHub Actions. Não é um APK testado.

## Remover Render após teste funcional
1. GitHub → Settings → Secrets and variables → Actions → Variables: exclua `OMEGASUB_API_URL` (se existir).
2. Render Dashboard → serviço OmegaSub-Android → Settings → Delete Service → confirmar.
3. Não há necessidade de manter Dockerfile ou backend remoto. O diretório `backend/` foi retirado.

## Diagnóstico
Se o build falhar na instalação de pacote Python, consulte a saída de `Gradle` no Actions. Algumas dependências nativas podem exigir wheels Android compatíveis. Não é seguro afirmar que Subliminal funcionará no Android sem esse teste.
