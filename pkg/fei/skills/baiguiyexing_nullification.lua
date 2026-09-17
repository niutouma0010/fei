local skill = fk.CreateSkill { name = "fei__baiguiyexing_nullification" }
local registered_mark = "fei__baiguiyexing_nullification"

local function registeredCards(player)
  return table.filter(player:getCardIds("ej"), function(id)
    return Fk:getCardById(id, true):getMark(registered_mark) == player.id
  end)
end

Fk:loadTranslationTable {
  ["fei__baiguiyexing_nullification"] = "百鬼夜行",
  [":fei__baiguiyexing_nullification"] = "你可以将〖百鬼夜行〗登记且未发生过区域移动的一张场上牌当【无懈可击】使用。",
  ["#fei__baiguiyexing-nullification"] = "百鬼夜行：你可以将场上未被重铸的一张牌当【无懈可击】使用",
}

skill:addEffect("viewas", {
  anim_type = "control",
  pattern = "nullification",
  prompt = "#fei__baiguiyexing-nullification",
  include_equip = true,
  expand_pile = function(self, player)
    return registeredCards(player)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(registeredCards(player), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("nullification")
    card.skillName = "fei__baiguiyexing"
    card:addSubcards(cards)
    return card
  end,
  enabled_at_response = function(self, player, response)
    return not response and #registeredCards(player) > 0
  end,
  enabled_at_nullification = function(self, player, data)
    return #registeredCards(player) > 0
  end,
})

skill:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(skill.name, true, true) and table.find(data, function(move)
      return table.find(move.moveInfo, function(info)
        return info.beforeCard:getMark(registered_mark) == player.id
      end) ~= nil
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      for _, info in ipairs(move.moveInfo) do
        if info.beforeCard:getMark(registered_mark) == player.id then
          room:setCardMark(Fk:getCardById(info.cardId, true), registered_mark, 0)
        end
      end
    end
  end,
})

return skill
