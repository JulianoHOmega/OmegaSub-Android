# v1.7.1 — Séries e visualização

- Reconhecimento de episódios numerados em pastas de temporada, por exemplo `Alien - Earth/1 (2025)/1 - Terra do nunca.mp4` → `Alien - Earth S01E01`.
- Reconhecimento de arquivos que já contêm `S01E01` ou `1x01`.
- Rejeição de legendas com identificação explícita de temporada/episódio incompatível.
- Correção das cores da tabela manual para evitar texto claro sobre fundo branco.
- Preservado o mecanismo de download de filmes da versão 1.7 (baseado na 1.5).
- A linha de log de diagnóstico permanece fora da interface.

A identificação de séries é baseada em nomes e pastas, não em análise visual ou de áudio. A sincronização não é garantida. Algumas legendas sem metadados de episódio ainda podem ser inadequadas; confira o release antes de baixar.
