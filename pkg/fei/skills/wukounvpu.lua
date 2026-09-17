local wukounvpu = fk.CreateSkill {
  name = "fei__wukounvpu",
  tags = { Skill.Compulsory },
}

local nosuit_mark = "fei__wukounvpu_nosuit-turn"

Fk:loadTranslationTable {
  ["fei__wukounvpu"] = "无口女仆",
  [":fei__wukounvpu"] = "锁定技，你的牌无花色，当你须响应牌时，你展示对方至多半数手牌，这些牌本回合亦无花色。已无花色的牌被展示或弃置后，你摸一张牌。",
  ["#fei__wukounvpu-choose"] = "无口女仆：展示 %dest 至多半数手牌，这些牌本回合无花色",
}

local function responseSource(player, data)
  local event_data = data.eventData
  if not event_data then return end
  local from = event_data.from
  if type(from) == "number" then
    from = player.room:getPlayerById(from)
  end
  if from and from ~= player and not from.dead then return from end
end

local function isNoSuitCard(card, owner)
  return card.suit == Card.NoSuit or
    (owner and owner:hasSkill(wukounvpu.name, true, true)) or
    (owner and card:getMark(nosuit_mark) == owner.id)
end

wukounvpu:addEffect(fk.AskForCardUse, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    local from = responseSource(player, data)
    return target == player and player:hasSkill(wukounvpu.name) and
      from and from:getHandcardNum() >= 2
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = responseSource(player, data)
    if not from then return end
    local cards = room:askToChooseCards(player, {
      target = from,
      min = 1,
      max = math.floor(from:getHandcardNum() / 2),
      flag = "h",
      skill_name = wukounvpu.name,
      prompt = "#fei__wukounvpu-choose::" .. from.id,
    })
    if #cards == 0 then return end
    from:showCards(cards, player)
    for _, id in ipairs(cards) do
      room:setCardMark(Fk:getCardById(id), nosuit_mark, from.id)
    end
    from:filterHandcards()
  end,
})

wukounvpu:addEffect(fk.AskForCardResponse, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    local from = responseSource(player, data)
    return target == player and player:hasSkill(wukounvpu.name) and
      from and from:getHandcardNum() >= 2
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = responseSource(player, data)
    if not from then return end
    local cards = room:askToChooseCards(player, {
      target = from,
      min = 1,
      max = math.floor(from:getHandcardNum() / 2),
      flag = "h",
      skill_name = wukounvpu.name,
      prompt = "#fei__wukounvpu-choose::" .. from.id,
    })
    if #cards == 0 then return end
    from:showCards(cards, player)
    for _, id in ipairs(cards) do
      room:setCardMark(Fk:getCardById(id), nosuit_mark, from.id)
    end
    from:filterHandcards()
  end,
})

wukounvpu:addEffect(fk.CardShown, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(wukounvpu.name) or player.dead or not data.from then return false end
    return table.find(data.cardIds, function(id)
      return isNoSuitCard(Fk:getCardById(id), data.from)
    end) ~= nil
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, wukounvpu.name)
  end,
})

wukounvpu:addEffect(fk.BeforeCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(wukounvpu.name, true, true)
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from and move.moveReason == fk.ReasonDiscard and
        table.find(move.moveInfo, function(info)
          return isNoSuitCard(info.beforeCard, move.from)
        end) then
        move.extra_data = move.extra_data or {}
        move.extra_data.fei__wukounvpu_nosuit = move.extra_data.fei__wukounvpu_nosuit or {}
        move.extra_data.fei__wukounvpu_nosuit[player.id] = true
      end
    end
  end,
})

wukounvpu:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(wukounvpu.name) and not player.dead and
      table.find(data, function(move)
        return ((move.extra_data or {}).fei__wukounvpu_nosuit or {})[player.id]
      end) ~= nil
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, wukounvpu.name)
  end,
})

wukounvpu:addEffect("filter", {
  global = true,
  mute = true,
  card_filter = function(self, card, player)
    return table.contains(player:getCardIds("hej"), card.id) and
      (player:hasSkill(wukounvpu.name) or card:getMark(nosuit_mark) == player.id)
  end,
  view_as = function(self, player, card)
    local result = Fk:cloneCard(card.name, Card.NoSuit, card.number)
    result.skillName = wukounvpu.name
    return result
  end,
})

wukounvpu:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return table.find(data, function(move)
      if not move.from then return false end
      return table.find(move.moveInfo, function(info)
        return info.beforeCard:getMark(nosuit_mark) == move.from.id and
          table.contains({ Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge }, info.fromArea) and
          (move.to ~= move.from or
            not table.contains({ Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge }, move.toArea))
      end)
    end)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.from then
        for _, info in ipairs(move.moveInfo) do
          if info.beforeCard:getMark(nosuit_mark) == move.from.id and
            table.contains({ Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge }, info.fromArea) and
            (move.to ~= move.from or
              not table.contains({ Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge }, move.toArea)) then
            room:setCardMark(Fk:getCardById(info.cardId, true), nosuit_mark, 0)
            Fk:filterCard(info.cardId, move.to)
          end
        end
      end
    end
  end,
})

return wukounvpu
