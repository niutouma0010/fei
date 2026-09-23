local skill = fk.CreateSkill { name = "fei__baiguiyexing_nullification" }
local converted_suits_mark = "fei__baiguiyexing_converted_suits"
local active_mark = "fei__baiguiyexing_active"

local function canConvert(player, id)
  if player:getMark(active_mark) == 0 or
    not table.contains(player:getCardIds("hej"), id) then return false end
  local suit = Fk:getCardById(id, true).suit
  return suit ~= Card.NoSuit and
    not table.contains(player:getTableMark(converted_suits_mark), suit)
end

local function boardCards(player)
  return table.filter(player:getCardIds("ej"), function(id)
    return canConvert(player, id)
  end)
end

local function hasConvertibleCard(player)
  return table.find(player:getCardIds("hej"), function(id)
    return canConvert(player, id)
  end) ~= nil
end

Fk:loadTranslationTable {
  ["fei__baiguiyexing_nullification"] = "百鬼夜行",
  [":fei__baiguiyexing_nullification"] = "你本巡内可将余下花色的牌当【无懈可击】使用。",
  ["#fei__baiguiyexing-nullification"] = "百鬼夜行：你可以将一张余下花色的牌当【无懈可击】使用",
}

skill:addEffect("viewas", {
  anim_type = "control",
  pattern = "nullification",
  prompt = "#fei__baiguiyexing-nullification",
  include_equip = true,
  expand_pile = function(self, player)
    return boardCards(player)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and canConvert(player, to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("nullification")
    card.skillName = "fei__baiguiyexing"
    card:addSubcards(cards)
    return card
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    return not response and hasConvertibleCard(player)
  end,
  enabled_at_nullification = function(self, player, data)
    return hasConvertibleCard(player)
  end,
})

return skill
