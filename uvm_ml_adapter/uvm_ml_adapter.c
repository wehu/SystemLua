#include <assert.h>
#include <dlfcn.h> 
#include <stdlib.h>
#include <bp_provided.h>
#include <bp_required.h>
#include <string.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

static lua_State *L = NULL;

static int lua_stack_base = 0;

#define BP(f) (*bpProvidedAPI->f##_ptr)

static bp_api_struct * bpProvidedAPI = NULL;

static unsigned framework_id = -1;

static uvm_ml_time_unit m_time_unit = TIME_UNIT_UNDEFINED;
static double           m_time_value = -1;

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
  int len = luaL_getn(L, 4);
  uvm_ml_stream_t data = (uvm_ml_stream_t)malloc(len*sizeof(uvm_ml_stream_t));
  assert(data);
  int i = 1;
  for(; i <= len; i++) {
    lua_rawgeti(L, 4, i);
    data[i-1] = lua_tointeger(L, -1);
  };
  unsigned done = 0;
  unsigned disable = BP(request_put)(
    framework_id,
    id,
    call_id,
    len,
    data,
    &done,
    &m_time_unit,
    &m_time_value
  );
  free(data);
  lua_pushnumber(L, disable);
  return 1;
}

static int uvm_sl_ml_request_get(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  unsigned call_id = luaL_checknumber(L, 2);
  unsigned callback_adapter_id = luaL_checknumber(L, 3);
  unsigned done = 0;
  int disable = BP(request_get)(
    framework_id,
    id,
    call_id,
    0,
    0,
    &done,
    &m_time_unit,
    &m_time_value
  );
  lua_pushnumber(L, disable);
  return 1;
}

static int uvm_sl_ml_get_requested(lua_State * L) {
  assert (bpProvidedAPI != NULL);
  int id = luaL_checknumber(L, 1);
  unsigned call_id = luaL_checknumber(L, 2);
  unsigned callback_adapter_id = luaL_checknumber(L, 3);
  unsigned stream_size = luaL_checknumber(L, 4);
  uvm_ml_stream_t data = (uvm_ml_stream_t)malloc(stream_size*sizeof(uvm_ml_stream_t));
  BP(get_requested)(
    framework_id,
    id,
    call_id,
    data
  );
  lua_newtable(L);
  int top = lua_gettop(L);
  int i = 1;
  for(;i <= stream_size; i++) {
    lua_pushnumber(L, i); 
    lua_pushnumber(L, data[i-1]);
    lua_settable(L, top);
  };
  free(data);
  return 1;
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

  lua_pushcfunction(L, uvm_sl_ml_request_get);
  lua_setglobal(L, "uvm_sl_ml_request_get");

  lua_pushcfunction(L, uvm_sl_ml_get_requested);
  lua_setglobal(L, "uvm_sl_ml_get_requested");

  lua_pushcfunction(L, uvm_sl_ml_get_type_id);
  lua_setglobal(L, "uvm_sl_ml_get_type_id");

  lua_pushcfunction(L, uvm_sl_ml_get_type_name);
  lua_setglobal(L, "uvm_sl_ml_get_type_name");

#ifdef SYS_LUA_CORE_FILE
  if(luaL_dofile(L, SYS_LUA_CORE_FILE) != 0)
#else
  if(luaL_dofile(L, "sl_core.lua") != 0)
#endif
    error(L, "%s", lua_tostring(L, -1));

  lua_getglobal(L, "sl_traceback");
  lua_stack_base = lua_gettop(L);
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
  int id = lua_tointeger(L, -1);
  lua_pop(L, 1);
  return id; 
}

