# 🤝 Contribuindo com o OmegaSub — Legendas PT-BR

Obrigado pelo interesse em melhorar o projeto!

## 💡 Sugestões e problemas

Antes de abrir uma nova [issue](https://github.com/JulianoHOmega/Legendas-PTBR/issues), verifique se o assunto já foi relatado.

Para reportar um problema, informe:

- Sistema operacional e versão (Windows ou distribuição Linux).
- Versão do OmegaSub — Legendas PT-BR e forma de execução (`.exe`, `.tar.gz` ou código-fonte).
- Passos para reproduzir o erro.
- Resultado esperado e resultado observado.
- Mensagem de erro ou log relevante, removendo dados pessoais e caminhos privados.

Não compartilhe credenciais, tokens nem arquivos de vídeo protegidos por direitos autorais.

## 🧑‍💻 Enviando código

1. Faça um **fork** do repositório.
2. Crie uma branch com nome descritivo, por exemplo `fix/busca-series`.
3. Faça alterações pequenas e focadas.
4. Teste o funcionamento afetado, especialmente buscas, downloads e identificação de episódios.
5. Evite modificar a experiência do Windows ao corrigir problemas específicos do Linux, e vice-versa.
6. Abra um [pull request](https://github.com/JulianoHOmega/Legendas-PTBR/pulls) explicando o que mudou, como testou e se há limitações.

## 🛠️ Preparando o ambiente

```bash
git clone https://github.com/SEU-USUARIO/OmegaSub.git
cd OmegaSub
python -m venv .venv
```

Ative o ambiente virtual correspondente ao seu sistema e execute:

```bash
pip install -r requirements.txt
python main.py
```

Se houver testes automatizados compatíveis com seu ambiente, execute-os antes de enviar a contribuição.

## 📌 Diretrizes

- Mantenha a interface e as mensagens voltadas ao público brasileiro.
- Prefira soluções simples e compatíveis com os dois sistemas operacionais.
- Não adicione segredos, credenciais ou serviços pagos sem discussão prévia.
- Respeite os termos dos provedores de legendas e os direitos de terceiros.
- Não inclua binários ou arquivos grandes sem necessidade.
- Atualize a documentação quando uma mudança alterar a experiência do usuário.

## 📜 Licença

Ao contribuir, você concorda que suas contribuições sejam distribuídas sob a [Licença MIT](LICENSE) do projeto.

Obrigado por contribuir! 🇧🇷
