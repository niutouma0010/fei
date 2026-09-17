local mobileUtil = require "packages.fei.util"
local centralArea = require "packages.fei.pkg.fei.skills.central_area"

local sanrenzuyeshi = fk.CreateSkill {
  name = "fei__sanrenzuyeshi",
  dynamic_desc = function(self, player, lang)
    local first = 1 + player:getMark("fei__sanrenzuyeshi_first")
    local obtain = 1 + player:getMark("fei__sanrenzuyeshi_obtain")
    local basic = 1 + player:getMark("fei__sanrenzuyeshi_basic")
    if first == 1 and obtain == 1 and basic == 1 then
      return Fk:translate(":fei__sanrenzuyeshi", lang)
    end
    return "fei__sanrenzuyeshi_inner:" .. first .. ":" .. obtain .. ":" .. basic
  end,
}

centralArea.registerSkill(sanrenzuyeshi.name)

local obtained_mark = "fei__sanrenzuyeshi_obtained-inhand"
local basic_state_mark = "fei__sanrenzuyeshi_basic_state"
local basic_slash_mark = "fei__sanrenzuyeshi_basic_slash_state"
local basic_active_mark = "fei__sanrenzuyeshi_basic_active"

local function getBasicNames()
  local names = table.simpleClone(Fk:getAllCardNames("b"))
  table.insertIfNeed(names, "analeptic")
  return names
end

local function getCentralInstantCards(room)
  return table.filter(centralArea.getCards(room), function(id)
    local card = Fk:getCardById(id)
    return card.type == Card.TypeBasic or card:isCommonTrick()
  end)
end

local function getUseEventsUntilCurrent(player)
  local room = player.room
  local current_use = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
  if not current_use then return {} end
  local uses = room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
    return e.data.from == player and e.id <= current_use.id
  end, Player.HistoryTurn)
  table.sort(uses, function(a, b) return a.id < b.id end)
  return uses
end

Fk:loadTranslationTable {
  ["fei__sanrenzuyeshi"] = "三刃卒业式",
  [":fei__sanrenzuyeshi"] = "当你本回合使用前1张牌后，你可以获得中央区的1张即时牌并明置，且失去之的回合结束时可视为使用1张基本牌；\n你以上述一者为【杀】结算后对应句数字+1。",
  [":fei__sanrenzuyeshi_inner"] = "当你本回合使用前{1}张牌后，你可以获得中央区的{2}张即时牌并明置，且失去之的回合结束时可视为使用{3}张基本牌；\n你以上述一者为【杀】结算后对应句数字+1。",

  ["#fei__sanrenzuyeshi-obtain"] = "三刃卒业式：当你本回合使用前%arg张牌后，你可以获得中央区的%arg2张即时牌并明置",
  ["#fei__sanrenzuyeshi-use"] = "三刃卒业式：且失去之的回合结束时可视为使用%arg张基本牌",
  ["#fei__sanrenzuyeshi-asked"] = "三刃卒业式：是否视为使用或打出【%arg】？",
  ["#fei__sanrenzuyeshi-asked-choice"] = "三刃卒业式：请选择要视为使用或打出的牌",
}

sanrenzuyeshi:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  priority = -1,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(sanrenzuyeshi.name) then return false end
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if not use_event or use_event.data.from ~= player then return false end
    use_event.data.extra_data = use_event.data.extra_data or {}
    if use_event.data.extra_data.fei__sanrenzuyeshi_obtain_checked then return false end
    local use_ids = Card:getIdList(use_event.data.card)
    local entered_discard = table.find(data, function(move)
      return move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonUse and
        table.find(move.moveInfo, function(info)
          return info.fromArea == Card.Processing and table.contains(use_ids, info.cardId)
        end) ~= nil
    end) ~= nil
    if not entered_discard then return false end
    use_event.data.extra_data.fei__sanrenzuyeshi_obtain_checked = true
    local limit = 1 + player:getMark("fei__sanrenzuyeshi_first")
    local n = 1 + player:getMark("fei__sanrenzuyeshi_obtain")
    local use_count = #getUseEventsUntilCurrent(player)
    if use_count == 0 or use_count > limit then return false end
    local cards = getCentralInstantCards(player.room)
    if #cards < n then return false end
    event:setCostData(self, { cards = cards, num = n, limit = limit })
    return true
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    local cards = room:askToCards(player, {
      min_num = cost.num,
      max_num = cost.num,
      include_equip = false,
      skill_name = sanrenzuyeshi.name,
      pattern = tostring(Exppattern { id = cost.cards }),
      prompt = "#fei__sanrenzuyeshi-obtain:::" .. cost.limit .. ":" .. cost.num,
      cancelable = true,
      expand_pile = cost.cards,
    })
    if #cards == cost.num then
      event:setCostData(self, { cards = cards, num = cost.num, limit = cost.limit })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    local central_cards = centralArea.getCards(room)
    local cards = table.filter(cost.cards, function(id)
      return table.contains(central_cards, id)
    end)
    if #cards ~= cost.num then return end
    local all_slash = table.every(cards, function(id)
      return Fk:getCardById(id).trueName == "slash"
    end)
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey,
      sanrenzuyeshi.name, nil, true, player)
    for _, id in ipairs(cards) do
      if room:getCardOwner(id) == player and room:getCardArea(id) == Card.PlayerHand then
        room:setCardMark(Fk:getCardById(id), obtained_mark, 1)
      end
    end
    mobileUtil.displayCards(player, cards)
    if all_slash then
      room:addPlayerMark(player, "fei__sanrenzuyeshi_obtain", 1)
    end
  end,
})

