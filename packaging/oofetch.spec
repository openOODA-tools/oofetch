Name:           oofetch
Version:        0.1.0
Release:        1%{?dist}
Summary:        Sovereign system fetch and environment showcase
License:        ASL 2.0
URL:            https://github.com/openOODA-tools/oofetch
Source0:        oofetch-linux-x86_64
Source1:        uninstall.sh
BuildArch:      x86_64
Requires:       glibc

%description
oofetch is a drop-in system fetch replacement written in pure openOODA, featuring
negative-trust capability security, instant terminal rendering, oote theme swatches,
and a first-class Model Context Protocol (MCP) stdio surface for AI agents.

%install
mkdir -p %{buildroot}/usr/bin
install -m 0755 %{SOURCE0} %{buildroot}/usr/bin/oofetch
install -m 0755 %{SOURCE1} %{buildroot}/usr/bin/oofetch-uninstall

%files
/usr/bin/oofetch
/usr/bin/oofetch-uninstall

%changelog
* Wed Oct 07 2026 openOODA-tools <ops@openooda.org> - 0.1.0-1
- Initial sovereign release: instant system fetch, oote palette swatches, and MCP stdio surface
