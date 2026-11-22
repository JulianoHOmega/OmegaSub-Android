# OmegaSub Android — pasta do vídeo e filtro de resultados

- Subliminal continua rodando localmente, sem Render.
- No primeiro download para uma pasta, o Android solicita que você **selecione a pasta que contém o vídeo**. É uma autorização de pasta, não uma escolha de nome de arquivo.
- A autorização é lembrada; para vídeos na mesma pasta, a legenda `.srt` será salva automaticamente ao lado do vídeo.
- Ao selecionar um vídeo em outra pasta, o Android solicita autorização para essa outra pasta. Esta versão lembra somente a última pasta autorizada.
- A pasta selecionada é validada pela presença do nome exato do vídeo, para evitar salvar no local errado.
- A legenda usa o mesmo nome-base do vídeo. Se já existir `.srt` com esse nome, será substituído.
- Resultados sem correspondência de título/série/hash/ID, com pontuação zero ou com ano explicitamente divergente são descartados antes da listagem e da seleção automática.
- O aviso de rodapé permanece removido.

## Instalação
Substitua os arquivos correspondentes no repositório GitHub, faça um único commit e acompanhe o GitHub Actions.

## Limitações e teste
Não foi compilado nem testado em um aparelho Android neste ambiente. Alguns provedores Subliminal podem não oferecer metadados de correspondência, e o filtro conservador pode descartar legendas legítimas. O seletor de pasta do Android pode restringir diretórios protegidos, como Downloads raiz, Android/data e outros. Para vídeos em pastas diferentes, a autorização será solicitada novamente.
