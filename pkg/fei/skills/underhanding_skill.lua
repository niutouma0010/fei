local skill = fk.CreateSkill { name = "fei__underhanding_skill" }

skill:addEffect("cardskill", {
  min_target_num = 1,
  max_target_num = 2,
  mod_target_filter = function(self, player, to_select)
    return to_select ~= player and not to_select:isAllNude()
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local from, to = effect.from, effect.to
    if from.dead or to.dead or to:isAllNude() then return end
    local id = room:askToChooseCard(from, { target = to, flag = "hej", skill_name = skill.name })
    room:obtainCard(from, id, false, fk.ReasonPrey, from, skill.name)
    if from.dead or to.dead or from:isNude() then return end
    local cards = room:askToCards(from, {
      min_num = 1, max_num = 1, include_equip = true,
      skill_name = skill.name, cancelable = false,
    })
    if #cards > 0 then room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, skill.name, nil, false, from) end
  end,
})

return skill
