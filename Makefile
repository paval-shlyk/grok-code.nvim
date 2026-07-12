.PHONY: test lint format

test:
	nvim --headless --clean -u tests/minimal_init.lua \
		-c "lua require('plenary.test_harness').test_directory('tests', {minimal_init = 'tests/minimal_init.lua'})" \
		-c "qall"

smoke:
	nvim --headless --clean -u tests/minimal_init.lua \
		-c "lua require('grok-code').setup()" \
		-c "lua print('✓ Smoke test passed')" \
		-c "qall"

lint:
	@command -v stylua >/dev/null 2>&1 && stylua --check lua/ tests/ || echo "stylua not found"
	@command -v luacheck >/dev/null 2>&1 && luacheck lua/ || echo "luacheck not found (install with luarocks)"

format:
	stylua lua/ tests/
