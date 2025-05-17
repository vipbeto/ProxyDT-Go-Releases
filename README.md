# ProxyDT-Go-Releases

![DTunnel](https://img.shields.io/badge/DTunnel-Proxy-blue?style=flat-square)

## 📝 Descrição

**ProxyDT-Go-Releases** é o repositório oficial de releases, instalador e menu interativo do proxy DTunnel para Linux. Aqui você encontra o script de instalação automatizada e uma interface simples para gerenciar múltiplas instâncias do proxy, facilitando a implantação e administração do DTunnel no seu servidor.

---

## 📚 Sumário
- [ProxyDT-Go-Releases](#proxydt-go-releases)
  - [📝 Descrição](#-descrição)
  - [📚 Sumário](#-sumário)
  - [⚡ Requisitos](#-requisitos)
  - [🚀 Instalação](#-instalação)
  - [🛠️ Como usar](#️-como-usar)
- [ou](#ou)
    - [Opções disponíveis:](#opções-disponíveis)
  - [🔐 Token de Acesso](#-token-de-acesso)
  - [📦 Atualizações](#-atualizações)
  - [💡 Exemplo de uso](#-exemplo-de-uso)
  - [❓ Suporte](#-suporte)

---

## ⚡ Requisitos

* Distribuição Linux (x86_64, arm64, armv7l ou i386)
* `bash` shell
* Utilitários: `curl`, `jq`, `tar`, `ss`, `systemctl`, `sha256sum`
* Permissões de `sudo` para instalação e manipulação de serviços

## 🚀 Instalação

Execute o script de instalação para baixar e configurar automaticamente o binário mais recente do DTunnel:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/DTunnel0/ProxyDT-Go-Releases/main/install.sh)
```

Ou, se preferir, clone o repositório e execute o instalador manualmente:

```bash
git clone https://github.com/DTunnel0/ProxyDT-Go-Releases.git
cd ProxyDT-Go-Releases
bash install.sh
```

## 🛠️ Como usar

Após a instalação, utilize o menu interativo para gerenciar instâncias do proxy:

```bash
bash main.sh
```

# ou

```bash
main
```

### Opções disponíveis:

* `01` - Abrir nova porta (iniciar proxy)
* `02` - Fechar porta (parar e remover proxy)
* `03` - Reiniciar porta
* `04` - Visualizar log da porta
* `00` - Sair

## 🔐 Token de Acesso

Na primeira execução, o script solicitará seu token de acesso, que será armazenado em `~/.proxy_token` para uso futuro.

## 📦 Atualizações

Para atualizar o binário, basta executar novamente o `install.sh` e selecionar a versão desejada.

## 💡 Exemplo de uso

```bash
# Instale o ProxyDT-Go
bash <(curl -fsSL https://raw.githubusercontent.com/DTunnel0/ProxyDT-Go-Releases/main/install.sh)

# Inicie o menu interativo
main
```

## ❓ Suporte

Em caso de dúvidas, sugestões ou problemas, abra uma issue no [GitHub](https://github.com/DTunnel0/ProxyDT-Go-Releases/issues)