PWD:=$(shell pwd)/
BIN_DIR:=$(PWD)bin/

COVERAGE:=$(PWD)stalker-coverage/
COVERAGE_SRC:=$(wildcard $(COVERAGE)lib/*.ts)
COVERAGE_BIN:=$(COVERAGE)dist/coverage.js

AGENT_SRC:=$(wildcard $(PWD)agent/*.ts)
AGENT_BIN:=$(BIN_DIR)_agent.js

TEST_SRC:=$(PWD)src/test.c
TEST_BIN:=$(BIN_DIR)test
TEST_CFLAGS:=-rdynamic

GADGET_URL:=https://github.com/frida/frida/releases/download/12.11.10/frida-gadget-12.11.10-linux-x86_64.so.xz
GADGET_SO:=$(BIN_DIR)frida-gadget-12.11.10-linux-x86_64.so
GADGET_CONFIG:=$(BIN_DIR)frida-gadget-12.11.10-linux-x86_64.config

all: $(AGENT_BIN) $(TEST_BIN) $(GADGET_CONFIG) $(GADGET_SO)

clean:
	rm -rf $(BIN_DIR)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(COVERAGE)package.json:
	git submodule init
	git submodule update

$(COVERAGE)node_modules/:
	cd $(COVERAGE) && npm install

$(COVERAGE_BIN): $(COVERAGE_SRC) $(COVERAGE)package.json | $(COVERAGE)node_modules/
	cd $(COVERAGE) && npm run build

$(PWD)node_modules: $(COVERAGE_BIN)
	npm install

$(AGENT_BIN): $(AGENT_SRC) | $(PWD)node_modules/
	npm run build

agent: $(AGENT_BIN) | $(BIN_DIR)

$(TEST_BIN): $(TEST_SRC) | $(BIN_DIR)
	$(CC) $(TEST_CFLAGS) -o $@ $<

test: $(TEST_BIN)

$(GADGET_SO): | $(BIN_DIR)
	wget -O $(GADGET_SO).xz $(GADGET_URL)
	xz -d $(GADGET_SO).xz

gadget: $(GADGET_SO)

$(GADGET_CONFIG): $(PWD)src/frida-gadget.config | $(BIN_DIR)
	cp $< $@

run:
	LD_PRELOAD=$(GADGET_SO) $(TEST_BIN) 123
	hexdump -C $(TEST_BIN).dat