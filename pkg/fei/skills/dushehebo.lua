local dushehebo = fk.CreateSkill {
  name = "fei__dushehebo",
}

Fk:loadTranslationTable {
  ["fei__dushehebo"] = "毒舌河伯",
  [":fei__dushehebo"] = "每回合结束时，你可以将手牌数弃至上限，然后将弃置牌依次当【出其不意】使用。",
  ["#fei__dushehebo-invoke"] = "毒舌河伯：是否将手牌数弃至手牌上限，然后将弃置牌依次当【出其不意】使用？",
  ["#fei__dushehebo-use"] = "毒舌河伯：将此弃置牌当【出其不意】使用",
}

dushehebo:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(dushehebo.name) and
      player:getHandcardNum() > math.max(player:getMaxCards(), 0)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = dushehebo.name,
      prompt = "#fei__dushehebo-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getHandcardNum() - math.max(player:getMaxCards(), 0)
    if n <= 0 then return end
    local cards = room:askToDiscard(player, {
      min_num = n,
      max_num = n,
      include_equip = false,
      skill_name = dushehebo.name,
      cancelable = false,
      skip = true,
    })
    room:throwCard(cards, dushehebo.name, player, player)
    for _, id in ipairs(cards) do
      if player.dead then break end
      if room:getCardArea(id) == Card.DiscardPile then
        local use = room:askToUseVirtualCard(player, {
          name = "fei__unexpectation",
          skill_name = dushehebo.name,
          prompt = "#fei__dushehebo-use",
          cancelable = false,
          skip = true,
          subcards = { id },
        })
        if use then room:useCard(use) end
      end
    end
  end,
})

return dushehebo
