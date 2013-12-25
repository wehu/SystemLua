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

#include "vpi_user.h"
#include "veriuser.h"

#include "sys_lua.h"

static s_vpi_systf_data task_data_s;

void register_sys_lua() {
  p_vpi_systf_data task_data_p = &task_data_s;
  task_data_p->type = vpiSysTask;
  task_data_p->tfname = "$sys_lua";
  task_data_p->calltf = sys_lua_calltf;
  task_data_p->compiletf = sys_lua_checktf;
  vpi_register_systf(task_data_p);
}

// Register the new system task here

void (*vlog_startup_routines[]) () = {
  register_sys_lua,
  0  // last entry must be 0 
}; 


