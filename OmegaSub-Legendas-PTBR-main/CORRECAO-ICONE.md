# v1.4.1 - diagnostico do icone EXE

O workflow compila um executavel com nome novo para evitar confusao com versoes antigas e verifica a presenca de recursos RT_ICON no PE.

1. Envie todos os arquivos para a raiz do repositorio, incluindo .github e assets.
2. Em Actions, execute Compilar Windows EXE.
3. No log Compilar executavel, procure Icon resources embedded: N (N > 0).
4. Baixe o novo artifact e extraia o EXE. O nome agora e Legendas-PTBR-v1.4.1.exe.
5. No Explorador, ative Exibir > Icones grandes e veja o icone. Se ainda mostrar Python, reinicie o Explorador ou o Windows para limpar o cache visual.

Se o GitHub indicar Icon resources embedded > 0, o icone foi incorporado ao executavel; a visualizacao antiga pode ser cache do Windows.
