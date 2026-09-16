local tianleiyin = fk.CreateSkill {
  name = "fei__tianleiyin",
}

local moving_mark = "fei__tianleiyin_moving"

Fk:loadTranslationTable {
  ["fei__tianleiyin"] = "天雷引",
  [":fei__tianleiyin"] = "当【闪电】离开一名角色的区域时，你可以将之置入你的判定区，然后观看其区域内的任意张牌并将其中一张牌置于牌堆顶。",
  ["#fei__tianleiyin-invoke"] = "天雷引：是否将离开 %dest 区域的%arg置入你的判定区？",
  ["#fei__tianleiyin-top"] = "天雷引：观看 %dest 区域内的牌，将其中一张置于牌堆顶",
}

local function leftPlayerArea(info)
  return info.fromArea == Card.PlayerHand or
    info.fromArea == Card.PlayerEquip or
    info.fromArea == Card.PlayerJudge
end

local function isLightningWhenLost(info)
  return info.beforeCard and info.beforeCard.name == "lightning"
end

tianleiyin:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(tianleiyin.name) or
      table.contains(player.sealedSlots, Player.JudgeSlot) or
      player:hasDelayedTrick("lightning") then
      return false
    end

    for _, move in ipairs(data) do
      if move.from then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if leftPlayerArea(info) and isLightningWhenLost(info) and
            card:getMark(moving_mark) == 0 and
            player.room:getCardArea(info.cardId) ~= Card.Void then
            event:setCostData(self, {
              cards = { info.cardId },
              from = move.from,
            })
            return true
          end
        end
      end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local cost = event:getCostData(self)
    local id = cost.cards[1]
    if player.room:getCardArea(id) == Card.Void then return false end
    return player.room:askToSkillInvoke(player, {
      skill_name = tianleiyin.name,
      prompt = "#fei__tianleiyin-invoke::" .. cost.from.id .. ":" ..
        Fk:getCardById(id):toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    local id = cost.cards[1]
    local from = cost.from
    local card = Fk:getCardById(id)
    if room:getCardArea(id) == Card.Void then return end

    room:setCardMark(card, moving_mark, 1)
    local lightning = Fk:cloneCard("lightning", card.suit, card.number)
    lightning:addSubcard(id)
    lightning.skillName = tianleiyin.name
    player:addVirtualEquip(lightning)
    room:moveCardTo(lightning, Card.PlayerJudge, player, fk.ReasonPut,
      tianleiyin.name, nil, true, player)
    room:setCardMark(card, moving_mark, 0)

    if player.dead or from.dead then return end
    local cards = from:getCardIds("hej")
    if #cards == 0 then return end
    local id2 = room:askToChooseCard(player, {
      target = from,
      flag = { card_data = { { from.general, cards } } },
      skill_name = tianleiyin.name,
      prompt = "#fei__tianleiyin-top::" .. from.id,
    })
    if id2 then
      room:moveCardTo(id2, Card.DrawPile, nil, fk.ReasonPut,
        tianleiyin.name, nil, true, player)
    end
  end,
})

return tianleiyin
