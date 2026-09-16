local leifajiangshi = fk.CreateSkill {
  name = "fei__leifajiangshi",
}

Fk:loadTranslationTable {
  ["fei__leifajiangshi"] = "雷罚降世",
  [":fei__leifajiangshi"] = "阶段技，你可以重铸任意张牌，然后令至多等量名角色依次进行一次判定，若结果花色与此流程中进入弃牌堆的牌均不同，其受到1点雷电伤害。",
  ["#fei__leifajiangshi"] = "雷罚降世：重铸任意张牌，并令至多等量名角色依次判定",
}

leifajiangshi:addEffect("active", {
  anim_type = "offensive",
  prompt = "#fei__leifajiangshi",
  min_card_num = 1,
  max_card_num = 999,
  min_target_num = 0,
  max_target_num = 999,
  max_phase_use_time = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(leifajiangshi.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getCardIds("he"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected < #selected_cards
  end,
  feasible = function(self, player, selected, selected_cards)
    return #selected_cards > 0 and #selected <= #selected_cards
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local suits = {}
    for _, id in ipairs(effect.cards) do
      table.insertIfNeed(suits, Fk:getCardById(id).suit)
    end
    room:recastCard(effect.cards, player, leifajiangshi.name)

    local targets = effect.tos
    room:sortByAction(targets)
    for _, to in ipairs(targets) do
      if not to.dead then
        local judge = {
          who = to,
          reason = leifajiangshi.name,
          pattern = { ["."] = "good" },
        }
        room:judge(judge)
        if not to.dead and judge.card and not table.contains(suits, judge.card.suit) then
          room:damage {
            from = player,
            to = to,
            damage = 1,
            damageType = fk.ThunderDamage,
            skillName = leifajiangshi.name,
          }
        end
      end
    end
  end,
})

return leifajiangshi
