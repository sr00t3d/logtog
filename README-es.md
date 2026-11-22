[![🇺🇸 English](https://img.shields.io/badge/lang-English-blue.svg)](README.md) [![🇧🇷 Português](https://img.shields.io/badge/lang-Português-green.svg)](README-ptbr.md) [![🇪🇸 Español](https://img.shields.io/badge/lang-Español-yellow.svg)](README-es.md)

# logtog

[![Versión](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/sr00t3d/logtog/releases/tag/v2.0.0)
[![Licencia](https://img.shields.io/badge/license-Apache--2.0-green.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-4.0%2B-orange.svg)](#requisitos)
[![Plataforma](https://img.shields.io/badge/platform-Linux%20%7C%20cPanel-lightgrey.svg)](#requisitos)

**CLI para auditar y alternar el archivado de Raw Access Logs en cPanel (`~/.cpanel-logs`).**

`logtog.sh` audita y activa/desactiva el archivado de logs de acceso (`archive-logs`) y la limpieza mensual (`remove-old-archived-logs`) en cuentas cPanel individuales, revendedores (`--reseller`) o todo el servidor (`--all`) — con **modo `--status` de solo lectura por defecto**, uso de disco en `~/logs`, `--dry-run` y salidas `table`/`json`/`csv`.

> **Inspiración Histórica:** Reimplementación clean-room en Bash + Python 3.6+ `v2.0.0` inspirada en el clásico `logtog` (2011–2012, Jon South / HostGator).

---

## Uso

```bash
# Auditoría de solo lectura
./logtog.sh percio
./logtog.sh --all --status

# Activar archivado + limpieza mensual automática
./logtog.sh percio --on --prune

# Previsualizar cambios sin escribir archivos
./logtog.sh --all --on --dry-run

# Desactivar archivado
./logtog.sh percio --off
```

---

## Ejecución Directa

Ejecuta directamente sin clonar el repositorio:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sr00t3d/logtog/main/logtog.sh) --all --status
bash <(curl -fsSL https://raw.githubusercontent.com/sr00t3d/logtog/main/logtog.sh) percio --on --prune --dry-run
```

---

## Autor y Licencia

- **Autor:** Percio Castelo — [perciocastelo.com.br](https://perciocastelo.com.br)
- **Página del Proyecto:** [perciocastelo.com.br/projetos/en/logtog.html](https://perciocastelo.com.br/projetos/en/logtog.html)
- **Licencia:** [Apache-2.0](LICENSE)
