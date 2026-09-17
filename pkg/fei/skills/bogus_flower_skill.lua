local skill = fk.CreateSkill { name = "fei__bogus_flower_skill" }

skill:addEffect("cardskill", {
  target_num = 1,
  mod_target_filter = function(self, player, to_select)
    return to_select == player
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.to
    if player:isNude() then return end
    local cards = room:askToDiscard(player, {
      min_num = 1, max_num = 2, include_equip = true,
      skill_name = skill.name, cancelable = false, skip = true,
    })
    local hasEquip = table.find(cards, function(id)
      return Fk:getCardById(id).type == Card.TypeEquip
    end) ~= nil
    room:throwCard(cards, skill.name, player, player)
    if not player.dead then player:drawCards(#cards + (hasEquip and 1 or 0), skill.name) end
  end,
})

return skill
