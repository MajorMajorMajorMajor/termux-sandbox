PREFIX ?= $(HOME)
BINDIR ?= $(PREFIX)/bin
SCRIPTS_DIR ?= $(HOME)/.termux-sandbox/scripts

SCRIPTS = scripts/extract-bootstrap.sh scripts/apply-symlinks.sh scripts/sandbox-relay.sh scripts/sandbox-relay-client.sh scripts/termux-sandbox-lib.sh

.PHONY: install uninstall

install:
	mkdir -p "$(BINDIR)" "$(SCRIPTS_DIR)"
	install -m 755 termux-sandbox asb "$(BINDIR)/"
	install -m 755 $(SCRIPTS) "$(SCRIPTS_DIR)/"

uninstall:
	rm -f "$(BINDIR)/termux-sandbox" "$(BINDIR)/asb"
	for script in $(SCRIPTS); do \
		rm -f "$(SCRIPTS_DIR)/$$(basename $$script)"; \
	done
