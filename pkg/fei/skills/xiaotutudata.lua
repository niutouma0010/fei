local xiaotutudata = fk.CreateSkill {
  name = "fei__xiaotutudata",
}

local main_phases = { Player.Judge, Player.Draw, Player.Play, Player.Discard }
local phase_mark = "fei__xiaotutudata_phases-round"
local pending_mark = "fei__xiaotutudata_pending"

Fk:loadTranslationTable {
  ["fei__xiaotutudata"] = "小兔兔打他",
  [":fei__xiaotutudata"] = "当你被【杀】指定为目标后，你可以将之改为【决斗】，若你赢，则你可以于当前回合结束后执行一个你本轮未执行过的主要阶段。",
  ["#fei__xiaotutudata-invoke"] = "小兔兔打他：是否令 %src 对你使用的【杀】改为【决斗】？",
  ["#fei__xiaotutudata-phase"] = "小兔兔打他：选择一个本轮未执行过的主要阶段执行",
}

xiaotutudata:addEffect(fk.EventPhaseStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(main_phases, player.phase)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMark(player, phase_mark, player.phase)
  end,
})

xiaotutudata:addEffect(fk.TargetConfirmed, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiaotutudata.name) and
      data.card.trueName == "slash" and data.from and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = xiaotutudata.name,
      prompt = "#fei__xiaotutudata-invoke:" .. data.from.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local original = data.card
    local duel = Fk:cloneCard("duel", original.suit, original.number)
    duel:addSubcards(Card:getIdList(original))
    duel.skillName = xiaotutudata.name
    data.card = duel
    data.use.card = duel
    data.use.extra_data = data.use.extra_data or {}
    data.use.extra_data.fei__xiaotutudata_target = player.id
    data.use.extra_data.fei__xiaotutudata_from = data.from.id
  end,
})

xiaotutudata:addEffect(fk.Damage, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or data.from ~= player or player.dead or not data.to then
      return false
    end
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not use_event then return false end
    local extra = use_event.data.extra_data or {}
    return extra.fei__xiaotutudata_target == player.id and
      extra.fei__xiaotutudata_from == data.to.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, pending_mark, 1)
  end,
})

xiaotutudata:addEffect(fk.TurnEnd, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark(pending_mark) > 0 and not player.dead
  end,
  on_cost = function(self, event, target, player, data)
    local phases = table.filter(main_phases, function(phase)
      return not table.contains(player:getTableMark(phase_mark), phase)
    end)
    player.room:setPlayerMark(player, pending_mark, 0)
    if #phases == 0 then return false end
    local choices = table.map(phases, Util.PhaseStrMapper)
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = xiaotutudata.name,
      prompt = "#fei__xiaotutudata-phase",
      cancelable = true,
    })
    if choice == "Cancel" then return false end
    event:setCostData(self, phases[table.indexOf(choices, choice)])
    return true
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraPhase(event:getCostData(self), xiaotutudata.name, false)
  end,
})

xiaotutudata:addEffect(fk.RoundEnd, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark(pending_mark) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, pending_mark, 0)
  end,
})

return xiaotutudata
