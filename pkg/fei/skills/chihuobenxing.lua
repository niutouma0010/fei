local chihuobenxing = fk.CreateSkill {
  name = "fei__chihuobenxing",
}

Fk:loadTranslationTable {
  ["fei__chihuobenxing"] = "吃货本性",
  [":fei__chihuobenxing"] = "你可以发动“狂骨”，且当你发动其他技能、使用【酒】或弃置【杀】时亦可改为发动之。",

  ["#fei__chihuobenxing-kuanggu"] = "吃货本性：是否发动“狂骨”，回复1点体力？",
}

local function askKuanggu(player)
  if player.dead or not player:isWounded() then return false end
  return player.room:askToSkillInvoke(player, {
    skill_name = chihuobenxing.name,
    prompt = "#fei__chihuobenxing-kuanggu",
  })
end

local function useKuanggu(player)
  player.room:notifySkillInvoked(player, "kuanggu", "support")
  player:broadcastSkillInvoke("kuanggu")
  player.room:recover {
    who = player,
    num = 1,
    recoverBy = player,
    skillName = "kuanggu",
  }
end

chihuobenxing:addEffect(fk.AfterSkillEffect, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(chihuobenxing.name) or
      player.dead or not player:isWounded() or data.skill.is_delay_effect then
      return false
    end
    local skeleton = data.skill:getSkeleton()
    if not skeleton or skeleton.name == chihuobenxing.name or skeleton.name == "kuanggu" then
      return false
    end
    return table.contains(player:getSkillNameList(), skeleton.name)
  end,
  on_cost = function(self, event, target, player, data)
    return askKuanggu(player)
  end,
  on_use = function(self, event, target, player, data)
    useKuanggu(player)
  end,
})

chihuobenxing:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chihuobenxing.name) and
      not player.dead and player:isWounded() and data.card.trueName == "analeptic"
  end,
  on_cost = function(self, event, target, player, data)
    return askKuanggu(player)
  end,
  on_use = function(self, event, target, player, data)
    useKuanggu(player)
  end,
})

chihuobenxing:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(chihuobenxing.name) or player.dead or not player:isWounded() then
      return false
    end
    return table.find(data, function(move)
      return move.from == player and move.toArea == Card.DiscardPile and
        move.moveReason == fk.ReasonDiscard and table.find(move.moveInfo, function(info)
          return Fk:getCardById(info.cardId, true).trueName == "slash"
        end)
    end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    return askKuanggu(player)
  end,
  on_use = function(self, event, target, player, data)
    useKuanggu(player)
  end,
})

return chihuobenxing
