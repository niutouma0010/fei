local mobileUtil = require "packages.fei.util"

local hudiequan = fk.CreateSkill {
  name = "fei__hudiequan",
}

Fk:loadTranslationTable {
  ["fei__hudiequan"] = "狐蝶拳",
  [":fei__hudiequan"] = "当你成为非装备牌的目标后，若你没有明置牌，你可以令此牌对你无效，然后获得并明置此牌；\n" ..
    "你可以将即时牌交给一名角色以视为对其使用之，若此牌不为明置牌，则此技能本回合视为“匿伏”。",

  ["#fei__hudiequan-nullify"] = "狐蝶拳：是否令%arg对你无效，然后获得并明置此牌？",
  ["#fei__hudiequan-use"] = "狐蝶拳：将一张即时牌交给一名角色，视为对其使用之",
}

local function isInstantCard(card)
  return card.type == Card.TypeBasic or card:isCommonTrick()
end

local function hasDisplayedHandCard(room, player)
  return table.find(player:getCardIds("h"), function(id)
    return mobileUtil.cardIsVisible(room, id)
  end) ~= nil
end

hudiequan:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(hudiequan.name) or
      data.card.type == Card.TypeEquip or hasDisplayedHandCard(player.room, player) then
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
    if #selected > 0 or #cards ~= 1 then return false end
    local original = Fk:getCardById(cards[1])
    local card = Fk:cloneCard(original.name, original.suit, original.number)
    card.skillName = hudiequan.name
    return player:canUseTo(card, to_select, { bypass_times = true })
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local to = effect.tos[1]
    local id = effect.cards[1]
    local original = Fk:getCardById(id)
    local was_displayed = mobileUtil.cardIsVisible(room, original)
    local card = Fk:cloneCard(original.name, original.suit, original.number)
    card.skillName = hudiequan.name

    room:moveCardTo(id, Card.PlayerHand, to, fk.ReasonGive,
      hudiequan.name, nil, was_displayed, player)
    if not player.dead and not to.dead and player:canUseTo(card, to, { bypass_times = true }) then
      room:useCard {
        from = player,
        tos = { to },
        card = card,
        extraUse = true,
      }
    end

    if not was_displayed and not player.dead then
      room:invalidateSkill(player, hudiequan.name, "-turn")
      if not player:hasSkill("fei__yuzi_nifu", true) then
        room:handleAddLoseSkills(player, "fei__yuzi_nifu", hudiequan.name, false)
      end
    end
  end,
})

return hudiequan
