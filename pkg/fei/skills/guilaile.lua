local guilaile = fk.CreateSkill {
  name = "fei__guilaile",
}

local host_mark = "fei__guilaile_host"
local owner_mark = "fei__guilaile_owner"
local visible_mark = "@fei__minglingfuti"
local old_deputy_mark = "fei__guilaile_old_deputy"
local host_maxhp_mark = "fei__guilaile_host_maxhp"
local wangliang_maxhp_mark = "fei__guilaile_wangliang_maxhp"

Fk:loadTranslationTable {
  ["fei__guilaile"] = "鬼来了",
  [":fei__guilaile"] = "游戏开始时或出牌阶段，你可以作为一名其他角色的副将（各自发动技能）直到你或其弃置牌，其可以跳过任意阶段且其跳过的阶段你可以执行之或发动技能。",
  ["#fei__guilaile"] = "鬼来了：选择一名其他角色，作为其副将",
  ["#fei__guilaile-start"] = "鬼来了：你可以选择一名其他角色，作为其副将",
  ["#fei__guilaile-skip"] = "鬼来了：你可以跳过%arg",
  ["#fei__guilaile-follow"] = "鬼来了：%dest跳过了%arg，你可以执行此阶段或发动技能",
  ["fei__guilaile-phase"] = "执行此阶段",
  ["fei__guilaile-skill"] = "发动“鬼来了”",
  ["@fei__minglingfuti"] = "冥灵附体",
}

local function getHost(player)
  local id = player:getMark(host_mark)
  if type(id) ~= "number" or id == 0 then return end
  return player.room:getPlayerById(id)
end

local function setResting(room, player, resting)
  if resting then
    room:setPlayerRest(player, 999)
    room:setPlayerProperty(player, "dead", true)
    table.removeOne(room.alive_players, player)
  else
    room:setPlayerRest(player, 0)
    room:setPlayerProperty(player, "dead", false)
    table.insertIfNeed(room.alive_players, player)
  end
  room:updateAllLimitSkillUI(player)
end

local function setHp(room, player, hp, maxHp)
  room:setPlayerProperty(player, "maxHp", math.max(maxHp, 1))
  room:setPlayerProperty(player, "hp", math.min(hp, player.maxHp))
end

local function restoreDeputy(room, host)
  local old = host:getMark(old_deputy_mark)
  room:setPlayerMark(host, owner_mark, 0)
  room:setPlayerMark(host, visible_mark, 0)
  room:setPlayerMark(host, old_deputy_mark, 0)
  if type(old) == "string" and old ~= "" and Fk.generals[old] then
    room:changeHero(host, old, false, true, true, false, false)
  else
    room:removeDeputy(host, {
      change_max_hp = false,
      send_log = true,
    })
  end
end

local function detach(player)
  local room = player.room
  local host = getHost(player)
  local hostMaxHp = host and host:getMark(host_maxhp_mark) or 0
  local wangliangMaxHp = player:getMark(wangliang_maxhp_mark)
  local wasAttached = host ~= nil and type(wangliangMaxHp) == "number" and wangliangMaxHp > 0
  local lostHp = host and math.max(host.maxHp - host.hp, 0) or 0
  room:setPlayerMark(player, host_mark, 0)
  room:setPlayerMark(player, wangliang_maxhp_mark, 0)
  if host and host:getMark(owner_mark) == player.id then
    restoreDeputy(room, host)
    room:setPlayerMark(host, host_maxhp_mark, 0)
    if type(hostMaxHp) == "number" and hostMaxHp > 0 then
      setHp(room, host, hostMaxHp - lostHp, hostMaxHp)
    end
  end
  if type(wangliangMaxHp) == "number" and wangliangMaxHp > 0 then
    setHp(room, player, wangliangMaxHp - lostHp, wangliangMaxHp)
  end
  if wasAttached and (player.dead or player.rest > 0) then
    setResting(room, player, false)
  end
  if wasAttached then
    for _, p in ipairs({ host, player }) do
      if p and not p.dead and p.hp < 1 then
        room:enterDying { who = p }
      end
    end
  end
end

