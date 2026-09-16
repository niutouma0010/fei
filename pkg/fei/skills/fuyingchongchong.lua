local mobileUtil = require "packages.mobile.mobile_util"

local fuyingchongchong = fk.CreateSkill {
  name = "fei__fuyingchongchong",
}

local analeptic_mark = "fei__fuyingchongchong_analeptic-turn"

Fk:loadTranslationTable {
  ["fei__fuyingchongchong"] = "蝠影重重",
  [":fei__fuyingchongchong"] = "当你使用伤害牌时，你可以失去1点体力并摸一张牌，然后明置一张手牌并令之本回合视为不计入次数的【酒】。",

  ["#fei__fuyingchongchong-invoke"] = "蝠影重重：你可以失去1点体力并摸一张牌，然后明置一张手牌令其本回合视为不计入次数的【酒】",
  ["#fei__fuyingchongchong-card"] = "蝠影重重：请明置一张手牌，令其本回合视为不计入次数的【酒】",
}

fuyingchongchong:addEffect("filter", {
  card_filter = function(self, card, player)
    return player:hasSkill(fuyingchongchong.name) and card:getMark(analeptic_mark) > 0 and
      table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    local c = Fk:cloneCard("analeptic", card.suit, card.number)
    c.skillName = fuyingchongchong.name
    return c
  end,
})

fuyingchongchong:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(fuyingchongchong.name) and card and
      card.trueName == "analeptic" and table.contains(card.skillNames, fuyingchongchong.name)
  end,
})

fuyingchongchong:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.trueName == "analeptic" and
      table.contains(data.card.skillNames, fuyingchongchong.name)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

fuyingchongchong:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuyingchongchong.name) and
      not player.dead and data.card.is_damage_card
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = fuyingchongchong.name,
      prompt = "#fei__fuyingchongchong-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, fuyingchongchong.name)
    if player.dead then return end
    player:drawCards(1, fuyingchongchong.name)
    if player.dead or player:isKongcheng() then return end

    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = fuyingchongchong.name,
      pattern = ".|.|.|hand",
      prompt = "#fei__fuyingchongchong-card",
      cancelable = false,
    })
    if #cards == 0 then return end
    mobileUtil.displayCards(player, cards)
    room:setCardMark(Fk:getCardById(cards[1]), analeptic_mark, 1)
    player:filterHandcards()
  end,
})

return fuyingchongchong
