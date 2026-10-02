local fei = require "packages.fei.pkg.fei"

local fei_core_page = {
  url = "packages/fei/fei_core/Room.qml",
}

Fk:addUIPackage {
  name = "fei_core",
  boardgame = "lunarltk",
  page = fei_core_page,
}

-- Keep the official freekill-core untouched. The fei package owns and selects
-- its isolated game UI, so existing clients do not need a different core Git
-- history or remote.
if Fk.boardgames and Fk.boardgames["lunarltk"] then
  Fk.boardgames["lunarltk"].page = fei_core_page
end

Fk:loadTranslationTable {
  ["fei"] = "非人学园",
  ["fei_kingdom"] = "非",
  ["Background Settings"] = "局内背景",
  ["Choose Room Background"] = "选择对局背景",
  ["Click a thumbnail to apply it immediately. The choice is saved for later games."] = "点击缩略图即可立即应用，选择会保留到之后的对局。",
  ["fei_core"] = "非人学园界面核心",
  ["Background"] = "背景",
}

return {
  fei,
}
