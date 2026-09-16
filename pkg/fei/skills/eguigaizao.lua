local eguiguizao = fk.CreateSkill {
  name = "fei__eguigaizao",
}

Fk:loadTranslationTable {
  ["fei__eguigaizao"] = "恶鬼改造",
  [":fei__eguigaizao"] = "轮次技，一名角色的回合结束时，你可以令你或其执行一个额外回合并交换体力牌直到回合结束，然后你摸该回合其被牌指定次数张牌。",
  ["#fei__eguigaizao-choose"] = "恶鬼改造：你可以令你或 %dest 执行一个额外回合",
}

local function swapHealthCards(room, first, second)
  if not first or not second or first == second then return end
  local first_hp, first_max = first.hp, first.maxHp
  local second_hp, second_max = second.hp, second.maxHp
  room:setPlayerProperty(first, "maxHp", second_max)
  room:setPlayerProperty(second, "maxHp", first_max)
  room:setPlayerProperty(first, "hp", second_hp)
  room:setPlayerProperty(second, "hp", first_hp)
end

eguiguizao:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(eguiguizao.name) and not target.dead and
      player:usedSkillTimes(eguiguizao.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local choices = { player }
    if target ~= player then table.insert(choices, target) end
    local tos = player.room:askToChoosePlayers(player, {
      targets = choices,
      min_num = 1,
      max_num = 1,
      skill_name = eguiguizao.name,
      prompt = "#fei__eguigaizao-choose::" .. target.id,
      cancelable = true,
    })
    if #tos == 0 then return false end
    event:setCostData(self, { tos = tos })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local executor = event:getCostData(self).tos[1]
    executor:gainAnExtraTurn(true, eguiguizao.name, nil, {
      fei__eguigaizao_owner = player.id,
      fei__eguigaizao_other = target.id,
    })
  end,
})

eguiguizao:addEffect(fk.TurnStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    local extra = data.extra_data or {}
    return data.reason == eguiguizao.name and
      extra.fei__eguigaizao_owner == player.id and
      not extra.fei__eguigaizao_swapped
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local extra = data.extra_data
    local other = player.room:getPlayerById(extra.fei__eguigaizao_other)
    if other then
      swapHealthCards(player.room, player, other)
      extra.fei__eguigaizao_swapped = true
    end
  end,
})

eguiguizao:addEffect(fk.TurnEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    local extra = data.extra_data or {}
    return data.reason == eguiguizao.name and
      extra.fei__eguigaizao_owner == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local extra = data.extra_data
    local other = room:getPlayerById(extra.fei__eguigaizao_other)
    if extra.fei__eguigaizao_swapped and other then
      swapHealthCards(room, player, other)
    end

    if player.dead or not other then return end
    local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      return table.contains(e.data.tos or {}, other)
    end, Player.HistoryTurn)
    if n > 0 then
      player:drawCards(n, eguiguizao.name)
    end
  end,
})

return eguiguizao
