SYS_LUA_HOME = $(CURDIR)/..
SYS_LUA_LIB = $(SYS_LUA_HOME)/lib
SYS_LUA_PLI = $(SYS_LUA_HOME)/pli
SYS_LUA_CORE_FILE = $(SYS_LUA_HOME)/lib/sl_core.lua

test:
	LUA_PATH=$(SYS_LUA_LIB)/?.lua lua test.lua

test_component:
	LUA_PATH=$(SYS_LUA_LIB)/?.lua lua test_component.lua

test_socket:
	LUA_PATH=$(SYS_LUA_LIB)/?.lua lua test_socket.lua

test_pli:
	LD_LIBRARY_PATH=$(SYS_LUA_PLI):$(LD_LIBRARY_PATH) \
	vcs -full64 -R -P $(SYS_LUA_PLI)/sys_lua.tab +vpi -L$(SYS_LUA_PLI) -lsys_lua tb.v
