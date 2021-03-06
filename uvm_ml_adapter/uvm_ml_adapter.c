//----------------------------------------------------------------------
//   Copyright 2012 Cadence Design Systems, Inc.
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//----------------------------------------------------------------------


#include <assert.h>
#include <dlfcn.h> 
#include <stdlib.h>
#include <bp_provided.h>
#include <bp_required.h>
#include <string.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#define PACK_MAX_SIZE 4096/32

static lua_State *L = NULL;

static int lua_stack_base = 0;

#define BP(f) (*bpProvidedAPI->f##_ptr)

static bp_api_struct * bpProvidedAPI = NULL;

static unsigned framework_id = -1;

static uvm_ml_time_unit m_time_unit = TIME_UNIT_UNDEFINED;
static double           m_time_value = -1;

static void set_pack_max_size(int size) {
  BP(set_pack_max_size)(framework_id, size);
}

static int get_pack_max_size() {
  return PACK_MAX_SIZE;
//  return BP(get_pack_max_size)(framework_id);
}

// provided apis
static int uvm_sl_ml_connect(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  const char * port_name = luaL_checkstring(L, 1);
  const char * export_name = luaL_checkstring(L, 2); 
  unsigned res = BP(connect)(framework_id, port_name, export_name);
  lua_pushnumber(L, res);
  return 1;
}

static int uvm_sl_ml_notify_end_blocking(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  unsigned call_id = luaL_checknumber(L, 1);
  unsigned callback_adapter_id = luaL_checknumber(L, 2);
  BP(notify_end_blocking)(framework_id, callback_adapter_id, call_id, m_time_unit, m_time_value);
  return 0;
}

