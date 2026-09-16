local chulingtegong = fk.CreateSkill {
  name = "fei__chulingtegong",
}

local analeptic_mark = "fei__chulingtegong-inhand"

local suit_card_names = {
  [Card.Spade] = "lightning",
  [Card.Diamond] = "axe",
  [Card.Heart] = "ice_sword",
  [Card.Club] = "analeptic",
}

local function getEmptyAreaNum(player)
  local n = 0
  if player:isKongcheng() then n = n + 1 end
  if #player:getCardIds("e") == 0 then n = n + 1 end
  if #player:getCardIds("j") == 0 then n = n + 1 end
  return n
end

local function getEmptyAreaSum(player, current)
  local n = getEmptyAreaNum(player)
  if current ~= player then
    n = n + getEmptyAreaNum(current)
  end
  return n
end

local function canPlaceCard(to, id)
  local card = Fk:getCardById(id)
  local name = suit_card_names[card.suit]
  if not name then return false end
  local virtual = Fk:cloneCard(name, card.suit, card.number)
  virtual:addSubcard(id)
  if card.suit == Card.Spade then
    return not table.contains(to.sealedSlots, Player.JudgeSlot) and
      not to:hasDelayedTrick(name) and not to:isProhibited(to, virtual)
  elseif card.suit == Card.Diamond or card.suit == Card.Heart then
    return to:canMoveCardIntoEquip(virtual, true)
  end
  return true
end

Fk:loadTranslationTable {
  ["fei__chulingtegong"] = "除灵特工",
  [":fei__chulingtegong"] = "当你使用牌后，你可以将手牌色数摸至你与当前回合角色空区域数和，然后将一张牌依花色当对应牌置入当前回合角色区域内：♠️，【闪电】；♦，【贯石斧】；♥，【寒冰剑】；♣，【酒】。",

  ["#fei__chulingtegong-invoke"] = "除灵特工：当你使用牌后，你可以将手牌色数摸至你与当前回合角色空区域数和，然后将一张牌依花色当对应牌置入当前回合角色区域内",
  ["#fei__chulingtegong-card"] = "除灵特工：将一张牌依花色当对应牌置入当前回合角色 %dest 的区域内",
}

chulingtegong:addEffect("filter", {
  card_filter = function(self, card, player)
    return card:getMark(analeptic_mark) > 0 and
      table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    local c = Fk:cloneCard("analeptic", card.suit, card.number)
    c.skillName = chulingtegong.name
    return c
  end,
})

chulingtegong:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if not player:hasSkill(chulingtegong.name) then return false end
    return table.find(data, function(move)
      return move.from == player and move.toArea == Card.Processing and
        move.moveReason == fk.ReasonUse
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not use_event or use_event.data.from ~= player then return end
    local current = player.room.current
    if not current or current.dead then return end
    local use = use_event.data
    use.extra_data = use.extra_data or {}
    use.extra_data.fei__chulingtegong_empty_num = getEmptyAreaSum(player, current)
  end,
})

chulingtegong:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    local current = player.room.current
    local empty_num = (data.extra_data or {}).fei__chulingtegong_empty_num
    return target == player and player:hasSkill(chulingtegong.name) and
      current and not current.dead and empty_num and
      player:getHandcardNum() < empty_num
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chulingtegong.name,
      prompt = "#fei__chulingtegong-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local current = room.current
    if not current or current.dead then return end

    local empty_num = (data.extra_data or {}).fei__chulingtegong_empty_num
    local draw_num = (empty_num or 0) - player:getHandcardNum()
    if draw_num <= 0 then return end
    local drawn = player:drawCards(draw_num, chulingtegong.name)
    if not drawn or #drawn == 0 then return end
    if player.dead or current.dead then return end

    local ids = table.filter(player:getCardIds("he"), function(id)
      return canPlaceCard(current, id)
    end)
    if #ids == 0 then return end
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = chulingtegong.name,
      pattern = tostring(Exppattern { id = ids }),
      prompt = "#fei__chulingtegong-card::" .. current.id,
      cancelable = false,
    })
    if #cards == 0 then return end

    local id = cards[1]
    local card = Fk:getCardById(id)
    local name = suit_card_names[card.suit]
    if card.suit == Card.Club then
      room:moveCardTo(id, Card.PlayerHand, current, fk.ReasonPut,
        chulingtegong.name, nil, false, player)
      if room:getCardOwner(id) == current and room:getCardArea(id) == Card.PlayerHand then
        room:setCardMark(Fk:getCardById(id), analeptic_mark, 1)
      end
      return
    end

    local virtual = Fk:cloneCard(name, card.suit, card.number)
    virtual:addSubcard(id)
    if card.suit == Card.Spade then
      current:addVirtualEquip(virtual)
      room:moveCardTo(virtual, Card.PlayerJudge, current, fk.ReasonPut,
        chulingtegong.name, nil, true, player)
    else
      room:moveCardIntoEquip(current, virtual, chulingtegong.name, true, player)
    end
  end,
})

return chulingtegong
