#include "bp_provided.h"
#include "bp_required.h"
#include <string.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

static lua_State *L = NULL;

static int lua_stack_base = 0;

static unsigned initialize_adapter();

#define BP(f) (*bpProvidedAPI->f##_ptr)

static bp_api_struct * bpProvidedAPI = NULL;

static unsigned framework_id = initialize_adapter();

static void set_debug_mode(int mode) {
}

static void startup() {
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
  if(luaL_loadfile(L, filename) != 0)
    error(L, "%s", lua_tostring(L, -1));
  if(lua_pcall(L, 0, 0, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));

  lua_getglobal(L, "component");
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
}

static int notify_tree_phase(int          target_id,
                             const char * phase_group,
                             const char * phase_name) {
}

static int notify_runtime_phase(const char *     phase_group,
                                const char *     phase_name,
                                unsigned int     phase_action,
                                uvm_ml_time_unit time_unit,
                                double           time_value,
                                unsigned int *   participate) {
}

static int find_connector_id_by_name(const char * path) {
  lua_getglobal(L, "socket");
  lua_pushstring(L, path);
  if (lua_pcall(L, 1, 1, lua_stack_base) != 0)
    error(L, "%s", lua_tostring(L, -1));
  lua_getfield(L, -1, "id");
  int id = lua_tointeger(L, -1);
  lua_pop(L, 1);
  return id;
}

static const char* get_connector_intf_name(unsigned connector_id) {
}

static unsigned is_export_connector(unsigned connector_id) {
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

static bp_frmw_c_api_struct* uvm_ml_sl_get_required_api() {
  bp_frmw_c_api_struct * required_api = new bp_frmw_c_api_struct();
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
  //required_api->put_uvm_ml_stream_request_ptr = uvm_ml_tlm_rec::request_put;
  //required_api->get_uvm_ml_stream_request_ptr = uvm_ml_tlm_rec::request_get;
  //required_api->get_requested_uvm_ml_stream_ptr = uvm_ml_tlm_rec::get_requested;
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
  //required_api->notify_end_blocking_ptr = uvm_ml_tlm_rec::notify_end_blocking;
  //required_api->tlm2_b_transport_request_ptr = uvm_ml_tlm_rec::tlm2_b_transport_request;
  //required_api->tlm2_b_transport_response_ptr = uvm_ml_tlm_rec::tlm2_b_transport_response;
  //required_api->tlm2_nb_transport_fw_ptr =  uvm_ml_tlm_rec::tlm2_nb_transport_fw;
  //required_api->tlm2_nb_transport_bw_ptr = uvm_ml_tlm_rec::tlm2_nb_transport_bw;
  //required_api->tlm2_transport_dbg_ptr = uvm_ml_tlm_rec::tlm2_transport_dbg;
  //required_api->tlm2_turn_off_transaction_mapping_ptr = (uvm_ml_tlm_rec::tlm2_turn_off_transaction_mapping);
  required_api->synchronize_ptr = uvm_ml_tlm_rec::synchronize;

  //required_api->create_child_junction_node_ptr = uvm_ml_tlm_rec::create_child_junction_node;
  return required_api;
}

static unsigned initialize_adapter() {
  backplane_open();
  assert(backplane_handle != NULL);
  bp_api_struct* (*bp_get_provided_tray_ptr)() = (bp_api_struct* (*)())dlsym(backplane_handle, backplane_get_provided_tray);
  bpProvidedAPI = (bp_get_provided_tray_ptr)();
  assert(bpProvidedAPI != NULL);
  char *frmw_ids[3] = {(char*)"UVMSL", (char*)"SL",(char*)""};
  return BP(register_framework)((char*)"SystemLua",frmw_ids, uvm_ml_sl_get_required_api());
}


