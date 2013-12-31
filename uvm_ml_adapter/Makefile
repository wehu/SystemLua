SYS_LUA_HOME = $(CURDIR)/..
SYS_LUA_LIB = $(SYS_LUA_HOME)/lib
SYS_LUA_CORE_FILE = $(SYS_LUA_HOME)/lib/sl_core.lua

libuvm_sl_ml.so : uvm_ml_adapter.c Makefile
	gcc uvm_ml_adapter.c -I$(LUA_HOME)/include \
	-L$(LUA_HOME)/lib -llua \
	-I$(UVM_ML_HOME)/ml/backplane \
        -DSYS_LUA_CORE_FILE=\"$(SYS_LUA_CORE_FILE)\" \
        -fPIC -shared -o libuvm_sl_ml.so

clean :
	rm libuvm_sl_ml.so