static int uvm_sl_ml_request_put(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  unsigned call_id = luaL_checknumber(L, 2);
  unsigned callback_adapter_id = luaL_checknumber(L, 3);
  int stream_size = luaL_getn(L, 4);
  unsigned stream[get_pack_max_size()];
  memset(stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  //uvm_ml_stream_t stream = (uvm_ml_stream_t)malloc(stream_size*sizeof(uvm_ml_stream_t));
  //assert(stream);
  int i = 1;
  lua_pushnil(L);
  for(; i <= stream_size; i++) {
    lua_next(L, 4);
    stream[i-1] = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
  };
  lua_pop(L, 1);
  unsigned done = 0;
  unsigned disable = BP(request_put)(
    framework_id,
    id,
    call_id,
    stream_size,
    stream,
    &done,
    &m_time_unit,
    &m_time_value
  );
  //free(stream);
  lua_pushboolean(L, disable);
  lua_pushboolean(L, done);
  return 2;
}

static int uvm_sl_ml_nb_put(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  int stream_size = luaL_getn(L, 2);
  unsigned stream[get_pack_max_size()];
  memset(stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  //uvm_ml_stream_t stream = (uvm_ml_stream_t)malloc(stream_size*sizeof(uvm_ml_stream_t));
  //assert(stream);
  int i = 1;
  lua_pushnil(L);
  for(; i <= stream_size; i++) {
    lua_next(L, 2);
    stream[i-1] = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
  };
  lua_pop(L, 1);
  int res = BP(nb_put)(
    framework_id,
    id,
    stream_size,
    stream,
    m_time_unit,
    m_time_value
  );
  lua_pushboolean(L, res);
  return 1;
}

static int uvm_sl_ml_can_put(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  int res = BP(can_put)(framework_id, id, m_time_unit, m_time_value);
  lua_pushboolean(L, res);
  return 1;
}

static int uvm_sl_ml_request_get(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int stream_size = 0;
  unsigned stream[get_pack_max_size()];
  memset(stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  int id = luaL_checknumber(L, 1);
  unsigned call_id = luaL_checknumber(L, 2);
  unsigned callback_adapter_id = luaL_checknumber(L, 3);
  unsigned done = 0;
  int disable = BP(request_get)(
    framework_id,
    id,
    call_id,
    &stream_size,
    stream,
    &done,
    &m_time_unit,
    &m_time_value
  );
  lua_newtable(L);
  int top = lua_gettop(L);
  if (done) {
    int i = 1;
    for(;i <= stream_size; i++) {
      lua_pushnumber(L, i);
      lua_pushnumber(L, stream[i-1]);
      lua_settable(L, top);
    };
  } else {
    lua_pushnumber(L, 1);
    lua_pushnumber(L, 0);
    lua_settable(L, top);
  };
  lua_pushboolean(L, disable);
  lua_pushboolean(L, done);
  return 3;
}

static int uvm_sl_ml_get_requested(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  unsigned call_id = luaL_checknumber(L, 2);
  unsigned callback_adapter_id = luaL_checknumber(L, 3);
  // FIXME: have to use max size of stream, or will result into memory problem
  unsigned stream[get_pack_max_size()];
  memset(stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  //assert(stream);
  unsigned size = BP(get_requested)(
    framework_id,
    id,
    call_id,
    stream
  );
  lua_newtable(L);
  int top = lua_gettop(L);
  int i = 1;
  for(;i <= size; i++) {
    lua_pushnumber(L, i); 
    lua_pushnumber(L, stream[i-1]);
    lua_settable(L, top);
  };
  //free(stream);
  return 1;
}

static int uvm_sl_ml_nb_get(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  int stream_size = 0;
  unsigned stream[get_pack_max_size()];
  memset(stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  int res = BP(nb_get)(
    framework_id,
    id,
    &stream_size,
    stream,
    m_time_unit,
    m_time_value
  );
  lua_newtable(L);
  int top = lua_gettop(L);
  if (res) {
    int i = 1;
    for(;i <= stream_size; i++) {
      lua_pushnumber(L, i);
      lua_pushnumber(L, stream[i-1]);
      lua_settable(L, top);
    };
  } else {
    lua_pushnumber(L, 1);
    lua_pushnumber(L, 0);
    lua_settable(L, top);
  };
  lua_pushboolean(L, res);
  return 2;
}

static int uvm_sl_ml_can_get(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  int res = BP(can_get)(framework_id, id, m_time_unit, m_time_value);
  lua_pushboolean(L, res);
  return 1;
}

static int uvm_sl_ml_request_peek(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int stream_size = 0;
  unsigned stream[get_pack_max_size()];
  memset(stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  int id = luaL_checknumber(L, 1);
  unsigned call_id = luaL_checknumber(L, 2);
  unsigned callback_adapter_id = luaL_checknumber(L, 3);
  unsigned done = 0;
  int disable = BP(request_peek)(
    framework_id,
    id,
    call_id,
    &stream_size,
    stream,
    &done,
    &m_time_unit,
    &m_time_value
  );
  lua_newtable(L);
  int top = lua_gettop(L);
  if (done) {
    int i = 1;
    for(;i <= stream_size; i++) {
      lua_pushnumber(L, i);
      lua_pushnumber(L, stream[i-1]);
      lua_settable(L, top);
    };
  } else {
    lua_pushnumber(L, 1);
    lua_pushnumber(L, 0);
    lua_settable(L, top);
  };
  lua_pushnumber(L, disable);
  lua_pushboolean(L, done);
  return 3;
}

static int uvm_sl_ml_peek_requested(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  unsigned call_id = luaL_checknumber(L, 2);
  unsigned callback_adapter_id = luaL_checknumber(L, 3);
  // FIXME: have to use max size of stream, or will result into memory problem
  unsigned stream[get_pack_max_size()];
  memset(stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  unsigned size = BP(peek_requested)(
    framework_id,
    id,
    call_id,
    stream
  );
  lua_newtable(L);
  int top = lua_gettop(L);
  int i = 1;
  for(;i <= size; i++) {
    lua_pushnumber(L, i);
    lua_pushnumber(L, stream[i-1]);
    lua_settable(L, top);
  };
  //free(stream);
  return 1;
}

static int uvm_sl_ml_nb_peek(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  int stream_size = 0;
  unsigned stream[get_pack_max_size()];
  memset(stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  int res = BP(nb_peek)(
    framework_id,
    id,
    &stream_size,
    stream,
    m_time_unit,
    m_time_value
  );
  lua_newtable(L);
  int top = lua_gettop(L);
  if (res) {
    int i = 1;
    for(;i <= stream_size; i++) {
      lua_pushnumber(L, i);
      lua_pushnumber(L, stream[i-1]);
      lua_settable(L, top);
    };
  } else {
    lua_pushnumber(L, 1);
    lua_pushnumber(L, 0);
    lua_settable(L, top);
  };
  lua_pushboolean(L, res);
  return 2;
}

static int uvm_sl_ml_can_peek(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  int res = BP(can_peek)(framework_id, id, m_time_unit, m_time_value);
  lua_pushboolean(L, res);
  return 1;
}

static int uvm_sl_ml_request_transport(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int rsp_stream_size = 0;
  unsigned rsp_stream[get_pack_max_size()];
  memset(rsp_stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  int id = luaL_checknumber(L, 1);
  unsigned call_id = luaL_checknumber(L, 2);
  unsigned callback_adapter_id = luaL_checknumber(L, 3);
  int req_stream_size = luaL_getn(L, 4);
  unsigned req_stream[get_pack_max_size()];
  memset(req_stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  //uvm_ml_stream_t stream = (uvm_ml_stream_t)malloc(stream_size*sizeof(uvm_ml_stream_t));
  //assert(stream);
  int i = 1;
  lua_pushnil(L);
  for(; i <= req_stream_size; i++) {
    lua_next(L, 4);
    req_stream[i-1] = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
  };
  lua_pop(L, 1);
  unsigned done = 0;
  int disable = BP(request_transport)(
    framework_id,
    id,
    call_id,
    req_stream_size,
    req_stream,
    &rsp_stream_size,
    rsp_stream,
    &done,
    &m_time_unit,
    &m_time_value
  );
  lua_newtable(L);
  int top = lua_gettop(L);
  if (done) {
    int i = 1;
    for(;i <= rsp_stream_size; i++) {
      lua_pushnumber(L, i);
      lua_pushnumber(L, rsp_stream[i-1]);
      lua_settable(L, top);
    };
  } else {
    lua_pushnumber(L, 1);
    lua_pushnumber(L, 0);
    lua_settable(L, top);
  };
  lua_pushnumber(L, disable);
  lua_pushboolean(L, done);
  return 3;
}

static int uvm_sl_ml_transport_response(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  unsigned call_id = luaL_checknumber(L, 2);
  unsigned callback_adapter_id = luaL_checknumber(L, 3);
  // FIXME: have to use max size of stream, or will result into memory problem
  unsigned stream[get_pack_max_size()];
  memset(stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  //assert(stream);
  unsigned size = BP(transport_response)(
    framework_id,
    id,
    call_id,
    stream
  );
  lua_newtable(L);
  int top = lua_gettop(L);
  int i = 1;
  for(;i <= size; i++) {
    lua_pushnumber(L, i);
    lua_pushnumber(L, stream[i-1]);
    lua_settable(L, top);
  };
  //free(stream);
  return 1;
}

static int uvm_sl_ml_nb_transport(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  int req_stream_size = luaL_getn(L, 2);
  unsigned req_stream[get_pack_max_size()];
  memset(req_stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  //uvm_ml_stream_t stream = (uvm_ml_stream_t)malloc(stream_size*sizeof(uvm_ml_stream_t));
  //assert(stream);
  int i = 1;
  lua_pushnil(L);
  for(; i <= req_stream_size; i++) {
    lua_next(L, 2);
    req_stream[i-1] = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
  };
  lua_pop(L, 1);
  int rsp_stream_size = 0;
  unsigned rsp_stream[get_pack_max_size()];
  memset(rsp_stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  int res = BP(nb_transport)(
    framework_id,
    id,
    req_stream_size,
    req_stream,
    &rsp_stream_size,
    rsp_stream,
    m_time_unit,
    m_time_value
  );
  lua_newtable(L);
  int top = lua_gettop(L);
  if (res) {
    int i = 1;
    for(;i <= rsp_stream_size; i++) {
      lua_pushnumber(L, i);
      lua_pushnumber(L, rsp_stream[i-1]);
      lua_settable(L, top);
    };
  } else {
    lua_pushnumber(L, 1);
    lua_pushnumber(L, 0);
    lua_settable(L, top);
  };
  lua_pushboolean(L, res);
  return 2;
}

static int uvm_sl_ml_write(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  int stream_size = luaL_getn(L, 2);
  unsigned stream[get_pack_max_size()];
  memset(stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  int i = 1;
  lua_pushnil(L);
  for(; i <= stream_size; i++) {
    lua_next(L, 2);
    stream[i-1] = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
  };
  lua_pop(L, 1);
  BP(write)(
    framework_id,
    id,
    stream_size,
    stream,
    m_time_unit,
    m_time_value
  );
  return 0;
}

static int uvm_sl_ml_tlm2_request_b_transport(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  unsigned call_id = luaL_checknumber(L, 2);
  unsigned callback_adapter_id = luaL_checknumber(L, 3);
  int stream_size = luaL_getn(L, 4);
  unsigned* stream = (unsigned*)malloc(sizeof(unsigned[get_pack_max_size()]));
  assert(stream);
  unsigned* old_ptr = stream;
  memset(stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  double delay = luaL_checknumber(L, 5);
  int i = 1;
  lua_pushnil(L);
  for(; i <= stream_size; i++) {
    lua_next(L, 4);
    stream[i-1] = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
  };
  lua_pop(L, 1);
  unsigned done = 0;
  int disable = BP(request_b_transport_tlm2)(
    framework_id,
    id,
    call_id,
    &stream_size,
    &stream,
    m_time_unit,
    delay,
    &done,
    m_time_unit,
    m_time_value
  );
  if (old_ptr != stream) free(old_ptr);
  lua_newtable(L);
  int top = lua_gettop(L);
  if (done) {
    int i = 1;
    for(;i <= stream_size; i++) {
      lua_pushnumber(L, i);
      lua_pushnumber(L, stream[i-1]);
      lua_settable(L, top);
    };
  } else {
    lua_pushnumber(L, 1);
    lua_pushnumber(L, 0);
    lua_settable(L, top);
  };
  lua_pushnumber(L, delay);
  lua_pushnumber(L, disable);
  lua_pushboolean(L, done);
  free(stream);
  return 4;
}

static int uvm_sl_ml_tlm2_b_transport_response(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  unsigned call_id = luaL_checknumber(L, 2);
  unsigned callback_adapter_id = luaL_checknumber(L, 3);
  int stream_size = get_pack_max_size();
  unsigned stream[get_pack_max_size()];
  memset(stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  BP(b_transport_tlm2_response)(
    framework_id,
    id,
    call_id,
    &stream_size,
    stream
  );
  lua_newtable(L);
  int top = lua_gettop(L);
  int i = 1;
  for(;i <= stream_size; i++) {
    lua_pushnumber(L, i);
    lua_pushnumber(L, stream[i-1]);
    lua_settable(L, top);
  };
  // FIXME no delay return????
  lua_pushnumber(L, 0);
  //free(stream);
  return 2;
}

static int uvm_sl_ml_tlm2_nb_transport_fw(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  int trans_id = luaL_checknumber(L, 2);
  int stream_size = luaL_getn(L, 3);
  uvm_ml_tlm_phase phase = (uvm_ml_tlm_phase)luaL_checknumber(L, 4);
  double delay = luaL_checknumber(L, 5);
  unsigned *stream = (unsigned *)malloc(sizeof(unsigned[get_pack_max_size()]));
  assert(stream);
  unsigned *old_ptr = stream;
  memset(stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  int i = 1;
  lua_pushnil(L);
  for(; i <= stream_size; i++) {
    lua_next(L, 3);
    stream[i-1] = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
  };
  lua_pop(L, 1);
  uvm_ml_tlm_sync_enum res = BP(nb_transport_fw)(
    framework_id,
    id,
    &stream_size,
    &stream,
    &phase,
    trans_id,
    &m_time_unit,
    &delay,
    m_time_unit,
    m_time_value
  );
  if(old_ptr != stream) free(old_ptr);
  lua_newtable(L);
  int top = lua_gettop(L);
  i = 1;
  for(;i <= stream_size; i++) {
    lua_pushnumber(L, i);
    lua_pushnumber(L, stream[i-1]);
    lua_settable(L, top);
  };
  lua_pushnumber(L, (int)phase);
  lua_pushnumber(L, delay);
  lua_pushnumber(L, res);
  free(stream);
  return 4;
}

static int uvm_sl_ml_tlm2_nb_transport_bw(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  int trans_id = luaL_checknumber(L, 2);
  int stream_size = luaL_getn(L, 3);
  uvm_ml_tlm_phase phase = (uvm_ml_tlm_phase)luaL_checknumber(L, 4);
  double delay = luaL_checknumber(L, 5);
  unsigned *stream = (unsigned *)malloc(sizeof(unsigned[get_pack_max_size()]));
  assert(stream);
  unsigned *old_ptr = stream;
  memset(stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  int i = 1;
  lua_pushnil(L);
  for(; i <= stream_size; i++) {
    lua_next(L, 3);
    stream[i-1] = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
  };
  lua_pop(L, 1);
  uvm_ml_tlm_sync_enum res = BP(nb_transport_bw)(
    framework_id,
    id,
    &stream_size,
    &stream,
    &phase,
    trans_id,
    &m_time_unit,
    &delay,
    m_time_unit,
    m_time_value
  );
  if(old_ptr != stream) free(old_ptr);
  lua_newtable(L);
  int top = lua_gettop(L);
  i = 1;
  for(;i <= stream_size; i++) {
    lua_pushnumber(L, i);
    lua_pushnumber(L, stream[i-1]);
    lua_settable(L, top);
  };
  lua_pushnumber(L, (int)phase);
  lua_pushnumber(L, delay);
  lua_pushnumber(L, res);
  free(stream);
  return 4;
}

static int uvm_sl_ml_tlm2_transport_dbg(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  int stream_size = luaL_getn(L, 2);
  unsigned *stream = (unsigned *)malloc(sizeof(unsigned[get_pack_max_size()]));
  assert(stream);
  unsigned *old_ptr = stream;
  memset(stream, '\0', sizeof(unsigned[get_pack_max_size()]));
  int i = 1;
  lua_pushnil(L);
  for(; i <= stream_size; i++) {
    lua_next(L, 2);
    stream[i-1] = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
  };
  lua_pop(L, 1);
  BP(transport_dbg)(
    framework_id,
    id,
    &stream_size,
    &stream,
    m_time_unit,
    m_time_value
  );
  if (old_ptr != stream) free(old_ptr);
  free(stream);
  return 0;
}

static int uvm_sl_ml_get_type_id(lua_State * L) {
  const char * name = luaL_checkstring(L, 1);
  unsigned id = BP(get_type_id_from_name)(framework_id, name);
  lua_pushnumber(L, id);
  return 1;
}

static int uvm_sl_ml_get_type_name(lua_State * L) {
  unsigned id = luaL_checknumber(L, 1);
  char * name = BP(get_type_name_from_id)(framework_id, id);
  lua_pushstring(L, name);
  return 1;
}

static int uvm_sl_ml_create_component_proxy(lua_State * L) {
  const char * frwind = luaL_checkstring(L, 1);
  const char * klass = luaL_checkstring(L, 2);
  const char * name = luaL_checkstring(L, 3);
  const char * parent_name = luaL_checkstring(L, 4);
  unsigned parent_id = luaL_checknumber(L, 5);
  unsigned child_junction_node_id = BP(create_child_junction_node)(
                                       framework_id,
                                       frwind,
                                       klass,
                                       name,
                                       parent_name,
                                       parent_id);
  lua_pushnumber(L, child_junction_node_id);
  return 1;
}

static int uvm_sl_ml_notify_tree_phase(lua_State * L) {
  const char * frwind = luaL_checkstring(L, 1);
  unsigned child_id = luaL_checknumber(L, 2);
  const char * group = luaL_checkstring(L, 3);
  const char * phase = luaL_checkstring(L, 4);
  int res = BP(notify_tree_phase)(framework_id, frwind, child_id, group, phase);
  return 0;
}

static int uvm_sl_ml_assign_transaction_id (lua_State * L) {
  int id = BP(assign_transaction_id)(framework_id);
  lua_pushnumber(L, id);
  return 1;
}

static int uvm_sl_ml_set_trace_mode(lua_State * L) {
  int mode = luaL_checknumber(L, 1);
  BP(set_trace_mode)(mode);
  return 0;
}

static int uvm_sl_ml_set_match_types(lua_State * L) {
  const char * type1 = luaL_checkstring(L, 1);
  const char * type2 = luaL_checkstring(L, 2);
  int res = BP(set_match_types)(framework_id, type1, type2);
  lua_pushnumber(L, res);
  return 1;
}

static int uvm_sl_ml_set_pack_max_size(lua_State * L) {
  int size = luaL_checknumber(L, 1);
  set_pack_max_size(size);
  return 0;
}

static int uvm_sl_ml_get_pack_max_size(lua_State * L) {
  int res = get_pack_max_size();
  lua_pushnumber(L, res);
  return 1;
}

// required apis

static void set_debug_mode(int mode) {
}

static void startup() {
  L = lua_open();
  luaopen_debug(L);
  luaL_openlibs(L);

  lua_pushcfunction(L, uvm_sl_ml_connect);
  lua_setglobal(L, "uvm_sl_ml_connect");

  lua_pushcfunction(L, uvm_sl_ml_notify_end_blocking);
  lua_setglobal(L, "uvm_sl_ml_notify_end_blocking");

  lua_pushcfunction(L, uvm_sl_ml_request_put);
  lua_setglobal(L, "uvm_sl_ml_request_put");

  lua_pushcfunction(L, uvm_sl_ml_can_put);
  lua_setglobal(L, "uvm_sl_ml_can_put");

  lua_pushcfunction(L, uvm_sl_ml_nb_put);
  lua_setglobal(L, "uvm_sl_ml_nb_put");

  lua_pushcfunction(L, uvm_sl_ml_request_get);
  lua_setglobal(L, "uvm_sl_ml_request_get");

  lua_pushcfunction(L, uvm_sl_ml_get_requested);
  lua_setglobal(L, "uvm_sl_ml_get_requested");

  lua_pushcfunction(L, uvm_sl_ml_can_get);
  lua_setglobal(L, "uvm_sl_ml_can_get");

  lua_pushcfunction(L, uvm_sl_ml_nb_get);
  lua_setglobal(L, "uvm_sl_ml_nb_get");

  lua_pushcfunction(L, uvm_sl_ml_request_peek);
  lua_setglobal(L, "uvm_sl_ml_request_peek");

  lua_pushcfunction(L, uvm_sl_ml_peek_requested);
  lua_setglobal(L, "uvm_sl_ml_peek_requested");

  lua_pushcfunction(L, uvm_sl_ml_can_peek);
  lua_setglobal(L, "uvm_sl_ml_can_peek");

  lua_pushcfunction(L, uvm_sl_ml_nb_peek);
  lua_setglobal(L, "uvm_sl_ml_nb_peek");

  lua_pushcfunction(L, uvm_sl_ml_request_transport);
  lua_setglobal(L, "uvm_sl_ml_request_transport");

  lua_pushcfunction(L, uvm_sl_ml_transport_response);
  lua_setglobal(L, "uvm_sl_ml_transport_response");

  lua_pushcfunction(L, uvm_sl_ml_nb_transport);
  lua_setglobal(L, "uvm_sl_ml_nb_transport");

  lua_pushcfunction(L, uvm_sl_ml_write);
  lua_setglobal(L, "uvm_sl_ml_write");

  lua_pushcfunction(L, uvm_sl_ml_tlm2_request_b_transport);
  lua_setglobal(L, "uvm_sl_ml_tlm2_request_b_transport");

  lua_pushcfunction(L, uvm_sl_ml_tlm2_b_transport_response);
  lua_setglobal(L, "uvm_sl_ml_tlm2_b_transport_response");

  lua_pushcfunction(L, uvm_sl_ml_tlm2_nb_transport_fw);
  lua_setglobal(L, "uvm_sl_ml_tlm2_nb_transport_fw");

  lua_pushcfunction(L, uvm_sl_ml_tlm2_nb_transport_bw);
  lua_setglobal(L, "uvm_sl_ml_tlm2_nb_transport_bw");

  lua_pushcfunction(L, uvm_sl_ml_tlm2_transport_dbg);
  lua_setglobal(L, "uvm_sl_ml_tlm2_transport_dbg");

  lua_pushcfunction(L, uvm_sl_ml_get_type_id);
  lua_setglobal(L, "uvm_sl_ml_get_type_id");

  lua_pushcfunction(L, uvm_sl_ml_get_type_name);
  lua_setglobal(L, "uvm_sl_ml_get_type_name");

  lua_pushcfunction(L, uvm_sl_ml_create_component_proxy);
  lua_setglobal(L, "uvm_sl_ml_create_component_proxy");

  lua_pushcfunction(L, uvm_sl_ml_notify_tree_phase);
  lua_setglobal(L, "uvm_sl_ml_notify_tree_phase");

  lua_pushcfunction(L, uvm_sl_ml_assign_transaction_id);
  lua_setglobal(L, "uvm_sl_ml_assign_transaction_id");

  lua_pushcfunction(L, uvm_sl_ml_set_trace_mode);
  lua_setglobal(L, "uvm_sl_ml_set_trace_mode");

  lua_pushcfunction(L, uvm_sl_ml_set_match_types);
  lua_setglobal(L, "uvm_sl_ml_set_match_types");

  lua_pushcfunction(L, uvm_sl_ml_set_pack_max_size);
  lua_setglobal(L, "uvm_sl_ml_set_pack_max_size");

  lua_pushcfunction(L, uvm_sl_ml_get_pack_max_size);
  lua_setglobal(L, "uvm_sl_ml_get_pack_max_size");

#ifdef SYS_LUA_CORE_FILE
  if(luaL_dofile(L, SYS_LUA_CORE_FILE) != 0)
#else
  if(luaL_dofile(L, "sl_core.lua") != 0)
#endif
    error(L, "%s", lua_tostring(L, -1));

  lua_getglobal(L, "sl_traceback");
  lua_stack_base = lua_gettop(L);

  //set_pack_max_size(PACK_MAX_SIZE);
}

static int construct_top(const char* filename, const char * instance_name){
  lua_getglobal(L, "require");
  lua_pushstring(L, filename);
  if (lua_pcall(L, 1, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));

  lua_getglobal(L, "find_component_by_full_name");
  lua_pushstring(L, instance_name);

  if (lua_pcall(L, 1, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));

  lua_getfield(L, -1, "id");
  int id = luaL_checkinteger(L, -1);
  lua_pop(L, 2);
  return id; 
}

static int notify_phase(const char * phase_group,
                        const char * phase_name,
                        unsigned int phase_action) {
  lua_getglobal(L, "notify_phase");
  lua_pushstring(L, phase_group);
  lua_pushstring(L, phase_name);
  lua_pushnumber(L, phase_action);
  if (lua_pcall(L, 3, 0, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  return 1;
}

static int notify_tree_phase(int          target_id,
                             const char * phase_group,
                             const char * phase_name) {
  lua_getglobal(L, "notify_phase_by_id");
  lua_pushnumber(L, target_id);
  lua_pushstring(L, phase_group);
  lua_pushstring(L, phase_name);
  lua_pushnumber(L, 0);
  if (lua_pcall(L, 4, 0, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  return 1;
}

static int notify_runtime_phase(const char *     phase_group,
                                const char *     phase_name,
                                unsigned int     phase_action,
                                uvm_ml_time_unit time_unit,
                                double           time_value,
                                unsigned int *   participate) {
  lua_getglobal(L, "notify_runtime_phase");
  lua_pushstring(L, phase_group);
  lua_pushstring(L, phase_name);
  lua_pushnumber(L, phase_action);
  if (lua_pcall(L, 3, 0, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  return 1;
}

static int find_connector_id_by_name(const char * path) {
  lua_getglobal(L, "find_port_by_full_name");
  lua_pushstring(L, path);
  if (lua_pcall(L, 1, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  lua_getfield(L, -1, "id");
  int id = luaL_checkinteger(L, -1);
  lua_pop(L, 2);
  return id;
}

static const char* get_connector_intf_name(unsigned connector_id) {
  lua_getglobal(L, "find_port_by_id");
  lua_pushnumber(L, connector_id);
  if (lua_pcall(L, 1, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  lua_getfield(L, -1, "type");
  const char * intf_name = luaL_checkstring(L, -1);
  lua_pop(L, 2);
  return intf_name;
}

static unsigned is_export_connector(unsigned connector_id) {
  lua_getglobal(L, "find_port_by_id");
  lua_pushnumber(L, connector_id);
  if (lua_pcall(L, 1, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  lua_getfield(L, -1, "is_export");
  int is_export = lua_toboolean(L, -1);
  lua_pop(L, 2);
  return is_export;
}

static int request_put(
  unsigned connector_id,
  unsigned call_id,
  unsigned callback_adapter_id,
  unsigned stream_size,
  uvm_ml_stream_t stream,
  uvm_ml_time_unit time_unit,
  double           time_value
  ) {
  lua_getglobal(L, "uvm_sl_ml_request_put_callback");
  lua_pushnumber(L, connector_id);
  lua_pushnumber(L, call_id);
  lua_pushnumber(L, callback_adapter_id);
  lua_newtable(L);
  int top = lua_gettop(L);
  int i = 1;
  for(; i <= stream_size; i++) {
    lua_pushnumber(L, i);
    lua_pushnumber(L, stream[i-1]);
    lua_settable(L, top);
  };
  if (lua_pcall(L, 4, 0, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  return 0;
}

static int can_put(
  unsigned connector_id,
  uvm_ml_time_unit time_unit,
  double           time_value
) {
  lua_getglobal(L, "uvm_sl_ml_can_put_callback");
  lua_pushnumber(L, connector_id);
  if (lua_pcall(L, 1, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  int res = lua_toboolean(L, -1);
  lua_pop(L, 1);
  return res;
}

static int nb_put(
  unsigned connector_id,
  unsigned stream_size ,
  uvm_ml_stream_t stream,
  uvm_ml_time_unit time_unit,
  double           time_value
) {
  lua_getglobal(L, "uvm_sl_ml_nb_put_callback");
  lua_pushnumber(L, connector_id);
  lua_newtable(L);
  int top = lua_gettop(L);
  int i = 1;
  for(; i <= stream_size; i++) {
    lua_pushnumber(L, i);
    lua_pushnumber(L, stream[i-1]);
    lua_settable(L, top);
  };
  if (lua_pcall(L, 2, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  int res = lua_toboolean(L, -1);
  lua_pop(L, 1);
  return res;
}

static int request_get(
  unsigned connector_id,
  unsigned call_id,
  unsigned callback_adapter_id,
  uvm_ml_time_unit time_unit,
  double           time_value
) {
  lua_getglobal(L, "uvm_sl_ml_request_get_callback");
  lua_pushnumber(L, connector_id);
  lua_pushnumber(L, call_id);
  lua_pushnumber(L, callback_adapter_id);
  if (lua_pcall(L, 3, 0, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1)); 
  return 0;
}

static unsigned get_requested(
    unsigned connector_id,
    unsigned call_id,
    uvm_ml_stream_t stream
) {
  lua_getglobal(L, "uvm_sl_ml_get_requested_callback");
  lua_pushnumber(L, connector_id);
  lua_pushnumber(L, call_id);
  lua_pushnumber(L, call_id);
  if (lua_pcall(L, 3, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  int stream_size = luaL_getn(L, -1);
  int i = 1;
  lua_pushnil(L);
  for(; i <= stream_size; i++) {
    lua_next(L, -2);
    stream[i-1] = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
  };
  lua_pop(L, 2);
  return stream_size;
}

static int can_get(
  unsigned connector_id,
  uvm_ml_time_unit time_unit,
  double           time_value
) {
  lua_getglobal(L, "uvm_sl_ml_can_get_callback");
  lua_pushnumber(L, connector_id);
  if (lua_pcall(L, 1, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  int res = lua_toboolean(L, -1);
  lua_pop(L, 1);
  return res;
}

static int nb_get(
  unsigned connector_id,
  unsigned * stream_size_ptr,
  uvm_ml_stream_t stream,
  uvm_ml_time_unit time_unit,
  double           time_value
) {
  lua_getglobal(L, "uvm_sl_ml_nb_get_callback");
  lua_pushnumber(L, connector_id);
  if (lua_pcall(L, 1, 2, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  int res = lua_toboolean(L, -1);
  lua_pop(L, 1);
  int stream_size = luaL_getn(L, -1);
  *stream_size_ptr = stream_size;
  int i = 1;
  lua_pushnil(L);
  for(; i <= stream_size; i++) {
    lua_next(L, -2);
    stream[i-1] = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
  };
  lua_pop(L, 2);
  return res;
}

static int request_peek(
  unsigned connector_id,
  unsigned call_id,
  unsigned callback_adapter_id,
  uvm_ml_time_unit time_unit,
  double           time_value
) {
  lua_getglobal(L, "uvm_sl_ml_request_peek_callback");
  lua_pushnumber(L, connector_id);
  lua_pushnumber(L, call_id);
  lua_pushnumber(L, callback_adapter_id);
  if (lua_pcall(L, 3, 0, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  return 0;
}

static unsigned peek_requested(
    unsigned connector_id,
    unsigned call_id,
    uvm_ml_stream_t stream
) {
  lua_getglobal(L, "uvm_sl_ml_peek_requested_callback");
  lua_pushnumber(L, connector_id);
  lua_pushnumber(L, call_id);
  lua_pushnumber(L, call_id);
  if (lua_pcall(L, 3, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  int stream_size = luaL_getn(L, -1);
  int i = 1;
  lua_pushnil(L);
  for(; i <= stream_size; i++) {
    lua_next(L, -2);
    stream[i-1] = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
  };
  lua_pop(L, 2);
  return stream_size;
}

static int can_peek(
  unsigned connector_id,
  uvm_ml_time_unit time_unit,
  double           time_value
) {
  lua_getglobal(L, "uvm_sl_ml_can_peek_callback");
  lua_pushnumber(L, connector_id);
  if (lua_pcall(L, 1, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  int res = lua_toboolean(L, -1);
  lua_pop(L, 1);
  return res;
}

static int nb_peek(
  unsigned connector_id,
  unsigned * stream_size_ptr,
  uvm_ml_stream_t stream,
  uvm_ml_time_unit time_unit,
  double           time_value
) {
  lua_getglobal(L, "uvm_sl_ml_nb_peek_callback");
  lua_pushnumber(L, connector_id);
  if (lua_pcall(L, 1, 2, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  int res = lua_toboolean(L, -1);
  lua_pop(L, 1);
  int stream_size = luaL_getn(L, -1);
  *stream_size_ptr = stream_size;
  int i = 1;
  lua_pushnil(L);
  for(; i <= stream_size; i++) {
    lua_next(L, -2);
    stream[i-1] = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
  };
  lua_pop(L, 2);
  return res;
}

static int request_transport(
  unsigned connector_id,
  unsigned call_id,
  unsigned callback_adapter_id,
  unsigned req_stream_size,
  uvm_ml_stream_t req_stream,
  unsigned* rsp_stream_size,
  uvm_ml_stream_t rsp_stream,
  uvm_ml_time_unit time_unit,
  double           time_value
  ) {
  lua_getglobal(L, "uvm_sl_ml_request_transport_callback");
  lua_pushnumber(L, connector_id);
  lua_pushnumber(L, call_id);
  lua_pushnumber(L, callback_adapter_id);
  lua_newtable(L);
  int top = lua_gettop(L);
  int i = 1;
  for(; i <= req_stream_size; i++) {
    lua_pushnumber(L, i);
    lua_pushnumber(L, req_stream[i-1]);
    lua_settable(L, top);
  };
  if (lua_pcall(L, 4, 0, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  return 0;
}

static unsigned transport_response(
    unsigned connector_id,
    unsigned call_id,
    uvm_ml_stream_t stream
) {
  lua_getglobal(L, "uvm_sl_ml_transport_response_callback");
  lua_pushnumber(L, connector_id);
  lua_pushnumber(L, call_id);
  lua_pushnumber(L, call_id);
  if (lua_pcall(L, 3, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  int stream_size = luaL_getn(L, -1);
  int i = 1;
  lua_pushnil(L);
  for(; i <= stream_size; i++) {
    lua_next(L, -2);
    stream[i-1] = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
  };
  lua_pop(L, 2);
  return stream_size;
}

static int nb_transport(
  unsigned connector_id,
  unsigned req_stream_size,
  uvm_ml_stream_t req_stream,
  unsigned* rsp_stream_size_ptr,
  uvm_ml_stream_t rsp_stream,
  uvm_ml_time_unit time_unit,
  double           time_value
) {
  lua_getglobal(L, "uvm_sl_ml_nb_transport_callback");
  lua_pushnumber(L, connector_id);
  lua_newtable(L);
  int top = lua_gettop(L);
  int i = 1;
  for(; i <= req_stream_size; i++) {
    lua_pushnumber(L, i);
    lua_pushnumber(L, req_stream[i-1]);
    lua_settable(L, top);
  };
  if (lua_pcall(L, 2, 2, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  int res = lua_toboolean(L, -1);
  lua_pop(L, 1);
  int stream_size = luaL_getn(L, -1);
  *rsp_stream_size_ptr = stream_size;
  i = 1;
  lua_pushnil(L);
  for(; i <= stream_size; i++) {
    lua_next(L, -2);
    rsp_stream[i-1] = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
  };
  lua_pop(L, 2);
  return res;
}

static void write(
  unsigned connector_id,
  unsigned stream_size ,
  uvm_ml_stream_t stream,
  uvm_ml_time_unit time_unit,
  double           time_value
) {
  lua_getglobal(L, "uvm_sl_ml_write_callback");
  lua_pushnumber(L, connector_id);
  lua_newtable(L);
  int top = lua_gettop(L);
  int i = 1;
  for(; i <= stream_size; i++) {
    lua_pushnumber(L, i);
    lua_pushnumber(L, stream[i-1]);
    lua_settable(L, top);
  };
  if (lua_pcall(L, 2, 0, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
}

static int tlm2_request_b_transport(
  unsigned connector_id,
  unsigned call_id,
  unsigned callback_adapter_id,
  unsigned stream_size,
  uvm_ml_stream_t stream,
  uvm_ml_time_unit      delay_unit,
  double                delay_value,
  uvm_ml_time_unit time_unit,
  double           time_value
  ) {
  lua_getglobal(L, "uvm_sl_ml_tlm2_request_b_transport_callback");
  lua_pushnumber(L, connector_id);
  lua_pushnumber(L, call_id);
  lua_pushnumber(L, callback_adapter_id);
  lua_newtable(L);
  int top = lua_gettop(L);
  int i = 1;
  for(; i <= stream_size; i++) {
    lua_pushnumber(L, i);
    lua_pushnumber(L, stream[i-1]);
    lua_settable(L, top);
  };
  lua_pushnumber(L, delay_value);
  if (lua_pcall(L, 5, 0, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  return 0;
}

static int tlm2_b_transport_response(
    unsigned connector_id,
    unsigned call_id,
    unsigned * stream_size,
    uvm_ml_stream_t * stream
) {
  lua_getglobal(L, "uvm_sl_ml_tlm2_b_transport_response_callback");
  lua_pushnumber(L, connector_id);
  lua_pushnumber(L, call_id);
  lua_pushnumber(L, call_id);
  if (lua_pcall(L, 3, 2, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  int delay = luaL_checknumber(L, -1);
  lua_pop(L, 1);
  *stream_size = luaL_getn(L, -1);
  int i = 1;
  lua_pushnil(L);
  for(; i <= *stream_size; i++) {
    lua_next(L, -2);
    (*stream)[i-1] = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
  };
  lua_pop(L, 2);
  return *stream_size;
}

static uvm_ml_tlm_sync_enum tlm2_nb_transport_fw(
    unsigned              connector_id,
    unsigned *            stream_size,
    uvm_ml_stream_t * stream,
    uvm_ml_tlm_phase *   phase,
    unsigned int          transaction_id,
    uvm_ml_time_unit *   delay_unit,
    double *              delay_value,
    uvm_ml_time_unit      time_unit,
    double                time_value
) {
  lua_getglobal(L, "uvm_sl_ml_tlm2_nb_transport_fw_callback");
  lua_pushnumber(L, connector_id);
  lua_pushnumber(L, transaction_id);
  lua_newtable(L);
  int top = lua_gettop(L);
  int i = 1;
  for(; i <= *stream_size; i++) {
    lua_pushnumber(L, i);
    lua_pushnumber(L, (*stream)[i-1]);
    lua_settable(L, top);
  };
  lua_pushnumber(L, (int)(*phase));
  lua_pushnumber(L, *delay_value);
  if (lua_pcall(L, 5, 4, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  int res = luaL_checknumber(L, -1);
  lua_pop(L, 1);
  double delay = luaL_checknumber(L, -1);
  *delay_value = delay;
  lua_pop(L, 1);
  uvm_ml_tlm_phase _phase = (uvm_ml_tlm_phase)luaL_checknumber(L, -1);
  *phase = _phase;
  lua_pop(L, 1);
  *stream_size = luaL_getn(L, -1);
  i = 1;
  lua_pushnil(L);
  for(; i <= *stream_size; i++) {
    lua_next(L, -2);
    (*stream)[i-1] = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
  };
  lua_pop(L, 2);
  return res;
}

static uvm_ml_tlm_sync_enum tlm2_nb_transport_bw(
    unsigned              connector_id,
    unsigned *            stream_size,
    uvm_ml_stream_t * stream,
    uvm_ml_tlm_phase *   phase,
    unsigned int          transaction_id,
    uvm_ml_time_unit *   delay_unit,
    double *              delay_value,
    uvm_ml_time_unit      time_unit,
    double                time_value
) {
  lua_getglobal(L, "uvm_sl_ml_tlm2_nb_transport_bw_callback");
  lua_pushnumber(L, connector_id);
  lua_pushnumber(L, transaction_id);
  lua_newtable(L);
  int top = lua_gettop(L);
  int i = 1;
  for(; i <= *stream_size; i++) {
    lua_pushnumber(L, i);
    lua_pushnumber(L, (*stream)[i-1]);
    lua_settable(L, top);
  };
  lua_pushnumber(L, (int)(*phase));
  lua_pushnumber(L, *delay_value);
  if (lua_pcall(L, 5, 4, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  int res = luaL_checknumber(L, -1);
  lua_pop(L, 1);
  double delay = luaL_checknumber(L, -1);
  *delay_value = delay;
  lua_pop(L, 1);
  uvm_ml_tlm_phase _phase = (uvm_ml_tlm_phase)luaL_checknumber(L, -1);
  *phase = _phase;
  lua_pop(L, 1);
  *stream_size = luaL_getn(L, -1);
  i = 1;
  lua_pushnil(L);
  for(; i <= *stream_size; i++) {
    lua_next(L, -2);
    (*stream)[i-1] = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
  };
  lua_pop(L, 2);
  return res;
}

static unsigned tlm2_transport_dbg(
    unsigned              connector_id,
    unsigned *            stream_size,
    uvm_ml_stream_t * stream,
    uvm_ml_time_unit      time_unit,
    double                time_value
) {
  lua_getglobal(L, "uvm_sl_ml_tlm2_transport_dbg_callback");
  lua_pushnumber(L, connector_id);
  lua_newtable(L);
  int top = lua_gettop(L);
  int i = 1;
  for(; i <= *stream_size; i++) {
    lua_pushnumber(L, i);
    lua_pushnumber(L, (*stream)[i-1]);
    lua_settable(L, top);
  };
  if (lua_pcall(L, 2, 0, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  return 0;

}

static void notify_end_blocking(
  unsigned call_id,
  uvm_ml_time_unit time_unit,
  double           time_value
) {
  lua_getglobal(L, "uvm_sl_ml_notify_end_blocking_callback");
  lua_pushnumber(L, call_id);
  lua_pushnumber(L, call_id); 
  if (lua_pcall(L, 2, 0, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1)); 
}

static void synchronize(
    uvm_ml_time_unit      time_unit,
    double                time_value
    ) {
  static double current_time = 0;
  lua_getglobal(L, "run");
  lua_pushnil(L);
  lua_pushnumber(L, time_value - current_time);
  current_time = time_value;

  if (lua_pcall(L, 2, 0, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
}

static int create_child_junction_node(
    const char * component_type_name,
    const char * instance_name,
    const char * parent_full_name,
    int          parent_framework_id,
    int          parent_junction_node_id
  ) {
  lua_getglobal(L, "uvm_sl_ml_create_component");
  lua_pushstring(L, component_type_name);
  lua_pushstring(L, instance_name);
  lua_pushstring(L, parent_full_name);
  lua_pushnumber(L, parent_framework_id);
  lua_pushnumber(L, parent_junction_node_id);
  if (lua_pcall(L, 5, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  lua_getfield(L, -1, "id");
  int id = luaL_checkinteger(L, -1);
  lua_pop(L, 2);
  return id;
}

static bp_frmw_c_api_struct* uvm_ml_sl_get_required_api() {
  bp_frmw_c_api_struct * required_api = (bp_frmw_c_api_struct*) malloc(sizeof(bp_frmw_c_api_struct));
  assert(required_api);
  memset(required_api, '\0', sizeof(bp_frmw_c_api_struct));
  required_api->set_trace_mode_ptr = set_debug_mode;
  required_api->startup_ptr = startup;
  required_api->construct_top_ptr = construct_top;
  required_api->notify_phase_ptr = notify_phase;
  required_api->notify_tree_phase_ptr = notify_tree_phase;
  required_api->notify_runtime_phase_ptr = notify_runtime_phase;
  required_api->find_connector_id_by_name_ptr = find_connector_id_by_name;
  required_api->get_connector_intf_name_ptr = get_connector_intf_name;
  required_api->is_export_connector_ptr = is_export_connector;
  required_api->try_put_uvm_ml_stream_ptr = nb_put;
  required_api->can_put_ptr = can_put;
  required_api->put_uvm_ml_stream_request_ptr = request_put;
  required_api->get_uvm_ml_stream_request_ptr = request_get;
  required_api->get_requested_uvm_ml_stream_ptr = get_requested;
  required_api->try_get_uvm_ml_stream_ptr = nb_get;
  required_api->can_get_ptr = can_get;
  required_api->peek_uvm_ml_stream_request_ptr = request_peek;
  required_api->peek_requested_uvm_ml_stream_ptr = peek_requested;
  required_api->try_peek_uvm_ml_stream_ptr = nb_peek;
  required_api->can_peek_ptr = can_peek;
  required_api->transport_uvm_ml_stream_request_ptr = request_transport;
  required_api->transport_response_uvm_ml_stream_ptr = transport_response;
  required_api->nb_transport_uvm_ml_stream_ptr = nb_transport;
  required_api->write_uvm_ml_stream_ptr = write;
  required_api->notify_end_blocking_ptr = notify_end_blocking;
  required_api->tlm2_b_transport_request_ptr = tlm2_request_b_transport;
  required_api->tlm2_b_transport_response_ptr = tlm2_b_transport_response;
  required_api->tlm2_nb_transport_fw_ptr = tlm2_nb_transport_fw;
  required_api->tlm2_nb_transport_bw_ptr = tlm2_nb_transport_bw;
  required_api->tlm2_transport_dbg_ptr = tlm2_transport_dbg;
  //required_api->tlm2_turn_off_transaction_mapping_ptr = (uvm_ml_tlm_rec::tlm2_turn_off_transaction_mapping);
  required_api->synchronize_ptr = synchronize;

  required_api->create_child_junction_node_ptr = create_child_junction_node;
  return required_api;
}

static void * backplane_handle = NULL;

static const char* backplane_get_provided_tray = "bp_get_provided_tray";

static void backplane_open()
{
  // The backplane library may be compiled in or preloaded
  // So, start with the 'global' namespace
  backplane_handle = dlopen(0, RTLD_LAZY);
  if(backplane_handle != 0) {
    if(dlsym(backplane_handle, backplane_get_provided_tray) != 0) {
      return;
    };
  };
  const char* const backplane_lib_name = "libml_uvm.so";
  char * lib_location = getenv("UVM_ML_OVERRIDE");
  if(lib_location == NULL) {
    lib_location = getenv("UNILANG_OVERRIDE");
  }
  if(lib_location) {
    char lib_file[1024*4];
    strcpy(lib_file, lib_location);
    strcat(lib_file, "/");
    strcat(lib_file, backplane_lib_name);
    backplane_handle = dlopen(lib_file, RTLD_LAZY | RTLD_GLOBAL);
  } else {
    backplane_handle = dlopen(backplane_lib_name, RTLD_LAZY | RTLD_GLOBAL);
  }
  if (backplane_handle == NULL) {
      char * err_msg = dlerror();

      // FIXME - use proper error messaging and proper per-simulator graceful shutdown mechanism here

      fprintf(stderr, "Failed to open the backplane library %s for the following reason: %s\n",
        backplane_lib_name, err_msg);
      exit(0);
  }

}


__attribute__((constructor)) static void initialize_adapter() {
  backplane_open();
  assert(backplane_handle != NULL);
  bp_api_struct* (*bp_get_provided_tray_ptr)() = (bp_api_struct* (*)())dlsym(backplane_handle, backplane_get_provided_tray);
  bpProvidedAPI = (bp_get_provided_tray_ptr)();
  assert(bpProvidedAPI != NULL);
  char *frmw_ids[3] = {(char*)"UVMSL", (char*)"SL",(char*)""};
  framework_id = BP(register_framework)((char*)"SystemLua",frmw_ids, uvm_ml_sl_get_required_api());
//  set_pack_max_size(PACK_MAX_SIZE);
}