static int notify_phase(const char * phase_group,
                        const char * phase_name,
                        unsigned int phase_action) {
  lua_getglobal(L, "notify_phase");
  lua_pushstring(L, phase_name);
  if (lua_pcall(L, 1, 0, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  return 1;
}

static int notify_tree_phase(int          target_id,
                             const char * phase_group,
                             const char * phase_name) {
  lua_getglobal(L, "find_component_by_id");
  lua_pushnumber(L, target_id);
  if (lua_pcall(L, 1, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  lua_getfield(L, -1, "notify_phase");
  lua_insert(L, -2);
  lua_pushstring(L, phase_name);
  if (lua_pcall(L, 2, 0, lua_stack_base) != 0)
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
  lua_pushstring(L, phase_name);
  if (lua_pcall(L, 1, 0, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  return 1;
}

static int find_connector_id_by_name(const char * path) {
  lua_getglobal(L, "find_port_by_full_name");
  lua_pushstring(L, path);
  if (lua_pcall(L, 1, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  lua_getfield(L, -1, "id");
  int id = lua_tointeger(L, -1);
  lua_pop(L, 1);
  return id;
}

static const char* get_connector_intf_name(unsigned connector_id) {
  lua_getglobal(L, "find_port_by_id");
  lua_pushnumber(L, connector_id);
  if (lua_pcall(L, 1, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  lua_getfield(L, -1, "typ");
  const char * intf_name = lua_tostring(L, -1);
  lua_pop(L, 1);
  return intf_name;
}

static unsigned is_export_connector(unsigned connector_id) {
  lua_getglobal(L, "find_port_by_id");
  lua_pushnumber(L, connector_id);
  if (lua_pcall(L, 1, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  lua_getfield(L, -1, "is_export");
  int is_export = lua_toboolean(L, -1);
  lua_pop(L, 1);
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
  int len = luaL_getn(L, -1);
  int i = 1;
  for(; i <= len; i++) {
    lua_rawgeti(L, -2, i);
    stream[i-1] = lua_tointeger(L, -1);
  };
  lua_pop(L, 1); 
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
  lua_getglobal(L, "component_proxy");
  lua_getglobal(L, component_type_name);
  lua_pushstring(L, instance_name);
  lua_pushstring(L, parent_full_name);
  lua_pushnumber(L, parent_framework_id);
  lua_pushnumber(L, parent_junction_node_id);
  if (lua_pcall(L, 5, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  lua_getfield(L, -1, "id");
  int id = lua_tointeger(L, -1);
  lua_pop(L, 1);
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
  //required_api->try_put_uvm_ml_stream_ptr = uvm_ml_tlm_rec::nb_put;
  //required_api->can_put_ptr = uvm_ml_tlm_rec::can_put;
  required_api->put_uvm_ml_stream_request_ptr = request_put;
  required_api->get_uvm_ml_stream_request_ptr = request_get;
  required_api->get_requested_uvm_ml_stream_ptr = get_requested;
  //required_api->try_get_uvm_ml_stream_ptr = uvm_ml_tlm_rec::nb_get;
  //required_api->can_get_ptr = uvm_ml_tlm_rec::can_get;
  //required_api->peek_uvm_ml_stream_request_ptr = uvm_ml_tlm_rec::request_peek;
  //required_api->peek_requested_uvm_ml_stream_ptr = uvm_ml_tlm_rec::peek_requested;
  //required_api->try_peek_uvm_ml_stream_ptr = uvm_ml_tlm_rec::nb_peek;
  //required_api->can_peek_ptr = uvm_ml_tlm_rec::can_peek;
  //required_api->transport_uvm_ml_stream_request_ptr = uvm_ml_tlm_rec::request_transport;
  //required_api->transport_response_uvm_ml_stream_ptr = uvm_ml_tlm_rec::transport_response;
  //required_api->nb_transport_uvm_ml_stream_ptr = uvm_ml_tlm_rec::nb_transport;
  //required_api->write_uvm_ml_stream_ptr = uvm_ml_tlm_rec::write;
  required_api->notify_end_blocking_ptr = notify_end_blocking;
  //required_api->tlm2_b_transport_request_ptr = uvm_ml_tlm_rec::tlm2_b_transport_request;
  //required_api->tlm2_b_transport_response_ptr = uvm_ml_tlm_rec::tlm2_b_transport_response;
  //required_api->tlm2_nb_transport_fw_ptr =  uvm_ml_tlm_rec::tlm2_nb_transport_fw;
  //required_api->tlm2_nb_transport_bw_ptr = uvm_ml_tlm_rec::tlm2_nb_transport_bw;
  //required_api->tlm2_transport_dbg_ptr = uvm_ml_tlm_rec::tlm2_transport_dbg;
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
}


