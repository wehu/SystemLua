--[[
Copyright (c) 2013 Wei Hu, huwei04@hotmail.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--]]

sl_object = {}

function sl_object:mixin(...)
  for _, v in ipairs(arg) do
    local l = 1
    for i, m in ipairs(self.modules) do
      if m == v then break end
      l = l + 1
    end
    if l > table.getn(self.modules) then
      table.insert(self.modules, v)
    end
  end
end

function sl_object:new(parent)
  if not parent then
    parent = sl_object
  end
  local o = {super=parent, modules={}}
  setmetatable(o, {__index = function (_, k)
    if o.super[k] then return o.super[k] end
    for i=1, table.getn(o.modules) do
      local v = o.modules[i][k]     -- try `i'-th superclass
      if v then return v end
    end
  end})
  return o
end

