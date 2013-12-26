/***
* Copyright (c) 2013 Wei Hu, huwei04@hotmail.com
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
***/

#include <string.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include "sys_lua.h"
#include "vpi_user.h"

static lua_State *L = NULL;

static int lua_stack_base = 0;

static int get_simtime(){
  s_vpi_time time_s = {vpiSimTime};
  vpi_get_time(NULL, &time_s);
  return time_s.low;
}

static void sys_lua_sync(){
  static int ct = 0;
  int delay = get_simtime() - ct;
  ct = get_simtime();

  lua_getglobal(L, "sync_signals");

  if (lua_pcall(L, 0, 0, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));

  lua_getglobal(L, "run");
  lua_pushnil(L);
  lua_pushnumber(L, delay);

  if (lua_pcall(L, 2, 0, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));

}

static int callback(p_cb_data data){
  switch(data->reason){
    case cbValueChange:
      sys_lua_sync();
      break;
    case cbStartOfSimulation:
      break;
    case cbEndOfSimulation:
      //sys_lua_sync();
      lua_close(L);
      break;
    default: break;
  };
  return 0; 
}

static int bind_signal(lua_State * L){
  const char * s = luaL_checkstring(L, 1);
  static s_vpi_time time_s = {vpiSimTime};
  static s_vpi_value value_s = {vpiIntVal};

  static s_cb_data cb_data_s = {cbValueChange, callback, NULL, &time_s, &value_s};
  vpiHandle sig = vpi_handle_by_name((PLI_BYTE8 *)s, NULL);
  cb_data_s.obj = sig;
  cb_data_s.user_data = (char *)NULL;
  vpi_register_cb(&cb_data_s);
  return 0;
}

static int write_signal(lua_State * L){
  char *s = (char *)luaL_checkstring(L, 1);
  int val = luaL_checknumber(L, 2);
  vpiHandle sig = vpi_handle_by_name(s, NULL);
  static s_vpi_value value_s;
  value_s.format = vpiIntVal;
  value_s.value.integer = val;
  s_vpi_time time_s = {vpiSimTime, 0, 0, 0};
  vpi_put_value(sig, &value_s, &time_s, vpiPureTransportDelay); 
                               //NULL, vpiNoDelay);
  return 0;
}

static int read_signal(lua_State * L){
  const char *s = luaL_checkstring(L, 1);
  vpiHandle sig = vpi_handle_by_name((PLI_BYTE8 *)s, NULL);
  static s_vpi_value value_s = {vpiIntVal}; //{vpiBinStrVal};
  vpi_get_value(sig, &value_s);
  lua_pushnumber(L, value_s.value.integer); //str);
  return 1;
}

static int sim_finish(lua_State * L){
  vpi_control(vpiFinish, 0);
  return 0;
}

static char filename[1024] = "";

PLI_INT32 sys_lua_calltf(PLI_BYTE8* data) {

  if(L == NULL) {
    static s_cb_data cb_data_s = {cbEndOfSimulation, callback};
    vpi_register_cb(&cb_data_s);
    L = lua_open();
    //assert(L);
    luaopen_debug(L);
    luaL_openlibs(L);
    lua_pushcfunction(L, write_signal);
    lua_setglobal(L, "sim_write_signal");
    lua_pushcfunction(L, read_signal);
    lua_setglobal(L, "sim_read_signal");
    lua_pushcfunction(L, bind_signal);
    lua_setglobal(L, "sim_bind_signal");
    lua_pushcfunction(L, sim_finish);
    lua_setglobal(L, "sim_finish");
#ifdef SYS_LUA_LIB
    lua_pushstring(L, SYS_LUA_LIB);
    lua_setglobal(L, "LUA_PATH");
#endif
#ifdef SYS_LUA_CORE_FILE
    if(luaL_dofile(L, SYS_LUA_CORE_FILE) != 0)
#else
    if(luaL_dofile(L, "sl_core.lua") != 0)
#endif
      error(L, "%s", lua_tostring(L, -1));

    lua_getglobal(L, "sl_traceback");
    lua_stack_base = lua_gettop(L);
  };

  vpiHandle systfH = vpi_handle(vpiSysTfCall, NULL);
  vpiHandle argI = vpi_iterate(vpiArgument, systfH);
  vpiHandle argH;

  s_vpi_value val;

  if (argI) {
    argH = vpi_scan(argI);
    while(argH){
      val.format = vpiStringVal;
      vpi_get_value(argH, &val);
      strcpy(filename, val.value.str);
      if(luaL_loadfile(L, filename) != 0)
        error(L, "%s", lua_tostring(L, -1));
      if(lua_pcall(L, 0, 0, lua_stack_base) != 0)
        error(L, "%s", lua_tostring(L, -1));
      argH = vpi_scan(argI);
    }
  }
  return 1;
}

PLI_INT32 sys_lua_checktf(PLI_BYTE8* data){
  return 1;
}

