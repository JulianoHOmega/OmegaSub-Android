<div align="center">

# 🎬 OmegaSub — Legendas PT-BR

### Encontre e baixe legendas em português brasileiro para seus filmes e séries

[![Windows](https://img.shields.io/badge/Windows-compatível-0078D4?logo=windows&logoColor=white)](https://github.com/JulianoHOmega/Legendas-PTBR/actions)
[![Linux](https://img.shields.io/badge/Linux-x86__64-FCC624?logo=linux&logoColor=black)](https://github.com/JulianoHOmega/Legendas-PTBR/actions)
[![Python](https://img.shields.io/badge/Python-projeto-3776AB?logo=python&logoColor=white)](https://github.com/JulianoHOmega/Legendas-PTBR)
[![License: MIT](https://img.shields.io/badge/Licença-MIT-green.svg)](LICENSE)

**[📥 Downloads e versões](https://github.com/JulianoHOmega/Legendas-PTBR/releases)** · **[⚙️ Compilações (Actions)](https://github.com/JulianoHOmega/Legendas-PTBR/actions)** · **[🐛 Reportar problema](https://github.com/JulianoHOmega/Legendas-PTBR/issues/new)** · **[🤝 Contribuir](CONTRIBUTING.md)**

</div>

---

## ✨ Sobre o projeto

O **OmegaSub — Legendas PT-BR** é um aplicativo de desktop para facilitar a busca e o download de legendas em português brasileiro para vídeos locais. Possui interface gráfica, suporte a filmes e episódios de séries e versões para Windows e Linux.

## 🚀 Funcionalidades

- 🔎 Busca de legendas para filmes e séries.
- 📺 Identificação de episódios por temporada e número do episódio, inclusive em estruturas de pastas.
- 🖱️ Pesquisa e seleção de legendas pela interface gráfica.
- 📁 Processamento de arquivos de vídeo e suporte a operações em lote.
- ⏹️ Possibilidade de cancelar operações.
- 🪟 Interface gráfica com visual escuro.
- 🐧 Distribuição para Linux em pacote `.tar.gz`.
- ⚙️ Compilação por GitHub Actions, sem exigir Python dos usuários dos executáveis.

> **Importante:** os resultados e downloads dependem da disponibilidade de provedores externos. Nem sempre haverá uma legenda adequada ou sincronizada para cada vídeo.

## 📥 Download e uso

Acesse **[Releases](https://github.com/JulianoHOmega/Legendas-PTBR/releases)** para conferir versões publicadas. Caso os executáveis ainda não estejam anexados a uma Release, consulte **[Actions](https://github.com/JulianoHOmega/Legendas-PTBR/actions)** e os artefatos das compilações bem-sucedidas.

### 🪟 Windows

1. Baixe o executável Windows disponibilizado pelo projeto.
2. Abra o arquivo `.exe`.
3. Selecione seus vídeos e pesquise as legendas.

### 🐧 Linux (x86_64)

1. Baixe o pacote Linux `.tar.gz` disponibilizado pelo projeto.
2. Extraia o arquivo, preservando a estrutura das pastas.
3. Abra o executável **`OmegaSub`** diretamente dentro da pasta extraída.

Se o Linux não permitir a execução por falta de permissão, abra um terminal na pasta do executável e execute:

```bash
chmod +x ./OmegaSub
./OmegaSub
```

**Não é necessário usar `iniciar.sh` nem instalar Python** para executar o pacote já compilado. A compatibilidade pode variar conforme a distribuição e as bibliotecas disponíveis no sistema.

## 🛠️ Código-fonte e desenvolvimento

O projeto utiliza Python e disponibiliza o código-fonte neste repositório.

```bash
git clone https://github.com/JulianoHOmega/OmegaSub-Legendas-PTBR.git
cd OmegaSub-Legendas-PTBR
python -m venv .venv
```

Ative o ambiente virtual e instale as dependências:

```bash
pip install -r requirements.txt
python main.py
```

> Para desenvolver, é necessário ter uma versão compatível do Python e as dependências do projeto. Os comandos de ativação do ambiente virtual variam entre Windows e Linux.

## 🤝 Como contribuir

Sugestões, relatórios de bugs e melhorias são bem-vindos! Leia o **[guia de contribuição](CONTRIBUTING.md)** antes de enviar alterações.

- [Abrir uma issue](https://github.com/JulianoHOmega/Legendas-PTBR/issues/new)
- [Ver pull requests](https://github.com/JulianoHOmega/Legendas-PTBR/pulls)
- [Consultar histórico de alterações](CHANGELOG.md)

## ⚖️ Licença e responsabilidade

O código deste projeto é disponibilizado sob a **[Licença MIT](LICENSE)**. As legendas encontradas podem estar sujeitas a direitos e condições próprios dos provedores e respectivos titulares. Respeite a legislação aplicável e os termos dos serviços utilizados.

---

<div align="center">

Feito para tornar a busca por legendas PT-BR mais prática. 🇧🇷

**[⬆️ Voltar ao início](#-legendas-pt-br)**

</div>


## Identidade visual

![OmegaSub](assets/omegasub-logo.png)

## Executáveis

- **Windows:** `OmegaSub.exe` (GitHub Actions: `OmegaSub-Windows`).
- **Linux x86_64:** `OmegaSub-Linux-x86_64.tar.gz` (GitHub Actions: `OmegaSub-Linux-TAR-GZ`). Extraia o pacote e abra diretamente o executável `OmegaSub`, sem `iniciar.sh`.
- Os workflows disponibilizam artefatos na aba **Actions**; publicar arquivos na aba **Releases** exige anexá-los à release.

## Observação sobre a mudança de nome

A lógica de busca e download de legendas foi preservada. O diretório de logs continua em `~/Legendas-PTBR/`, preservando a localização usada pela versão anterior.