local function attach(player, host)
  if host == player then return end
  detach(player)
  local room = player.room
  local previous_owner = host:getMark(owner_mark)
  if type(previous_owner) == "number" and previous_owner ~= 0 then
    local previous = room:getPlayerById(previous_owner)
    if previous then room:setPlayerMark(previous, host_mark, 0) end
    restoreDeputy(room, host)
  end
  room:setPlayerMark(host, old_deputy_mark, host.deputyGeneral or "")
  room:setPlayerMark(host, host_maxhp_mark, host.maxHp)
  room:setPlayerMark(player, wangliang_maxhp_mark, player.maxHp)
  room:setPlayerMark(player, host_mark, host.id)
  room:setPlayerMark(host, owner_mark, player.id)
  room:setPlayerMark(host, visible_mark, 1)
  local mergedMaxHp = (host.maxHp + player.maxHp) // 2
  local mergedHp = (host.hp + player.hp) // 2
  -- 按国战换副将流程真正更换副将，使所有客户端都能看到副将状态；
  -- 随后移除宿主因此获得的魍魉技能，技能仍由魍魉本人各自发动。
  room:changeHero(host, "fei__wangliang", false, true, true, false, false)
  room:handleAddLoseSkills(host,
    "-fei__guilaile|-fei__mingzhihuo|-fei__mingzhiwu", nil, false)
  setHp(room, host, mergedHp, mergedMaxHp)
  if (host:getMark(host_maxhp_mark) + player:getMark(wangliang_maxhp_mark)) % 2 == 1 then
    room:addPlayerMark(host, "@!!fei_yinyangfish", 1)
    room:handleAddLoseSkills(host, "fei__yinyangfish_skill&")
  end
  setResting(room, player, true)
  local turn = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
  if turn and room.current == player then
    room:endTurn()
  end
end

local function chooseHost(player, cancelable, prompt)
  local targets = table.filter(player.room.alive_players, function(p)
    return p ~= player
  end)
  if #targets == 0 then return end
  local chosen = player.room:askToChoosePlayers(player, {
    targets = targets,
    min_num = 1,
    max_num = 1,
    prompt = prompt or "#fei__guilaile",
    skill_name = guilaile.name,
    cancelable = cancelable,
  })
  if #chosen > 0 then attach(player, chosen[1]) end
end

guilaile:addEffect("active", {
  anim_type = "support",
  prompt = "#fei__guilaile",
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  can_use = function(self, player)
    return player.phase == Player.Play and #Fk:currentRoom().alive_players > 1
  end,
  on_use = function(self, room, effect)
    attach(effect.from, effect.tos[1])
  end,
})

guilaile:addEffect(fk.GameStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(guilaile.name) and #player.room.alive_players > 1
  end,
  on_cost = function(self, event, target, player, data)
    local chosen = player.room:askToChoosePlayers(player, {
      targets = table.filter(player.room.alive_players, function(p) return p ~= player end),
      min_num = 1,
      max_num = 1,
      prompt = "#fei__guilaile-start",
      skill_name = guilaile.name,
      cancelable = true,
    })
    if #chosen > 0 then
      event:setCostData(self, { tos = chosen })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    attach(player, event:getCostData(self).tos[1])
  end,
})

guilaile:addEffect(fk.EventPhaseChanging, {
  global = true,
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    local host = getHost(player)
    return player:hasSkill(guilaile.name, true, true) and host and target == host and
      not data.skipped and data.phase ~= Player.NotActive
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(target, {
      skill_name = guilaile.name,
      prompt = "#fei__guilaile-skip:::" .. Util.PhaseStrMapper(data.phase),
    })
  end,
  on_use = function(self, event, target, player, data)
    data.skipped = true
    local choice = player.room:askToChoice(player, {
      choices = { "fei__guilaile-phase", "fei__guilaile-skill", "Cancel" },
      skill_name = guilaile.name,
      prompt = "#fei__guilaile-follow::" .. target.id .. ":" .. Util.PhaseStrMapper(data.phase),
    })
    if choice == "fei__guilaile-phase" then
      player:gainAnExtraPhase(data.phase, guilaile.name, false)
    elseif choice == "fei__guilaile-skill" then
      chooseHost(player, false, "#fei__guilaile")
    end
  end,
})

-- 休整中的魍魉只在执行主将跳过的额外阶段时临时恢复可操作状态；
-- 她始终不放回 alive_players，因此不会成为其他角色选牌时的目标。
guilaile:addEffect(fk.EventPhaseChanging, {
  global = true,
  mute = true,
  priority = 10,
  can_refresh = function(self, event, target, player, data)
    return target == player and data.reason == guilaile.name and getHost(player) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerProperty(player, "dead", false)
    player.room:updateAllLimitSkillUI(player)
  end,
})

guilaile:addEffect(fk.EventPhaseEnd, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and data.reason == guilaile.name and getHost(player) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerProperty(player, "dead", true)
    table.removeOne(player.room.alive_players, player)
    player.room:updateAllLimitSkillUI(player)
  end,
})

guilaile:addEffect(fk.EventPhaseSkipped, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and data.reason == guilaile.name and getHost(player) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerProperty(player, "dead", true)
    table.removeOne(player.room.alive_players, player)
    player.room:updateAllLimitSkillUI(player)
  end,
})

guilaile:addEffect(fk.AfterCardsMove, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    local host = getHost(player)
    if not host then return false end
    return table.find(data, function(move)
      return move.moveReason == fk.ReasonDiscard and
        (move.from == player or move.from == host) and #move.moveInfo > 0
    end)
  end,
  on_refresh = function(self, event, target, player, data)
    detach(player)
  end,
})

guilaile:addLoseEffect(function(self, player)
  detach(player)
end)

return guilaile
