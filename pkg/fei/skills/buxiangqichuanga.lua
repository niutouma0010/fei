local buxiangqichuanga = fk.CreateSkill {
  name = "fei__buxiangqichuanga",
}

local U = require "packages.fei.util"

local limited_mark = "fei__buxiangqichuanga_limited-round"
local limited_visible_mark = "@fei__buxiangqichuanga_limited-round"
local invalid_mark = "fei__buxiangqichuanga_invalid"
local main_phases = { Player.Judge, Player.Draw, Player.Play, Player.Discard }

Fk:loadTranslationTable {
  ["fei__buxiangqichuanga"] = "不想起床啊",
  [":fei__buxiangqichuanga"] = "你可以视为使用或打出一张无次数和距离限制的基本牌，或跳过主要阶段，你发动一者后此技能本轮改为限定技直到亦放弃发动另一者。",
  ["@fei__buxiangqichuanga_limited-round"] = "限定技",
  ["#fei__buxiangqichuanga"] = "不想起床啊：选择视为使用的基本牌",
  ["#fei__buxiangqichuanga-use"] = "不想起床啊：视为使用%arg",
  ["#fei__buxiangqichuanga-response"] = "不想起床啊：选择是否视为使用或打出一张基本牌",
  ["#fei__buxiangqichuanga-skip"] = "不想起床啊：是否跳过你的%arg？",
}

local function recordActivation(player, branch)
  local room = player.room
  if player:getMark(limited_mark) == 0 then
    room:setPlayerMark(player, limited_mark, branch)
    room:setPlayerMark(player, limited_visible_mark, 1)
  else
    room:setPlayerMark(player, invalid_mark, 1)
  end
end

local function recordRefusal(player, branch)
  local room = player.room
  local state = player:getMark(limited_mark)
  if (branch == "basic" and state == "phase") or
    (branch == "phase" and state == "basic") then
    room:setPlayerMark(player, limited_mark, 0)
    room:setPlayerMark(player, limited_visible_mark, 0)
  end
end

local function clearLimitedStateIfInvalid(player)
  if player:getMark(invalid_mark) == 0 then return end
  local room = player.room
  room:setPlayerMark(player, limited_mark, 0)
  room:setPlayerMark(player, limited_visible_mark, 0)
end

local function allBasicNames()
  local names = Fk:getAllCardNames("b")
  table.insertIfNeed(names, "analeptic")
  return names
end

local function playableNames(player)
  return table.filter(allBasicNames(), function(name)
    local card = Fk:cloneCard(name)
    return not player:prohibitUse(card) and
      #card:getAvailableTargets(player, {
        bypass_times = true,
        bypass_distances = true,
      }) > 0
  end)
end

local function askedNames(event, player, data)
  local pattern = Exppattern:Parse(data.pattern)
  return table.filter(allBasicNames(), function(name)
    local card = Fk:cloneCard(name)
    if not pattern:match(card) then return false end
    if event == fk.AskForCardResponse then
      return not player:prohibitResponse(card)
    end
    return not player:prohibitUse(card)
  end)
end

buxiangqichuanga:addEffect("active", {
  anim_type = "special",
  prompt = "#fei__buxiangqichuanga",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return #playableNames(player) > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local names = playableNames(player)
    if #names == 0 then return end
    local name = U.askForChooseCardNames(room, player, names, 1, 1,
      buxiangqichuanga.name, "#fei__buxiangqichuanga", allBasicNames(), true)[1]
    if not name then
      recordRefusal(player, "basic")
      return
    end
    local use = room:askToUseVirtualCard(player, {
      name = name,
      skill_name = buxiangqichuanga.name,
      prompt = "#fei__buxiangqichuanga-use:::" .. name,
      cancelable = true,
      skip = true,
      extra_data = {
        bypass_times = true,
        bypass_distances = true,
        extraUse = true,
      },
    })
    if use then
      recordActivation(player, "basic")
      room:useCard(use)
      clearLimitedStateIfInvalid(player)
    else
      recordRefusal(player, "basic")
    end
  end,
})

local asked_spec = {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(buxiangqichuanga.name) and
      #askedNames(event, player, data) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local names = askedNames(event, player, data)
    local name = U.askForChooseCardNames(player.room, player, names, 1, 1,
      buxiangqichuanga.name, "#fei__buxiangqichuanga-response", allBasicNames(), true)[1]
    if not name then
      recordRefusal(player, "basic")
      return false
    end
    event:setCostData(self, name)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local name = event:getCostData(self)
    local card = Fk:cloneCard(name)
    card.skillName = buxiangqichuanga.name
    recordActivation(player, "basic")
    local result = { from = player, card = card }
    if event == fk.AskForCardUse then
      result.tos = {}
      local extra = data.extraData or {}
      for _, id in ipairs(extra.fix_targets or extra.must_targets or {}) do
        local to = player.room:getPlayerById(id)
        if to then table.insert(result.tos, to) end
      end
    end
    data.result = result
    clearLimitedStateIfInvalid(player)
    return true
  end,
}

buxiangqichuanga:addEffect(fk.AskForCardUse, asked_spec)
buxiangqichuanga:addEffect(fk.AskForCardResponse, asked_spec)

buxiangqichuanga:addEffect(fk.EventPhaseChanging, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(buxiangqichuanga.name) and
      table.contains(main_phases, data.phase) and not data.skipped
  end,
  on_cost = function(self, event, target, player, data)
    local yes = player.room:askToSkillInvoke(player, {
      skill_name = buxiangqichuanga.name,
      prompt = "#fei__buxiangqichuanga-skip:::" .. Util.PhaseStrMapper(data.phase),
    })
    if not yes then
      recordRefusal(player, "phase")
    end
    return yes
  end,
  on_use = function(self, event, target, player, data)
    recordActivation(player, "phase")
    data.skipped = true
    clearLimitedStateIfInvalid(player)
  end,
})

buxiangqichuanga:addEffect("invalidity", {
  recheck_invalidity = true,
  invalidity_func = function(self, from, skill)
    return from:getMark(invalid_mark) > 0 and
      skill.name == buxiangqichuanga.name and skill:isPlayerSkill(from, true)
  end,
})

return buxiangqichuanga
