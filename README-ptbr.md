[![🇺🇸 English](https://img.shields.io/badge/lang-English-blue.svg)](README.md) [![🇧🇷 Português](https://img.shields.io/badge/lang-Português-green.svg)](README-ptbr.md) [![🇪🇸 Español](https://img.shields.io/badge/lang-Español-yellow.svg)](README-es.md)

# logtog

[![Versão](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/sr00t3d/logtog/releases/tag/v2.0.0)
[![Licença](https://img.shields.io/badge/license-Apache--2.0-green.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-4.0%2B-orange.svg)](#requisitos)
[![Plataforma](https://img.shields.io/badge/platform-Linux%20%7C%20cPanel-lightgrey.svg)](#requisitos)

**CLI para auditar e alternar o arquivamento de Raw Access Logs no cPanel (`~/.cpanel-logs`).**

O `logtog.sh` audita e gerencia o arquivamento de logs de acesso (`archive-logs`) e a limpeza mensal automática (`remove-old-archived-logs`) em contas cPanel individuais, revendas (`--reseller`) ou em todo o servidor (`--all`) — operando em **modo `--status` somente-leitura por padrão**, com uso de disco em `~/logs`, `--dry-run` e saídas `table`/`json`/`csv`.

> **Inspiração Histórica:** Reimplementação clean-room em Bash + Python 3.6+ `v2.0.0` inspirada no clássico `logtog` (2011–2012, Jon South / HostGator). Remove a limitação de 8 caracteres em nomes de usuário, adiciona `--status` read-only padrão, `--prune`/`--no-prune`, contagem de disco em `~/logs`, `--dry-run` e JSON/CSV.

---

## Requisitos

- Servidor Linux cPanel/WHM com Bash 4.0+ e Python 3.6+
- Privilégios de `root` para alterar `~/.cpanel-logs` de outras contas

---

## Como Usar

```bash
# Auditoria somente-leitura de uma conta (ou todas)
./logtog.sh percio
./logtog.sh --all --status

# Ativar arquivamento de logs + limpeza mensal automática
./logtog.sh percio --on --prune

# Simular ativação para uma revenda pulando um cliente específico
./logtog.sh --reseller rev1 --on --skip vipacct --dry-run

# Desativar arquivamento de logs
./logtog.sh percio --off

# Exportar em JSON ou CSV
./logtog.sh --all -o json
./logtog.sh --all -o csv
```

---

## Execução Direta

Execute diretamente sem clonar o repositório:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sr00t3d/logtog/main/logtog.sh) --all --status
bash <(curl -fsSL https://raw.githubusercontent.com/sr00t3d/logtog/main/logtog.sh) percio --on --prune --dry-run
```

---

## Autor e Licença

- **Autor:** Percio Castelo — [perciocastelo.com.br](https://perciocastelo.com.br)
- **Página do Projeto:** [perciocastelo.com.br/projetos/br/logtog.html](https://perciocastelo.com.br/projetos/br/logtog.html)
- **Licença:** [Apache-2.0](LICENSE)
