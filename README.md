# OmegaSub Android — Flutter + Subliminal

Este projeto mantém a interface Flutter e o ícone OmegaSub. A busca de legendas é feita **pelo Subliminal Python**, executado em um backend HTTPS. O APK não precisa de chave de API nem de conta para o usuário final, mas **depende de um servidor mantido pelo responsável pelo aplicativo**.

## 1. Iniciar o backend Python

Em um computador/servidor com Python 3.12:

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app:app --host 127.0.0.1 --port 8000
```

Teste: `http://127.0.0.1:8000/health`. Para acesso de celulares externos, publique o backend com **HTTPS**, usando um serviço de hospedagem ou proxy reverso. **Não exponha diretamente uma API sem proteção de abuso**: implemente rate limiting e monitoramento no proxy antes de abrir ao público.

Também é possível criar a imagem Docker: `docker build -t omegasub-backend backend`.

## 2. Configurar a compilação Android

No repositório GitHub Android, abra **Settings → Secrets and variables → Actions → Variables → New repository variable**. Crie `OMEGASUB_API_URL` com a URL HTTPS do backend, por exemplo `https://SEU-SERVIDOR.example` (substitua por um endereço real).

Execute o workflow `Compilar OmegaSub Android`. O artifact será `OmegaSub.apk`. Se não configurar a URL, o APK ainda poderá compilar, mas mostrará mensagem de configuração ausente quando tentar pesquisar.

## 3. Funcionamento

- Escolha um arquivo de vídeo. O app extrai título, ano e episódio do **nome** do arquivo; não envia o vídeo ao servidor.
- No modo automático, a pesquisa começa após a seleção. No modo manual, é possível ajustar o título.
- O servidor usa Subliminal para consultar provedores PT-BR e devolve resultados classificados.
- Selecione uma legenda e salve como `.srt` usando o seletor Android.
- Resultados expiram após 20 minutos; se o download expirar, pesquise novamente.

## Limitações e segurança

- Não é Subliminal executando dentro do APK. É uma arquitetura cliente/servidor que evita dependências Python incompatíveis com Android.
- Não foi validada uma compilação Flutter nem o funcionamento dos provedores reais neste ambiente. Teste o GitHub Actions e o celular antes de publicar como estável.
- O Subliminal pode depender de provedores externos sujeitos a falhas, alterações, restrições e credenciais próprias.
- Uma URL pública e infraestrutura do backend são necessárias; GitHub Pages não executa Python.
- Não hospede legendas sem autorização; respeite direitos autorais e condições dos provedores.


Veja [MIGRACAO_LOCAL.md](MIGRACAO_LOCAL.md) para a versão experimental com Subliminal embutido.


## Correção experimental da dependência srt (22/11/2026)

O GitHub Actions gera um wheel universal `srt==3.5.3` no CI e o Chaquopy o encontra via `--find-links`. Isso contorna o erro `No matching distributions ... srt` observado no log. A compilação e a busca no celular **ainda precisam ser validadas**; outras dependências podem falhar. Não remova o serviço Render antes de confirmar a busca e o download local.
