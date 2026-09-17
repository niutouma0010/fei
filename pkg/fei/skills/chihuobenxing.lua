local chihuobenxing = fk.CreateSkill {
  name = "fei__chihuobenxing",
}

Fk:loadTranslationTable {
  ["fei__chihuobenxing"] = "吃货本性",
  [":fei__chihuobenxing"] = "你可以发动“狂骨”，且当你发动其他技能、使用【酒】或弃置【杀】时亦可改为发动之。",

  ["#fei__chihuobenxing-kuanggu"] = "吃货本性：请选择是否发动“狂骨”",
}

local function askKuanggu(player)
  if player.dead then return nil end
  local choices = { "draw1", "Cancel" }
  if player:isWounded() then
    table.insert(choices, 2, "recover")
  end
  local choice = player.room:askToChoice(player, {
    choices = choices,
    skill_name = chihuobenxing.name,
    prompt = "#fei__chihuobenxing-kuanggu",
  })
  return choice ~= "Cancel" and choice or nil
end

local function useKuanggu(player, choice)
  if choice == "recover" then
    player.room:recover {
      who = player,
      num = 1,
      recoverBy = player,
      skillName = chihuobenxing.name,
    }
  elseif choice == "draw1" then
    player:drawCards(1, chihuobenxing.name)
  end
end

local function kuangguCost(self, event, target, player, data)
  local choice = askKuanggu(player)
  if choice then
    event:setCostData(self, { choice = choice })
    return true
  end
end

local function kuangguUse(self, event, target, player, data)
  useKuanggu(player, event:getCostData(self).choice)
end

local function discardedSlashNum(player, data)
  local n = 0
  for _, move in ipairs(data) do
    if move.from == player and move.toArea == Card.DiscardPile and
      move.moveReason == fk.ReasonDiscard then
      for _, info in ipairs(move.moveInfo) do
        if Fk:getCardById(info.cardId, true).trueName == "slash" then
          n = n + 1
        end
      end
    end
  end
  return n
end

-- “狂骨”原本的发动时机：每造成1点伤害均可发动一次。
chihuobenxing:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chihuobenxing.name) and
      not player.dead and (data.extra_data or {}).fei__chihuobenxing_kuanggu
  end,
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  on_cost = kuangguCost,
  on_use = kuangguUse,
})

chihuobenxing:addEffect(fk.BeforeHpChanged, {
  can_refresh = function(self, event, target, player, data)
    return data.damageEvent and data.damageEvent.from == player and
      player:hasSkill(chihuobenxing.name) and player:compareDistance(target, 2, "<")
  end,
  on_refresh = function(self, event, target, player, data)
    data.damageEvent.extra_data = data.damageEvent.extra_data or {}
    data.damageEvent.extra_data.fei__chihuobenxing_kuanggu = true
  end,
})

-- 额外时机一：发动其他技能时，可改为发动“狂骨”并取消原技能效果。
chihuobenxing:addEffect(fk.SkillEffect, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(chihuobenxing.name) or
      player.dead or data.skill.is_delay_effect then
      return false
    end
    local skeleton = data.skill:getSkeleton()
    return skeleton and skeleton.name ~= chihuobenxing.name and
      table.contains(player:getSkillNameList(), skeleton.name)
  end,
  on_cost = kuangguCost,
  on_use = function(self, event, target, player, data)
    data.prevented = true
    kuangguUse(self, event, target, player, data)
  end,
})

-- 额外时机二：使用【酒】时，可改为发动“狂骨”；牌仍被使用，但不执行【酒】效果。
chihuobenxing:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chihuobenxing.name) and
      not player.dead and data.card.trueName == "analeptic"
  end,
  on_cost = kuangguCost,
  on_use = function(self, event, target, player, data)
    data.nullified = true
    kuangguUse(self, event, target, player, data)
  end,
})

-- 额外时机三：弃置【杀】前，可改为发动“狂骨”并取消弃置该【杀】。
chihuobenxing:addEffect(fk.BeforeCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chihuobenxing.name) and not player.dead and
      discardedSlashNum(player, data) > 0
  end,
  on_cost = kuangguCost,
  on_use = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player and move.toArea == Card.DiscardPile and
        move.moveReason == fk.ReasonDiscard then
        move.moveInfo = table.filter(move.moveInfo, function(info)
          return Fk:getCardById(info.cardId, true).trueName ~= "slash"
        end)
      end
    end
    kuangguUse(self, event, target, player, data)
  end,
})

return chihuobenxing
