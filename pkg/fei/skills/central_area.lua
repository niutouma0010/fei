local central_area = fk.CreateSkill {
  name = "#fei__central_area",
}

local banner_name = "fei__central_area"
local seen_mark = "fei__central_area_seen-turn"
local related_skills = {}

function central_area.registerSkill(skill_name)
  table.insertIfNeed(related_skills, skill_name)
end

function central_area.isActive(room)
  return table.find(room.alive_players, function(player)
    return table.find(related_skills, function(skill_name)
      return player:hasSkill(skill_name, true)
    end) ~= nil
  end) ~= nil
end

function central_area.getCards(room)
  local cards = room:getBanner(banner_name)
  if type(cards) ~= "table" then return {} end
  return table.filter(cards, function(id)
    return room:getCardArea(id) == Card.DiscardPile
  end)
end

central_area:addEffect(fk.AfterCardsMove, {
  global = true,
  mute = true,
  priority = 1000,
  can_refresh = function(self, event, target, player, data)
    local room = player.room
    if player ~= room.alive_players[1] or not central_area.isActive(room) then
      return false
    end
    return table.find(data, function(move)
      return move.toArea == Card.DiscardPile and table.find(move.moveInfo, function(info)
        return info.beforeCard:getMark(seen_mark) == 0
      end) ~= nil
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local cards = central_area.getCards(room)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if info.beforeCard:getMark(seen_mark) == 0 and
            room:getCardArea(info.cardId) == Card.DiscardPile then
            table.insertIfNeed(cards, info.cardId)
            room:setCardMark(Fk:getCardById(info.cardId), seen_mark, 1)
          end
        end
      end
    end
    room:setBanner(banner_name, cards)
  end,
})

central_area:addEffect(fk.TurnEnd, {
  global = true,
  mute = true,
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return player == player.room.alive_players[1] and
      type(player.room:getBanner(banner_name)) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setBanner(banner_name, nil)
  end,
})

central_area:addEffect(fk.TurnStart, {
  global = true,
  mute = true,
  priority = 1000,
  can_refresh = function(self, event, target, player, data)
    return player == player.room.alive_players[1] and
      type(player.room:getBanner(banner_name)) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setBanner(banner_name, nil)
  end,
})

return central_area
