local skill = fk.CreateSkill {
  name = "fei__unexpectation_skill",
}

Fk:loadTranslationTable {
  ["fei__unexpectation_skill"] = "出其不意",
  ["#fei__unexpectation_skill"] = "选择一名有手牌的其他角色，展示其一张手牌，若花色与此牌不同则对其造成1点伤害",
}

skill:addEffect("cardskill", {
  prompt = "#fei__unexpectation_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected, card)
    return to_select ~= player and not to_select:isKongcheng()
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.from
    local target = effect.to
    if target:isKongcheng() then return end
    local id = room:askToChooseCard(player, {
      target = target,
      flag = "h",
      skill_name = skill.name,
    })
    target:showCards(id)
    local card = Fk:getCardById(id)
    if target.dead then return end
    if card:compareSuitWith(effect.card, true) then
      room:damage {
        from = player,
        to = target,
        card = effect.card,
        damage = 1,
        skillName = skill.name,
      }
    end
  end,
})

return skill
