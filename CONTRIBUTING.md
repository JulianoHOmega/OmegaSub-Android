# 🤝 Contribuindo com o OmegaSub Android

Obrigado por querer melhorar o **OmegaSub Android**! O objetivo é manter o aplicativo simples, gratuito e fácil de usar, preservando o funcionamento do Subliminal local.

## Antes de começar

- Confira as [issues existentes](https://github.com/JulianoHOmega/OmegaSub-Android/issues) para evitar trabalhos duplicados.
- Para alterações maiores, abra uma issue descrevendo a proposta antes de implementar.
- Respeite as licenças das dependências e não inclua arquivos de legendas, filmes ou outros conteúdos protegidos sem autorização.

## 🐛 Como reportar um problema

Abra uma [nova issue](https://github.com/JulianoHOmega/OmegaSub-Android/issues/new) com:

1. Modelo do celular e versão do Android.
2. Versão do OmegaSub instalada.
3. Passos para reproduzir o problema.
4. Resultado esperado e resultado observado.
5. Captura de tela ou trecho do log, se possível.

**Privacidade:** remova informações pessoais, caminhos sensíveis e credenciais antes de publicar logs.

## 💡 Como sugerir melhorias

Explique qual problema a melhoria resolve, como o usuário a utilizaria e se a mudança afeta o modo automático, o download ou as permissões de armazenamento.

## 🔧 Enviando código

1. Faça um **fork** do repositório.
2. Crie uma branch com nome descritivo, por exemplo `fix/filtro-legendas`.
3. Implemente uma alteração por vez, evitando mudanças não relacionadas.
4. Execute as verificações aplicáveis, incluindo `flutter analyze` e `flutter test`, quando o ambiente estiver configurado.
5. Verifique a compilação do APK no GitHub Actions, quando possível.
6. Abra um **Pull Request** explicando o que mudou, como testar e quais riscos existem.

## 🎯 Diretrizes do projeto

- Preserve o **Subliminal local** e evite introduzir dependência obrigatória de servidor externo.
- Mantenha a interface em **português brasileiro**.
- Preserve o layout e a identidade visual, salvo quando a alteração for discutida.
- Não quebre o download automático, a renomeação de arquivos ou o modo manual.
- Trate permissões do Android com cuidado e evite solicitar acesso desnecessário.
- Prefira mensagens de erro compreensíveis para quem usa o aplicativo.
- Não adicione credenciais, tokens ou dados pessoais ao repositório.

## 📜 Licença das contribuições

Ao enviar uma contribuição, você concorda que o código enviado poderá ser distribuído sob a [Licença MIT](LICENSE) do projeto. Certifique-se de ter direito de contribuir com o conteúdo.

Obrigado por ajudar o OmegaSub Android a melhorar! 🎬