sanrenzuyeshi:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if not player:hasSkill(sanrenzuyeshi.name, true) then return false end
    return table.find(data, function(move)
      if move.from ~= player or (move.to == player and move.toArea == Card.PlayerHand) then
        return false
      end
      return table.find(move.moveInfo, function(info)
        return info.fromArea == Card.PlayerHand and
          info.beforeCard:getMark(obtained_mark) > 0
      end) ~= nil
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "fei__sanrenzuyeshi_lost-turn", 1)
  end,
})

local function consumeBasicState(player, card)
  local room = player.room
  local left = player:getMark(basic_state_mark)
  if left < 1 then return end
  if card.trueName ~= "slash" then
    room:setPlayerMark(player, basic_slash_mark, 0)
  end
  left = left - 1
  room:setPlayerMark(player, basic_state_mark, left)
end

local function finishBasicStateCard(player)
  if player:getMark(basic_state_mark) == 0 and
    player:getMark(basic_slash_mark) > 0 and not player.dead then
    player.room:addPlayerMark(player, "fei__sanrenzuyeshi_basic", 1)
    player.room:setPlayerMark(player, basic_slash_mark, 0)
  end
end

local asked_basic_names = { "slash", "jink", "peach", "analeptic" }

local function getAskedBasicNames(event, player, data)
  if player:getMark(basic_active_mark) == 0 or
    player:getMark(basic_state_mark) == 0 then return {} end
  local pattern = Exppattern:Parse(data.pattern)
  return table.filter(asked_basic_names, function(name)
    local card = Fk:cloneCard(name)
    if not pattern:match(card) then return false end
    if event == fk.AskForCardResponse then
      return not player:prohibitResponse(card)
    end
    return not player:prohibitUse(card)
  end)
end

local asked_basic_spec = {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(sanrenzuyeshi.name, true) and
      #getAskedBasicNames(event, player, data) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = getAskedBasicNames(event, player, data)
    if #choices == 0 then return false end
    local name = choices[1]
    if #choices > 1 then
      name = room:askToChoice(player, {
        choices = choices,
        skill_name = sanrenzuyeshi.name,
        prompt = "#fei__sanrenzuyeshi-asked-choice",
      })
    end
    if not room:askToSkillInvoke(player, {
      skill_name = sanrenzuyeshi.name,
      prompt = "#fei__sanrenzuyeshi-asked:::" .. name,
    }) then
      return false
    end
    event:setCostData(self, name)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local name = event:getCostData(self)
    local card = Fk:cloneCard(name)
    card.skillName = sanrenzuyeshi.name
    consumeBasicState(player, card)
    local result = {
      from = player,
      card = card,
    }
    if event == fk.AskForCardUse then
      result.tos = {}
      local extra_data = data.extraData or {}
      local target_ids = extra_data.fix_targets or extra_data.must_targets or {}
      for _, id in ipairs(target_ids) do
        local to = room:getPlayerById(id)
        if to then table.insert(result.tos, to) end
      end
    end
    data.result = result
    return true
  end,
}

sanrenzuyeshi:addEffect(fk.AskForCardUse, asked_basic_spec)
sanrenzuyeshi:addEffect(fk.AskForCardResponse, asked_basic_spec)

sanrenzuyeshi:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(sanrenzuyeshi.name) and
      player:getMark("fei__sanrenzuyeshi_lost-turn") > 0) then
      return false
    end
    return table.find(getBasicNames(), function(name)
      return #Fk:cloneCard(name):getAvailableTargets(player, {
        bypass_times = true,
        extraUse = true,
      }) > 0
    end) ~= nil
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 1 + player:getMark("fei__sanrenzuyeshi_basic")
    room:setPlayerMark(player, basic_state_mark, n)
    room:setPlayerMark(player, basic_slash_mark, 1)
    room:setPlayerMark(player, basic_active_mark, 1)
    while player:getMark(basic_state_mark) > 0 and not player.dead do
      local use = room:askToUseVirtualCard(player, {
        name = getBasicNames(),
        skill_name = sanrenzuyeshi.name,
        prompt = "#fei__sanrenzuyeshi-use:::" .. n,
        cancelable = true,
        skip = true,
        extra_data = {
          bypass_times = true,
          extraUse = true,
        },
      })
      if not use then break end
      consumeBasicState(player, use.card)
      room:useCard(use)
      finishBasicStateCard(player)
    end
    room:setPlayerMark(player, basic_active_mark, 0)
    room:setPlayerMark(player, basic_state_mark, 0)
    room:setPlayerMark(player, basic_slash_mark, 0)
  end,
})

sanrenzuyeshi:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(sanrenzuyeshi.name, true) then return false end
    local limit = 1 + player:getMark("fei__sanrenzuyeshi_first")
    local uses = getUseEventsUntilCurrent(player)
    return #uses == limit and table.every(uses, function(e)
      return e.data.card.trueName == "slash"
    end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "fei__sanrenzuyeshi_first", 1)
  end,
})

return sanrenzuyeshi
