local baiguiyexing = fk.CreateSkill {
  name = "fei__baiguiyexing",
}

Fk:loadTranslationTable {
  ["fei__baiguiyexing"] = "百鬼夜行",
  [":fei__baiguiyexing"] = "阶段技，你可以重铸区域内若干张花色各不相同的牌以视为使用一张目标数上限相同的【火攻】。",

  ["#fei__baiguiyexing"] = "百鬼夜行：你可以重铸区域内若干张花色各不相同的牌以视为使用一张目标数上限相同的【火攻】",
}

baiguiyexing:addEffect("active", {
  anim_type = "offensive",
  prompt = "#fei__baiguiyexing",
  min_card_num = 1,
  max_card_num = 4,
  min_target_num = 1,
  max_target_num = 4,
  max_phase_use_time = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(baiguiyexing.name, Player.HistoryPhase) == 0 and
      #player:getCardIds("hej") > 0
  end,
  card_filter = function(self, player, to_select, selected)
    if not table.contains(player:getCardIds("hej"), to_select) then return false end
    local suit = Fk:getCardById(to_select).suit
    return suit ~= Card.NoSuit and table.every(selected, function(id)
      return Fk:getCardById(id).suit ~= suit
    end)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected >= #selected_cards then return false end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = baiguiyexing.name
    return player:canUseTo(card, to_select)
  end,
  feasible = function(self, player, selected, selected_cards)
    return #selected_cards > 0 and #selected > 0 and #selected <= #selected_cards
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:recastCard(effect.cards, player, baiguiyexing.name)
    if player.dead then return end
    local targets = table.filter(effect.tos, function(p)
      return not p.dead and not p:isKongcheng()
    end)
    if #targets == 0 then return end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = baiguiyexing.name
    room:useCard {
      from = player,
      tos = targets,
      card = card,
    }
  end,
})

return baiguiyexing
