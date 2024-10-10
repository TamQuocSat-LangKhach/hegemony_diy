local lunar = require "packages/hegemony_diy/lunar_heg"
local work = require "packages/hegemony_diy/work_heg"
local zxj = require "packages/hegemony_diy/zxj_heg"

local heg = Fk.game_modes["new_heg_mode"]
table.insertTable(heg.whitelist, {"lunar_heg"})
table.insertTable(heg.whitelist, {"work_heg"})
table.insertTable(heg.whitelist, {"zxj_heg"})

return {
  lunar,
  work,
  zxj,
}
