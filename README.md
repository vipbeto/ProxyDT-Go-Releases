# ProxyDT-Go-Releases

## 📝 Descrição

**ProxyDT-Go-Releases** é uma ferramenta para instalar e gerenciar múltiplas instâncias do proxy DTunnel em servidores Linux. Ela simplifica o processo de instalação, configuração e administração, automatizando o download do binário, criação de serviços `systemd` e gerenciamento de logs.

## ⚡ Requisitos

* Distribuição Linux (x86\_64, arm64, armv7l ou i386)
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