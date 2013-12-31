SYS_LUA_HOME = $(CURDIR)/..
SYS_LUA_LIB = $(SYS_LUA_HOME)/lib
SYS_LUA_CORE_FILE = $(SYS_LUA_HOME)/lib/sl_core.lua

BIT = 64bit

ifeq ($(BIT), 64bit)
BIT64 = -m64
endif

libuvm_sl_ml.so : uvm_ml_adapter.c Makefile
	gcc -Werror -g $(BIT64) uvm_ml_adapter.c -I$(LUA_HOME)/include \
	-L$(LUA_HOME)/lib -llua \
	-I$(UVM_ML_HOME)/ml/backplane \
	-L$(UVM_ML_HOME)/ml/libs/backplane/$(BIT) -luvm_ml_bp \
        -DSYS_LUA_CORE_FILE=\"$(SYS_LUA_CORE_FILE)\" \
        -fPIC -shared -o $@

clean :
	rm libuvm_sl_ml.so
