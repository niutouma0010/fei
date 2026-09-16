local leidianshaonv = fk.CreateSkill {
  name = "fei__leidianshaonv",
  dynamic_desc = function(self, player, lang)
    local changed = player:getMark("fei__leidianshaonv_changed")
    if changed == "thunder__slash" then
      return Fk:translate(":fei__leidianshaonv1", lang)
    elseif changed == "jink" then
      return Fk:translate(":fei__leidianshaonv2", lang)
    end
    return Fk:translate(":fei__leidianshaonv", lang)
  end,
}

local U = require "packages.utility.utility"

local changed_mark = "fei__leidianshaonv_changed"
local source_mark = "fei__leidianshaonv_source"
local initial_names = { "thunder__slash", "jink" }

Fk:loadTranslationTable {
  ["fei__leidianshaonv"] = "雷电少女",
  [":fei__leidianshaonv"] = "你可以将你区域内的一张牌当雷【杀】或【闪】使用或打出。以此法使用或打出牌后，你摸一张牌，然后将此牌名改为【闪电】直到你下次获得牌。",
  [":fei__leidianshaonv1"] = "你可以将你区域内的一张牌当【闪电】或【闪】使用或打出。以此法使用或打出牌后，你摸一张牌，然后将此牌名改为【闪电】直到你下次获得牌。",
  [":fei__leidianshaonv2"] = "你可以将你区域内的一张牌当雷【杀】或【闪电】使用或打出。以此法使用或打出牌后，你摸一张牌，然后将此牌名改为【闪电】直到你下次获得牌。",

  ["#fei__leidianshaonv"] = "雷电少女：选择要转化的牌名",
  ["#fei__leidianshaonv-use"] = "雷电少女：将你区域内的一张牌当%arg使用",
  ["#fei__leidianshaonv-response"] = "雷电少女：是否将你区域内的一张牌当%arg使用或打出？",
  ["#fei__leidianshaonv-card"] = "雷电少女：选择一张牌当%arg使用或打出",
}

local function currentNames(player)
  local changed = player:getMark(changed_mark)
  if changed == "thunder__slash" then
    return { "lightning", "jink" }
  elseif changed == "jink" then
    return { "thunder__slash", "lightning" }
  end
  return table.simpleClone(initial_names)
end

-- “闪电”只是被替换后的显示牌名；记录它原本占据的是哪个牌名位置。
local function sourceName(player, name)
  if name == "lightning" then
    local changed = player:getMark(changed_mark)
    if changed == "thunder__slash" or changed == "jink" then
      return changed
    end
  end
  return name
end

local function areaCards(player)
  return player:getCardIds("hej")
end

local function canUseName(player, name)
  local card = Fk:cloneCard(name)
  if player:prohibitUse(card) then return false end
  return #card:getAvailableTargets(player, {
    bypass_times = false,
    extraUse = false,
  }) > 0
end

local function playableNames(player)
  return table.filter(currentNames(player), function(name)
    return canUseName(player, name)
  end)
end

local function askedNames(event, player, data)
  if #areaCards(player) == 0 then return {} end
  local pattern = Exppattern:Parse(data.pattern)
  return table.filter(currentNames(player), function(name)
    local card = Fk:cloneCard(name)
    if not pattern:match(card) then return false end
    if event == fk.AskForCardResponse then
      return not player:prohibitResponse(card)
    end
    return not player:prohibitUse(card)
  end)
end

local function askName(room, player, choices, prompt, cancelable)
  return U.askForChooseCardNames(room, player, choices, 1, 1,
    leidianshaonv.name, prompt, currentNames(player), cancelable)[1]
end

local function markConversion(player, card, name)
  card.skillName = leidianshaonv.name
  card:setMark(source_mark, sourceName(player, name))
end

leidianshaonv:addEffect("active", {
  anim_type = "offensive",
  prompt = "#fei__leidianshaonv",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return #areaCards(player) > 0 and #playableNames(player) > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local choices = playableNames(player)
    if #choices == 0 then return end

    -- 与“炎之拳”使用同一种牌名卡图选择窗口。
    local name = askName(room, player, choices, "#fei__leidianshaonv", false)
    local use = room:askToUseVirtualCard(player, {
      name = name,
      skill_name = leidianshaonv.name,
      prompt = "#fei__leidianshaonv-use:::" .. name,
      cancelable = true,
      skip = true,
      card_filter = {
        cards = areaCards(player),
        n = 1,
        pattern = ".",
      },
      extra_data = {
        bypass_times = false,
        extraUse = false,
      },
    })
    if use then
      markConversion(player, use.card, name)
      room:useCard(use)
    end
  end,
})

local asked_spec = {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(leidianshaonv.name, true) and
      #askedNames(event, player, data) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local choices = askedNames(event, player, data)
    if #choices == 0 then return false end
    local name = askName(player.room, player, choices,
      "#fei__leidianshaonv-response", true)
    if not name then return false end
    event:setCostData(self, name)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local name = event:getCostData(self)
    local cards = room:askToChooseCards(player, {
      target = player,
      min = 1,
      max = 1,
      flag = "hej",
      skill_name = leidianshaonv.name,
      prompt = "#fei__leidianshaonv-card:::" .. name,
    })
    if #cards == 0 then return false end

    local original = Fk:getCardById(cards[1])
    local card = Fk:cloneCard(name, original.suit, original.number)
    card:addSubcard(cards[1])
    markConversion(player, card, name)

    local result = {
      from = player,
      card = card,
    }
    if event == fk.AskForCardUse then
      result.tos = {}
      local extra_data = data.extraData or {}
      for _, id in ipairs(extra_data.fix_targets or extra_data.must_targets or {}) do
        local to = room:getPlayerById(id)
        if to then table.insert(result.tos, to) end
      end
    end
    data.result = result
    return true
  end,
}

leidianshaonv:addEffect(fk.AskForCardUse, asked_spec)
leidianshaonv:addEffect(fk.AskForCardResponse, asked_spec)

local finish_spec = {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(leidianshaonv.name, true) or not data.card then
      return false
    end
    local source = data.card:getMark(source_mark)
    return data.card.skillName == leidianshaonv.name and
      (source == "thunder__slash" or source == "jink")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local source = data.card:getMark(source_mark)
    player.room:drawCards(player, 1, leidianshaonv.name)
    if not player.dead then
      -- 摸牌会先清除旧状态，再把本次实际使用的牌名位置改为【闪电】。
      player.room:setPlayerMark(player, changed_mark, source)
    end
  end,
}

leidianshaonv:addEffect(fk.CardUseFinished, finish_spec)
leidianshaonv:addEffect(fk.CardRespondFinished, finish_spec)

leidianshaonv:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:getMark(changed_mark) == 0 then return false end
    return table.find(data, function(move)
      if move.to ~= player or move.toArea ~= Card.PlayerHand then return false end
      return table.find(move.moveInfo, function(info)
        return info.fromArea ~= Card.PlayerHand or move.from ~= player
      end) ~= nil
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, changed_mark, 0)
  end,
})

return leidianshaonv
