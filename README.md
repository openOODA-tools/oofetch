# oofetch

> **Sovereign system fetch and environment showcase for the openOODA era.**  
> *A drop-in `fastfetch` / `neofetch` replacement written in pure openOODA, featuring negative-trust capability security, instant terminal rendering, `oote` theme swatches, and a first-class Model Context Protocol (MCP) surface.*

Part of [openOODA-tools](https://github.com/openOODA-tools).

---

## 1. Installation

`oofetch` has zero runtime dependencies. It compiles to a standalone native binary linked directly with libc.

### Universal Web Installer
Installs the standalone native binary to `/usr/local/bin` (or `~/.local/bin`):

```bash
curl -fsSL https://openooda-tools.github.io/oofetch/install.sh | bash
```

### Debian / Ubuntu (APT)
```bash
# Automated via installer
curl -fsSL https://openooda-tools.github.io/oofetch/install.sh | bash -s -- --apt

# Or manual package install
sudo dpkg -i oofetch_0.1.0-1_amd64.deb
```

### Fedora / RHEL / CentOS (DNF)
```bash
# Automated via installer
curl -fsSL https://openooda-tools.github.io/oofetch/install.sh | bash -s -- --dnf

# Or manual RPM install
sudo dnf install ./oofetch-0.1.0-1.x86_64.rpm
```

### Arch Linux (PKGBUILD)
```bash
# Automated via installer
curl -fsSL https://openooda-tools.github.io/oofetch/install.sh | bash -s -- --arch

# Or manual build via packaging/PKGBUILD
cd packaging && makepkg -si
```

### Clean Uninstaller
To cleanly remove `oofetch` and any installed package manager entries:

```bash
# Automated via standalone uninstaller
curl -fsSL https://openooda-tools.github.io/oofetch/uninstall.sh | bash

# Or via installer flag
curl -fsSL https://openooda-tools.github.io/oofetch/install.sh | bash -s -- --uninstall

# Or preview removal without making changes (dry-run)
curl -fsSL https://openooda-tools.github.io/oofetch/uninstall.sh | bash -s -- --dry-run
```

---

## 2. CLI Usage

```
usage: oofetch [options]

Display host architecture, operating system posture, and theme swatches.

Options:
  -h, --help           display this help and exit
  -v, --version        output version information and exit
      --json           output system posture formatted as JSON
      --no-color       disable ANSI color escapes
      --color          force ANSI color escapes
      --theme <name>   override active oote theme
      --logo <type>    select art type: 'mascot' or 'distro' (default: mascot)
      --mcp            start Model Context Protocol stdio server
```

### Common Examples

```bash
# Display default system fetch with openOODA mascot and active theme
oofetch

# Display distribution emblem (Fedora, Arch, Debian, Linux)
oofetch --logo distro

# Output machine-readable JSON for scripts and telemetry
oofetch --json

# Override active visual theme
oofetch --theme 1982
```

---

## 3. Theming Integration (`oote`)

`oofetch` automatically discovers and synchronizes visual presentation with [oote](https://github.com/openOODA-tools/oote):

- **Configuration File**: Reads `~/.openooda/theme.oot` with `$HOME` fallback.
- **Environment Overrides**: Respects `OODA_THEME`, `OODA_MODE`, and `OODA_BORDER`.
- **Palette Swatches**: Displays full 16-color ANSI swatch blocks matching terminal lighting.

---

## 4. Model Context Protocol (MCP)

`oofetch` includes a built-in JSON-RPC 2.0 MCP server over standard I/O for LLM coding agents:

```bash
oofetch --mcp
```

### Supported Tools:
1. `host_info`: Inspects OS distribution, kernel, hardware product, shell, terminal, CPU model, memory usage, and active theme.
2. `system_posture`: Returns numeric system posture metrics including uptime in seconds, memory percentage, core count, and package counts.

---

## 5. Security & Architecture

- **Zero Ambient Authority**: Written in pure openOODA with capability-bounded tokens (`&FsReadCap`, `&EnvCap`, `&ProcessCap`).
- **No Shell Escapes**: Pure native execution without `/bin/sh` invocations.
- **Page Rule & Academy Governance**: 100% compliant with the openOODA Academy and House Laws codified in [`AGENTS.md`](./AGENTS.md).

---

## 6. License

Apache License, Version 2.0. See [`LICENSE`](./LICENSE) for full text.