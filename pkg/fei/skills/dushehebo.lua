local dushehebo = fk.CreateSkill {
  name = "fei__dushehebo",
}

local nosuit_mark = "fei__wukounvpu_nosuit-turn"

Fk:loadTranslationTable {
  ["fei__dushehebo"] = "毒舌河伯",
  [":fei__dushehebo"] = "每回合结束时，你可以将超出手牌上限的牌依次按牌面花色当【出其不意】使用。",
  ["#fei__dushehebo-invoke"] = "毒舌河伯：是否将超出手牌上限的牌依次按牌面花色当【出其不意】使用？",
  ["#fei__dushehebo-choose"] = "毒舌河伯：选择超出手牌上限的牌",
  ["#fei__dushehebo-use"] = "毒舌河伯：将此牌按牌面花色当【出其不意】使用",
  ["#fei__dushehebo-target"] = "毒舌河伯：请选择【出其不意】的目标",
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
    local cards = room:askToCards(player, {
      min_num = n,
      max_num = n,
      include_equip = false,
      skill_name = dushehebo.name,
      pattern = ".|.|.|hand",
      prompt = "#fei__dushehebo-choose",
      cancelable = false,
    })
    for _, id in ipairs(cards) do
      if player.dead then break end
      if room:getCardOwner(id) == player and room:getCardArea(id) == Card.PlayerHand then
        local original = Fk:getCardById(id, true)
        -- “无口女仆”只令牌暂时无花色；转化前先恢复实体牌原本的花色。
        room:setCardMark(original, nosuit_mark, 0)
        Fk:filterCard(id, player)
        local card = Fk:cloneCard("fei__unexpectation", original.suit, original.number)
        card.skillName = dushehebo.name
        card:addSubcard(id)
        local candidates = table.filter(room.alive_players, function(p)
          return player:canUseTo(card, p, { bypass_times = true })
        end)
        if #candidates == 0 then break end
        local tos = room:askToChoosePlayers(player, {
          targets = candidates,
          min_num = 1,
          max_num = 1,
          skill_name = dushehebo.name,
          prompt = "#fei__dushehebo-target",
          cancelable = false,
        })
        if #tos > 0 then
          room:useCard {
            from = player,
            tos = tos,
            card = card,
            extraUse = true,
          }
        end
      end
    end
  end,
})

return dushehebo
