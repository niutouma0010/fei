local mobileUtil = require "packages.fei.util"

local hudiequan = fk.CreateSkill {
  name = "fei__hudiequan",
}

Fk:loadTranslationTable {
  ["fei__hudiequan"] = "狐蝶拳",
  [":fei__hudiequan"] = "当你成为非装备牌的目标后，若你没有明置牌或手牌数为3，你可以令此牌对你无效，然后获得并明置此牌；\n" ..
    "你可以将给出一张即时牌并对一名角色视为使用之，若此牌不为明置牌或目标不为其，则此技能本回合视为“匿伏”。",

  ["#fei__hudiequan-nullify"] = "狐蝶拳：是否令%arg对你无效，然后获得并明置此牌？",
  ["#fei__hudiequan-use"] = "狐蝶拳：将一张即时牌交给一名角色，然后选择视为使用此牌的目标",
  ["#fei__hudiequan-target"] = "狐蝶拳：请选择视为使用【%arg】的目标",
  ["#fei__hudiequan-response-card"] = "狐蝶拳：选择要给出的即时牌",
  ["#fei__hudiequan-response-recipient"] = "狐蝶拳：选择获得此牌的其他角色",
}

local function isInstantCard(card)
  return card.type == Card.TypeBasic or card:isCommonTrick()
end

local function hasDisplayedHandCard(room, player)
  return table.find(player:getCardIds("h"), function(id)
    return mobileUtil.cardIsVisible(room, id)
  end) ~= nil
end

local function enterNifu(player)
  local room = player.room
  room:invalidateSkill(player, hudiequan.name, "-turn")
  room:invalidateSkill(player, "fei__hudiequan_response", "-turn")
  if not player:hasSkill("fei__yuzi_nifu", true) then
    room:handleAddLoseSkills(player, "fei__yuzi_nifu", hudiequan.name, false)
  end
end

hudiequan:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(hudiequan.name) or
      data.card.type == Card.TypeEquip or
      (hasDisplayedHandCard(player.room, player) and player:getHandcardNum() ~= 3) then
      return false
    end
    return #player.room:getSubcardsByRule(data.card, { Card.Processing }) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = hudiequan.name,
      prompt = "#fei__hudiequan-nullify:::" .. data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.use.nullifiedTargets = data.use.nullifiedTargets or {}
    table.insertIfNeed(data.use.nullifiedTargets, player)

    local cards = room:getSubcardsByRule(data.card, { Card.Processing })
    if #cards == 0 then return end
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey,
      hudiequan.name, nil, true, player)
    local obtained = table.filter(cards, function(id)
      return room:getCardOwner(id) == player and room:getCardArea(id) == Card.PlayerHand
    end)
    if #obtained > 0 then
      mobileUtil.displayCards(player, obtained)
    end
  end,
})

hudiequan:addEffect("active", {
  anim_type = "control",
  prompt = "#fei__hudiequan-use",
  card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select) and
      isInstantCard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, player, to_select, selected, cards)
    if #selected > 0 or #cards ~= 1 or to_select == player then return false end
    local original = Fk:getCardById(cards[1])
    local card = Fk:cloneCard(original.name, original.suit, original.number)
    card.skillName = hudiequan.name
    return table.find(Fk:currentRoom().alive_players, function(p)
      return player:canUseTo(card, p, { bypass_times = true, bypass_distances = true })
    end) ~= nil
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local recipient = effect.tos[1]
    local id = effect.cards[1]
    local original = Fk:getCardById(id)
    local was_displayed = mobileUtil.cardIsVisible(room, original)
    local card = Fk:cloneCard(original.name, original.suit, original.number)
    card.skillName = hudiequan.name

    room:moveCardTo(id, Card.PlayerHand, recipient, fk.ReasonGive,
      hudiequan.name, nil, was_displayed, player)
    if player.dead then return end
    local candidates = table.filter(room.alive_players, function(p)
      return player:canUseTo(card, p, { bypass_times = true, bypass_distances = true })
    end)
    if #candidates == 0 then return end
    local chosen = room:askToChoosePlayers(player, {
      targets = candidates,
      min_num = 1,
      max_num = 1,
      skill_name = hudiequan.name,
      prompt = "#fei__hudiequan-target:::" .. card:toLogString(),
      cancelable = false,
    })
    local use_target = chosen[1]
    if use_target then
      room:useCard {
        from = player,
        tos = { use_target },
        card = card,
        extraUse = true,
      }
    end
    if not player.dead and (not was_displayed or use_target ~= recipient) then
      enterNifu(player)
    end
  end,
})

hudiequan:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, hudiequan.name)
  end,
  bypass_distances = function(self, player, skill, card)
    return card and table.contains(card.skillNames, hudiequan.name)
  end,
})

hudiequan:addEffect(fk.PreCardUse, {
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, hudiequan.name)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

return hudiequan
