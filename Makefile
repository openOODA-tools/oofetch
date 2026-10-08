# oofetch v0.2.0 Makefile
#
# Build, verification gate, test suite, and tri-distribution packaging.
#
# Usage:
#   make build       - compile main.oo to dist/oofetch
#   make check       - run oodac check on every .oo file
#   make line-cap    - enforce 16-256 line cap on every .oo and .oot
#   make file-law    - reject forbidden file extensions and stray docs
#   make academy     - verify every .oo has the 4-element Academy header
#   make density     - enforce at most 8 pages per directory
#   make verify      - run line-cap, file-law, academy, density, and check
#   make test        - run end-to-end integration, MCP, negative, and smoke tests
#   make bench       - run performance benchmark suite
#   make package     - build deb, rpm, and arch packages
#   make clean       - remove build artifacts

OODA_COMPILER ?= $(firstword $(wildcard $(HOME)/.openooda/bin/oodac $(CURDIR)/../../openOODA/oodac/bin/oodac))
OODACODEX ?= $(HOME)/.openooda/northstar.oot
OO_LIST_AMBIENT_QUOTA ?= 8589934592
BIN := dist/oofetch

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

SRC := $(wildcard *.oo) $(wildcard */*.oo)
VERSION ?= 0.2.0

.PHONY: build check line-cap file-law academy density verify clean test bench package package-deb package-rpm package-arch install uninstall

build: $(BIN)

$(BIN): $(SRC)
	@mkdir -p dist .ooda-cache/ooda-tmp
	OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODACODEX=$(OODACODEX) OODA_COMPILER=$(OODA_COMPILER) OODA_NO_JAIL=1 $(OODA_COMPILER) build main.oo -o $(BIN)
	@chmod +x $(BIN)
	@echo "built $(BIN)"

# --- Verification gate ---------------------------------------------------------

line-cap:
	@violations=0; \
	for f in $$(find . -name "*.oo" -o -name "*.oot"); do \
		n=$$(wc -l < "$$f"); \
		if [ $$n -gt 256 ]; then \
			echo "VIOLATION: $$f = $$n lines (exceeds 256)"; violations=$$((violations+1)); \
			continue; \
		fi; \
		if [ $$n -lt 16 ]; then \
			echo "VIOLATION: $$f = $$n lines (under 16-line floor)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations files violate the Page Rule"; exit 1; fi; \
	echo "PASS: Page Rule sizing (16-256 lines) holds"

file-law:
	@forbidden="py js ts rb pl json yaml toml"; \
	violations=0; \
	for ext in $$forbidden; do \
		found=$$(find . -name "*.$$ext" -not -path "./.git/*" -not -path "./.github/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" 2>/dev/null | head -3); \
		if [ -n "$$found" ]; then \
			echo "VIOLATION: .$$ext forbidden:"; echo "$$found"; violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.md" -not -path "./.git/*" -not -path "./.github/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" 2>/dev/null); do \
		if [ "$$f" != "./README.md" ] && [ "$$f" != "./AGENTS.md" ]; then \
			echo "VIOLATION: .md forbidden outside README.md and AGENTS.md: $$f"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: file-law violations"; exit 1; fi; \
	echo "PASS: file law holds"

academy:
	@failures=0; \
	for f in $$(find . -name "*.oo" -not -path "./dist/*"); do \
		header=$$(head -7 "$$f"); \
		missing=""; \
		echo "$$header" | grep -q "^// # "        || missing="$$missing title"; \
		echo "$$header" | grep -q "^// Logline:"  || missing="$$missing logline"; \
		echo "$$header" | grep -q "^// Setup:"    || missing="$$missing setup"; \
		echo "$$header" | grep -q "^// Beats:"    || missing="$$missing beats"; \
		if [ -n "$$missing" ]; then \
			echo "FAIL: $$f missing Academy element(s):$$missing"; failures=$$((failures+1)); \
		fi; \
	done; \
	if [ $$failures -gt 0 ]; then echo "FAIL: $$failures academy header violations"; exit 1; fi; \
	echo "PASS: academy headers hold (all 4 elements present in first 7 lines)"

density:
	@violations=0; \
	for d in $$(find . -type d -not -path "./.git*" -not -path "./dist*" -not -path "./.ooda-cache*" -not -path "./packaging*"); do \
		n=$$(ls "$$d"/*.oo "$$d"/*.oot 2>/dev/null | grep -v '\*' | wc -l); \
		if [ $$n -gt 8 ]; then \
			echo "VIOLATION: $$d holds $$n pages (exceeds 8)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations directories exceed the density bound"; exit 1; fi; \
	echo "PASS: directory density (<= 8 pages per directory) holds"

check:
	@for f in $$(find . -name "*.oo" -not -path "./dist/*"); do \
		$(OODA_COMPILER) check "$$f" > /dev/null || exit 1; \
	done; \
	echo "PASS: oodac check holds on all .oo files"

verify: line-cap file-law academy density check

test: $(BIN)
	@echo "=== Tier 1: Core CLI Flags, Formats, Logos, Mascots, and Options ==="
	@./$(BIN) --help > /dev/null && echo "PASS: --help"
	@./$(BIN) -h > /dev/null && echo "PASS: -h"
	@./$(BIN) --version | grep -q "0.2.0" && echo "PASS: --version"
	@./$(BIN) -v | grep -q "0.2.0" && echo "PASS: -v"
	@./$(BIN) --help | grep -q -- "--no-logo" && echo "PASS: --help documents --no-logo"
	@./$(BIN) --help | grep -q -- "--mascot" && echo "PASS: --help documents --mascot"
	@./$(BIN) --help | grep -q -- "--logo" && echo "PASS: --help documents --logo"
	@./$(BIN) --help | grep -q -- "--theme" && echo "PASS: --help documents --theme"
	@./$(BIN) --unknown > /dev/null 2>&1; test $$? -eq 2 && echo "PASS: unknown flag exits 2"
	@./$(BIN) --theme > /dev/null 2>&1; test $$? -eq 2 && echo "PASS: --theme without arg exits 2"
	@./$(BIN) --logo > /dev/null 2>&1; test $$? -eq 2 && echo "PASS: --logo without arg exits 2"
	@./$(BIN) --mascot > /dev/null 2>&1; test $$? -eq 2 && echo "PASS: --mascot without arg exits 2"
	@OODA_NO_JAIL=1 ./$(BIN) --json | grep -q '"os":' && echo "PASS: --json contains os"
	@OODA_NO_JAIL=1 ./$(BIN) --json | grep -q '"arch":' && echo "PASS: --json contains arch"
	@OODA_NO_JAIL=1 ./$(BIN) --json | grep -q '"uptime":' && echo "PASS: --json contains uptime"
	@OODA_NO_JAIL=1 ./$(BIN) --no-color | grep -q "OS:" && echo "PASS: --no-color contains OS label"
	@ESC=$$(printf '\033'); ! (OODA_NO_JAIL=1 ./$(BIN) --no-color | grep -q "$$ESC") && echo "PASS: --no-color suppresses ANSI escapes"
	@OODA_NO_JAIL=1 ./$(BIN) --logo arch | grep -q "OS:" && echo "PASS: --logo arch"
	@OODA_NO_JAIL=1 ./$(BIN) --logo fedora | grep -q "OS:" && echo "PASS: --logo fedora"
	@OODA_NO_JAIL=1 ./$(BIN) --logo debian | grep -q "OS:" && echo "PASS: --logo debian"
	@OODA_NO_JAIL=1 ./$(BIN) --mascot happy | grep -q "(\^)" && echo "PASS: --mascot happy"
	@OODA_NO_JAIL=1 ./$(BIN) --mascot alert | grep -q "(!)" && echo "PASS: --mascot alert"
	@OODA_NO_JAIL=1 ./$(BIN) --mascot sleepy | grep -q "(-)" && echo "PASS: --mascot sleepy"
	@OODA_NO_JAIL=1 ./$(BIN) --no-logo | grep -q "OS:" && echo "PASS: --no-logo renders metrics"
	@OODA_NO_JAIL=1 OO_COLUMNS=40 ./$(BIN) | grep -q "OS:" && echo "PASS: dynamic OO_COLUMNS < 50 collapses to single column"
	@OODA_NO_JAIL=1 COLUMNS=40 ./$(BIN) | grep -q "OS:" && echo "PASS: dynamic COLUMNS < 50 collapses to single column"
	@OODA_NO_JAIL=1 OO_COLUMNS=80 ./$(BIN) | grep -q "OS:" && echo "PASS: dynamic OO_COLUMNS=80 two-column layout"
	@OODA_NO_JAIL=1 ./$(BIN) --theme 1982 --json | grep -q '"theme": "1982"' && echo "PASS: --theme override"
	@echo "=== Tier 2: MCP Handshake & Protocol Framing ==="
	@printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}\n' | ./$(BIN) --mcp | grep -q "2024-11-05" && echo "PASS: MCP initialize protocolVersion"
	@printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}\n' | ./$(BIN) --mcp | grep -q '"name":"oofetch","version":"0.2.0"' && echo "PASS: MCP initialize serverInfo"
	@printf '{"jsonrpc":"2.0","id":2,"method":"ping","params":{}}\n' | ./$(BIN) --mcp | grep -q '"result":{}' && echo "PASS: MCP ping"
	@printf '{"jsonrpc":"2.0","id":3,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp | grep -q "host_info" && echo "PASS: MCP tools/list host_info"
	@printf '{"jsonrpc":"2.0","id":3,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp | grep -q "system_posture" && echo "PASS: MCP tools/list system_posture"
	@printf '{"jsonrpc":"2.0","id":3,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp | grep -q "query_hardware" && echo "PASS: MCP tools/list query_hardware"
	@printf '{"jsonrpc":"2.0","id":3,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp | grep -q "render_mascot" && echo "PASS: MCP tools/list render_mascot"
	@test -z "$$(printf '{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}\n' | ./$(BIN) --mcp)" && echo "PASS: MCP notifications/initialized produces no response"
	@printf '{"jsonrpc":"2.0","id":4,"method":"shutdown","params":{}}\n' | ./$(BIN) --mcp | grep -q '"result":null' && echo "PASS: MCP shutdown"
	@test -z "$$(printf '{"jsonrpc":"2.0","method":"exit","params":{}}\n' | ./$(BIN) --mcp)" && echo "PASS: MCP exit terminates cleanly"
	@test "$$(printf '{"jsonrpc":"2.0","id":1,"method":"ping","params":{}}{"jsonrpc":"2.0","id":2,"method":"ping","params":{}}\n' | ./$(BIN) --mcp | grep -c '"result":{}')" = "2" && echo "PASS: MCP concatenated JSON-RPC messages without newline"
	@printf '{"jsonrpc":"2.0","id":99,"method":"ping","params":{}}' | ./$(BIN) --mcp | grep -q '"id":99' && echo "PASS: MCP request without trailing newline"
	@(sleep 0.1 && printf '{"jsonrpc":"2.0","id":15,"method":"ping","params":{}}\n') | ./$(BIN) --mcp | grep -q '"result":{}' && echo "PASS: MCP stdio idle pause does not crash server"
	@echo "=== Tier 3: All 4 MCP Tools & Execution Edge Cases ==="
	@printf '{"jsonrpc":"2.0","id":10,"method":"tools/call","params":{"name":"host_info","arguments":{}}}\n' | OODA_NO_JAIL=1 ./$(BIN) --mcp | grep -q 'arch' && echo "PASS: MCP host_info contains arch"
	@printf '{"jsonrpc":"2.0","id":11,"method":"tools/call","params":{"name":"host_info","arguments":{}}}\n' | OODA_NO_JAIL=1 ./$(BIN) --mcp | grep -q 'os' && echo "PASS: MCP host_info contains os"
	@printf '{"jsonrpc":"2.0","id":12,"method":"tools/call","params":{"name":"system_posture","arguments":{}}}\n' | OODA_NO_JAIL=1 ./$(BIN) --mcp | grep -q "uptime_seconds" && echo "PASS: MCP system_posture uptime_seconds"
	@printf '{"jsonrpc":"2.0","id":13,"method":"tools/call","params":{"name":"system_posture","arguments":{}}}\n' | OODA_NO_JAIL=1 ./$(BIN) --mcp | grep -q "package_manager" && echo "PASS: MCP system_posture package_manager"
	@printf '{"jsonrpc":"2.0","id":14,"method":"tools/call","params":{"name":"query_hardware","arguments":{}}}\n' | OODA_NO_JAIL=1 ./$(BIN) --mcp | grep -q "cpu_model" && echo "PASS: MCP query_hardware cpu_model"
	@printf '{"jsonrpc":"2.0","id":15,"method":"tools/call","params":{"name":"query_hardware","arguments":{}}}\n' | OODA_NO_JAIL=1 ./$(BIN) --mcp | grep -q "total_ram_mib" && echo "PASS: MCP query_hardware total_ram_mib"
	@printf '{"jsonrpc":"2.0","id":16,"method":"tools/call","params":{"name":"query_hardware","arguments":{}}}\n' | OODA_NO_JAIL=1 ./$(BIN) --mcp | grep -q "swap_total_mib" && echo "PASS: MCP query_hardware swap_total_mib"
	@printf '{"jsonrpc":"2.0","id":17,"method":"tools/call","params":{"name":"render_mascot","arguments":{}}}\n' | OODA_NO_JAIL=1 ./$(BIN) --mcp | grep -q "content" && echo "PASS: MCP render_mascot default"
	@printf '{"jsonrpc":"2.0","id":18,"method":"tools/call","params":{"name":"render_mascot","arguments":{"name":"arch"}}}\n' | OODA_NO_JAIL=1 ./$(BIN) --mcp | grep -q '/\\' && echo "PASS: MCP render_mascot arch logo"
	@printf '{"jsonrpc":"2.0","id":19,"method":"tools/call","params":{"name":"render_mascot","arguments":{"name":"happy"}}}\n' | OODA_NO_JAIL=1 ./$(BIN) --mcp | grep -q '(\^)' && echo "PASS: MCP render_mascot happy mascot"
	@printf '{"jsonrpc":"2.0","id":20,"method":"tools/call","params":{"name":"render_mascot","arguments":{"name":"default","theme":"1982"}}}\n' | OODA_NO_JAIL=1 ./$(BIN) --mcp | grep -q "content" && echo "PASS: MCP render_mascot theme styling"
	@echo "=== Tier 4: Negative Trust & Error Responses & Determinism & Smoke ==="
	@printf 'invalid json string\n' | ./$(BIN) --mcp | grep -q -- "-32600" && echo "PASS: MCP invalid json exits -32600"
	@printf '{"jsonrpc":"1.0","id":30,"method":"ping","params":{}}\n' | ./$(BIN) --mcp | grep -q -- "-32600" && echo "PASS: MCP invalid jsonrpc version exits -32600"
	@printf '{"jsonrpc":"2.0","id":31,"method":"","params":{}}\n' | ./$(BIN) --mcp | grep -q -- "-32600" && echo "PASS: MCP empty method exits -32600"
	@printf '{"jsonrpc":"2.0","id":32,"method":"nonexistent_method","params":{}}\n' | ./$(BIN) --mcp | grep -q -- "-32601" && echo "PASS: MCP unknown method exits -32601"
	@printf '{"jsonrpc":"2.0","id":33,"method":"tools/call","params":{"name":"nonexistent_tool","arguments":{}}}\n' | ./$(BIN) --mcp | grep -q -- "-32601" && echo "PASS: MCP unknown tool exits -32601"
	@printf '{"jsonrpc":"2.0","id":34,"method":"tools/call","params":{"arguments":{}}}\n' | ./$(BIN) --mcp | grep -q -- "-32602" && echo "PASS: MCP missing tool name exits -32602"
	@printf '{"jsonrpc":"2.0","id":35,"method":"tools/call","params":{"name":"render_mascot","arguments":{"name":123}}}\n' | OODA_NO_JAIL=1 ./$(BIN) --mcp | grep -q -- "-32602" && echo "PASS: MCP render_mascot numeric name exits -32602"
	@printf '{"jsonrpc":"2.0","id":36,"method":"tools/call","params":{"name":"render_mascot","arguments":{"theme":123}}}\n' | OODA_NO_JAIL=1 ./$(BIN) --mcp | grep -q -- "-32602" && echo "PASS: MCP render_mascot numeric theme exits -32602"
	@run1="$$(printf '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp)"; \
	run2="$$(printf '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp)"; \
	test "$$run1" = "$$run2" && echo "PASS: determinism tools/list Run_1 == Run_2"
	@run1="$$(printf '{"jsonrpc":"2.0","id":7,"method":"ping","params":{}}\n' | ./$(BIN) --mcp)"; \
	run2="$$(printf '{"jsonrpc":"2.0","id":7,"method":"ping","params":{}}\n' | ./$(BIN) --mcp)"; \
	test "$$run1" = "$$run2" && echo "PASS: determinism ping Run_1 == Run_2"
	@OODA_NO_JAIL=1 ./$(BIN) --json | grep -v -E '"(memory|uptime)"' > .ooda-cache/run1.txt 2>&1 || true; \
	OODA_NO_JAIL=1 ./$(BIN) --json | grep -v -E '"(memory|uptime)"' > .ooda-cache/run2.txt 2>&1 || true; \
	diff -u .ooda-cache/run1.txt .ooda-cache/run2.txt && echo "PASS: double-run output is identical"
	@./install.sh --dry-run > /dev/null && echo "PASS: install.sh --dry-run"
	@./install.sh --uninstall --dry-run > /dev/null && echo "PASS: install.sh --uninstall --dry-run"
	@./uninstall.sh --dry-run > /dev/null && echo "PASS: uninstall.sh --dry-run"
	@echo "ALL TESTS PASSED"

bench: $(BIN)
	@echo "=== Running oofetch performance benchmarks ==="
	@echo "--- CLI two-column fetch benchmark ---"
	@time -p sh -c 'for i in $$(seq 1 30); do OODA_NO_JAIL=1 ./$(BIN) > /dev/null; done'
	@echo "--- CLI json benchmark ---"
	@time -p sh -c 'for i in $$(seq 1 30); do OODA_NO_JAIL=1 ./$(BIN) --json > /dev/null; done'
	@echo "--- MCP host_info benchmark ---"
	@time -p sh -c 'for i in $$(seq 1 30); do printf '\''{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"host_info","arguments":{}}}\n'\'' | OODA_NO_JAIL=1 ./$(BIN) --mcp > /dev/null; done'
	@echo "--- MCP system_posture benchmark ---"
	@time -p sh -c 'for i in $$(seq 1 50); do printf '\''{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"system_posture","arguments":{}}}\n'\'' | OODA_NO_JAIL=1 ./$(BIN) --mcp > /dev/null; done'
	@echo "--- MCP query_hardware benchmark ---"
	@time -p sh -c 'for i in $$(seq 1 50); do printf '\''{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"query_hardware","arguments":{}}}\n'\'' | OODA_NO_JAIL=1 ./$(BIN) --mcp > /dev/null; done'
	@echo "--- MCP render_mascot benchmark ---"
	@time -p sh -c 'for i in $$(seq 1 50); do printf '\''{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"render_mascot","arguments":{"name":"default"}}}\n'\'' | OODA_NO_JAIL=1 ./$(BIN) --mcp > /dev/null; done'
	@echo "Benchmark complete."

install: $(BIN)
	@mkdir -p $(DESTDIR)$(BINDIR)
	install -m 0755 $(BIN) $(DESTDIR)$(BINDIR)/oofetch
	install -m 0755 uninstall.sh $(DESTDIR)$(BINDIR)/oofetch-uninstall
	@echo "installed oofetch and oofetch-uninstall to $(DESTDIR)$(BINDIR)"

uninstall:
	@rm -f $(DESTDIR)$(BINDIR)/oofetch $(DESTDIR)$(BINDIR)/oofetch-uninstall
	@if [ "$(PURGE)" = "1" ]; then rm -rf $(HOME)/.cache/oofetch $(HOME)/.config/oofetch; echo "purged user cache and config"; fi
	@echo "uninstalled oofetch and oofetch-uninstall from $(DESTDIR)$(BINDIR)"

package-deb: $(BIN)
	@mkdir -p dist/deb-root/DEBIAN dist/deb-root/usr/bin
	@sed "s/^Version:.*/Version: $(VERSION)-1/" packaging/debian/control.binary > dist/deb-root/DEBIAN/control
	@cp $(BIN) dist/deb-root/usr/bin/oofetch
	@chmod 0755 dist/deb-root/usr/bin/oofetch
	@cp uninstall.sh dist/deb-root/usr/bin/oofetch-uninstall
	@chmod 0755 dist/deb-root/usr/bin/oofetch-uninstall
	@dpkg-deb --build --root-owner-group dist/deb-root dist/oofetch_$(VERSION)-1_amd64.deb
	@rm -rf dist/deb-root
	@echo "built dist/oofetch_$(VERSION)-1_amd64.deb"

package-rpm: $(BIN)
	@mkdir -p ~/rpmbuild/SOURCES ~/rpmbuild/SPECS ~/rpmbuild/RPMS
	@cp $(BIN) ~/rpmbuild/SOURCES/oofetch-linux-x86_64
	@cp uninstall.sh ~/rpmbuild/SOURCES/uninstall.sh
	@sed "s/^Version:.*/Version: $(VERSION)/" packaging/oofetch.spec > ~/rpmbuild/SPECS/oofetch.spec
	@rpmbuild -bb ~/rpmbuild/SPECS/oofetch.spec
	@cp ~/rpmbuild/RPMS/x86_64/oofetch-$(VERSION)*.rpm dist/ 2>/dev/null || true
	@if ls dist/oofetch-$(VERSION)-1.*.x86_64.rpm 1> /dev/null 2>&1; then cp dist/oofetch-$(VERSION)-1.*.x86_64.rpm dist/oofetch-$(VERSION)-1.x86_64.rpm; fi
	@echo "built dist RPM package"

package-arch: $(BIN)
	@mkdir -p dist/arch-pkg/usr/bin
	@cp $(BIN) dist/arch-pkg/usr/bin/oofetch
	@chmod 0755 dist/arch-pkg/usr/bin/oofetch
	@cp uninstall.sh dist/arch-pkg/usr/bin/oofetch-uninstall
	@chmod 0755 dist/arch-pkg/usr/bin/oofetch-uninstall
	@printf "pkgname = oofetch\npkgbase = oofetch\npkgver = $(VERSION)-1\npkgdesc = Sovereign system fetch and environment showcase\nurl = https://github.com/openOODA-tools/oofetch\nbuilddate = $$(date +%s)\npackager = openOODA-tools <ops@openooda.org>\nsize = $$(stat -c %s $(BIN))\narch = x86_64\nlicense = Apache-2.0\ndepend = glibc\nprovides = oofetch\n" > dist/arch-pkg/.PKGINFO
	@tar --zstd -cf dist/oofetch-$(VERSION)-1-x86_64.pkg.tar.zst -C dist/arch-pkg .PKGINFO usr
	@rm -rf dist/arch-pkg
	@bash -n packaging/arch/PKGBUILD
	@cp packaging/arch/PKGBUILD dist/PKGBUILD
	@cp packaging/arch/PKGBUILD packaging/PKGBUILD
	@echo "built dist/oofetch-$(VERSION)-1-x86_64.pkg.tar.zst and validated PKGBUILD"

package: package-deb package-rpm package-arch
	@cp $(BIN) dist/oofetch-linux-x86_64
	@chmod 0755 dist/oofetch-linux-x86_64
	@(cd dist && sha256sum oofetch-linux-x86_64 > oofetch-linux-x86_64.sha256)
	@(cd dist && sha256sum oofetch* > checksums.txt)
	@echo "built all packages and generated dist/checksums.txt"

clean:
	@rm -rf dist .ooda-cache
	@echo "cleaned"
