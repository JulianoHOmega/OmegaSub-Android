<div align="center">

# 🎬 OmegaSub Android

### Legendas em português brasileiro, direto no seu celular.

**Simples • Gratuito • Sem cadastro • Subliminal local**

[![Versão](https://img.shields.io/badge/vers%C3%A3o-v1.0-dc2626?style=for-the-badge)](https://github.com/JulianoHOmega/OmegaSub-Android/releases/tag/v1.0)
[![Android](https://img.shields.io/badge/Android-APK-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/JulianoHOmega/OmegaSub-Android/releases)
[![Licença MIT](https://img.shields.io/badge/licen%C3%A7a-MIT-2563eb?style=for-the-badge)](LICENSE)

**[⬇️ BAIXAR OMEGASUB ANDROID v1.0](https://github.com/JulianoHOmega/OmegaSub-Android/releases/download/v1.0/OmegaSub-Android.zip)**

[Releases](https://github.com/JulianoHOmega/OmegaSub-Android/releases) · [Reportar problema](https://github.com/JulianoHOmega/OmegaSub-Android/issues) · [Contribuir](CONTRIBUTING.md)

</div>

---

## ✨ Sobre o projeto

O **OmegaSub Android** ajuda você a encontrar e baixar legendas **PT-BR** para filmes e séries a partir de um vídeo armazenado no celular. A busca utiliza o **Subliminal executado localmente no aplicativo**, sem depender de um servidor próprio ou do Render.

> **Importante:** a pesquisa ainda requer conexão com a internet para consultar os provedores externos. A disponibilidade das legendas varia conforme cada provedor.

## 🚀 Funcionalidades

- 🎞️ **Seleção de vídeo:** escolha um arquivo diretamente no Android.
- 🔎 **Identificação pelo nome:** o app identifica informações como título e ano a partir do arquivo.
- ⚡ **Modo automático:** pesquisa e tenta baixar a legenda mais compatível.
- 🖐️ **Modo manual:** consulte resultados e escolha a legenda desejada.
- 🇧🇷 **Foco em PT-BR:** pesquisa de legendas em português brasileiro.
- 📝 **Renomeação automática:** salva a legenda com o nome-base do vídeo e extensão `.srt`.
- 📂 **Escolha da pasta:** utiliza o acesso autorizado pelo Android para salvar o arquivo.
- 🔒 **Sem cadastro:** não exige criar conta no OmegaSub.

## 📥 Download e instalação

1. Acesse o **[download da versão v1.0](https://github.com/JulianoHOmega/OmegaSub-Android/releases/download/v1.0/OmegaSub-Android.zip)**.
2. Extraia o arquivo ZIP e localize o APK incluído no pacote.
3. Abra o APK no celular e autorize a instalação de aplicativos dessa origem, caso o Android solicite.
4. Abra o **OmegaSub** e selecione um vídeo.

**Segurança:** instale somente arquivos obtidos nas releases oficiais do projeto. O Android pode exibir avisos para APKs distribuídos fora da Play Store.

## 📱 Como usar

1. Toque em **Selecionar vídeo**.
2. Aguarde a identificação e a busca de legendas.
3. Com o **modo automático** ativado, o app tenta baixar a melhor opção.
4. Se preferir, consulte a lista e escolha uma legenda manualmente.
5. Autorize uma pasta de destino quando o Android solicitar.

**Exemplo de nomes:**

```text
A odisseia (2026).mp4
A odisseia (2026).srt
```

> **Limitação do Android:** algumas pastas, como a raiz de `Download`, podem impedir a concessão de acesso amplo. Nesses casos, escolha uma subpasta permitida. A correspondência entre títulos e legendas não é perfeita; confira os resultados quando necessário.

## 🧩 Tecnologias

| Tecnologia | Utilização |
|---|---|
| **Flutter / Dart** | Interface do aplicativo |
| **Python + Subliminal** | Pesquisa de legendas |
| **Chaquopy** | Python integrado ao APK Android |
| **GitHub Actions** | Compilação automatizada |

O projeto **não precisa de backend próprio** para a busca de legendas.

## 🛠️ Desenvolvimento

O código-fonte está neste repositório. A compilação Android é automatizada em **Actions**. Para desenvolver localmente, é necessário preparar o ambiente Flutter/Android e as dependências de integração Python descritas no projeto.

Contribuições, relatórios de erros e melhorias são bem-vindos. Leia o [guia de contribuição](CONTRIBUTING.md) antes de enviar alterações.

## ⚖️ Aviso legal

O OmegaSub é uma ferramenta de pesquisa e gerenciamento de legendas. **Não hospeda filmes ou séries** e depende de serviços externos para encontrar legendas. Respeite os direitos autorais e os termos dos provedores. Este projeto não é afiliado aos serviços de legendas consultados.

## 📄 Licença

O código original deste repositório é disponibilizado sob a **[Licença MIT](LICENSE)**. Bibliotecas e dependências de terceiros mantêm suas próprias licenças.

---

<div align="center">

Desenvolvido por **[JulianoHOmega](https://github.com/JulianoHOmega)** ❤️

**[⭐ Se o projeto foi útil, deixe uma estrela no GitHub!](https://github.com/JulianoHOmega/OmegaSub-Android)**

</div>
