function sl_checkarg(a, t)
  if type(a) ~= t then
    err("expect an argument of "..t..", but got an argument of "..type(a))
  end
end
