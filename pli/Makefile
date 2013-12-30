SYS_LUA_HOME = $(CURDIR)/..
SYS_LUA_LIB = $(SYS_LUA_HOME)/lib
SYS_LUA_CORE_FILE = $(SYS_LUA_HOME)/lib/sl_core.lua

libsys_lua.so : vpi_user.c sys_lua.c sys_lua.h Makefile
	gcc vpi_user.c sys_lua.c -I$(VCS_HOME)/include -I$(LUA_HOME)/include \
	-DSYS_LUA_CORE_FILE=\"$(SYS_LUA_CORE_FILE)\" \
	-llua -L$(LUA_HOME)/lib -fPIC -shared -o libsys_lua.so

clean:
	rm libsys_lua.so
