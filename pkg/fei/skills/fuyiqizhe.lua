local fuyiqizhe = fk.CreateSkill {
  name = "fei__fuyiqizhe",
}

local U = require "packages.fei.util"
local used_mark = "fei__fuyiqizhe_used-round"
local child_mark = "@fei__fuyiqizhe_child"
local child_owner_mark = "fei__fuyiqizhe_child_owner"
local choices = { "fei__unexpectation", "fei__bogus_flower", "fei__underhanding" }

Fk:loadTranslationTable {
  ["fei__fuyiqizhe"] = "夫弈棋者",
  [":fei__fuyiqizhe"] = "每轮每牌名限一次，每回合结束时，你可以展示一张牌，然后视为将之当【出其不意】/【树上开花】/【瞒天过海】中的若干张依次令一名角色使用，展示牌因此：进入弃牌堆后，你与失去者各失去1点体力；为所有角色可见后，你重置此技能。",
  ["#fei__fuyiqizhe-owner"] = "夫弈棋者：选择一名有牌的角色",
  ["#fei__fuyiqizhe-card"] = "夫弈棋者：选择并展示 %dest 区域内的一张牌",
  ["#fei__fuyiqizhe-names"] = "夫弈棋者：选择要依次视为使用的牌名",
  ["#fei__fuyiqizhe-user"] = "夫弈棋者：选择一名角色，令其使用【%arg】",
  ["#fei__fuyiqizhe-target"] = "夫弈棋者：为 %src 使用的【%arg】选择目标",
  [child_mark] = "子",
}

local function isChildOf(id, player)
  return Fk:getCardById(id, true):getMark(child_owner_mark) == player.id
end

local function clearChildren(room, player)
  for _, id in ipairs(Fk:getAllCardIds()) do
    if isChildOf(id, player) then
      local card = Fk:getCardById(id, true)
      room:setCardMark(card, child_mark, 0)
      room:setCardMark(card, child_owner_mark, 0)
    end
  end
end

local function resetSkill(room, player)
  room:setPlayerMark(player, used_mark, 0)
  clearChildren(room, player)
end

local function causalUse(room, player)
  local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
  if not use_event then return end
  local use = use_event.data
  local extra = use.extra_data or {}
  if extra.fei__fuyiqizhe_owner == player.id and
    table.contains(choices, use.card.name) then
    return use
  end
end

local function availableNames(player)
  local used = player:getTableMark(used_mark)
  return table.filter(choices, function(name)
    return not table.contains(used, name) and Fk.all_card_types[name] ~= nil
  end)
end

local function canUseName(player, name)
  local card = Fk:cloneCard(name)
  card.skillName = fuyiqizhe.name
  return not player:prohibitUse(card) and player:canUse(card) and
    #card:getAvailableTargets(player) > 0
end

local function chooseTargets(room, chooser, user, card)
  if card.name == "fei__bogus_flower" then
    return { user }
  end
  local targets = table.filter(room.alive_players, function(p)
    return user:canUseTo(card, p)
  end)
  if #targets == 0 then return end
  return room:askToChoosePlayers(chooser, {
    targets = targets,
    min_num = 1,
    max_num = 1,
    prompt = "#fei__fuyiqizhe-target:" .. user.id .. "::" .. card.name,
    skill_name = fuyiqizhe.name,
    cancelable = false,
  })
end

fuyiqizhe:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fuyiqizhe.name) and #availableNames(player) > 0 and
      table.find(player.room.alive_players, function(p) return not p:isAllNude() end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local owners = table.filter(room.alive_players, function(p) return not p:isAllNude() end)
    local selected = room:askToChoosePlayers(player, {
      targets = owners,
      min_num = 1,
      max_num = 1,
      prompt = "#fei__fuyiqizhe-owner",
      skill_name = fuyiqizhe.name,
      cancelable = true,
    })
    if #selected == 0 then return false end
    local owner = selected[1]
    local id = room:askToChooseCard(player, {
      target = owner,
      flag = "hej",
      skill_name = fuyiqizhe.name,
      prompt = "#fei__fuyiqizhe-card::" .. owner.id,
    })
    if not id then return false end
    event:setCostData(self, { owner = owner, card = id })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    local owner, id = cost.owner, cost.card
    if room:getCardOwner(id) ~= owner or
      not table.contains(owner:getCardIds("hej"), id) then return end

    owner:showCards({ id }, player)
    room:setCardMark(Fk:getCardById(id, true), child_mark, "")
    room:setCardMark(Fk:getCardById(id, true), child_owner_mark, player.id)
    local names = availableNames(player)
    if #names == 0 then return end
    names = U.askForChooseCardNames(room, player, names, 1, #names,
      fuyiqizhe.name, "#fei__fuyiqizhe-names", choices, false)

    for _, name in ipairs(names) do
      if player.dead then break end
      local users = table.filter(room.alive_players, function(p)
        return canUseName(p, name)
      end)
      if #users > 0 then
        local chosen = room:askToChoosePlayers(player, {
          targets = users,
          min_num = 1,
          max_num = 1,
          prompt = "#fei__fuyiqizhe-user:::" .. name,
          skill_name = fuyiqizhe.name,
          cancelable = false,
        })
        local user = chosen[1]
        if user then
          local shown = Fk:getCardById(id, true)
          local virtual = Fk:cloneCard(name, shown.suit, shown.number)
          virtual.skillName = fuyiqizhe.name
          virtual:addFakeSubcard(id)
          local targets = chooseTargets(room, player, user, virtual)
          if targets and #targets > 0 then
            room:addTableMarkIfNeed(player, used_mark, name)
            room:useCard {
              from = user,
              tos = targets,
              card = virtual,
              extra_data = {
                fei__fuyiqizhe_shown_card = id,
                fei__fuyiqizhe_owner = player.id,
              },
            }
          end
        end
      end
    end

  end,
})

fuyiqizhe:addEffect(fk.AfterCardsMove, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(fuyiqizhe.name, true, true) or not causalUse(player.room, player) then
      return false
    end
    local discarded, visible = {}, false
    for _, move in ipairs(data) do
      for _, info in ipairs(move.moveInfo) do
        if isChildOf(info.cardId, player) then
          if move.toArea == Card.DiscardPile then
            table.insert(discarded, { id = info.cardId, loser = move.from })
          elseif not table.contains({ Card.PlayerEquip, Card.PlayerJudge }, info.fromArea) and
            table.contains({ Card.PlayerEquip, Card.PlayerJudge }, move.toArea) then
            visible = true
          end
        end
      end
    end
    if #discarded == 0 and not visible then return false end
    event:setCostData(self, { discarded = discarded, visible = visible })
    return true
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    for _, item in ipairs(cost.discarded) do
      local card = Fk:getCardById(item.id, true)
      room:setCardMark(card, child_mark, 0)
      room:setCardMark(card, child_owner_mark, 0)
      if not player.dead then room:loseHp(player, 1, fuyiqizhe.name) end
      if item.loser and not item.loser.dead then
        room:loseHp(item.loser, 1, fuyiqizhe.name)
      end
    end
    if cost.visible then resetSkill(room, player) end
  end,
})

fuyiqizhe:addEffect(fk.CardShown, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fuyiqizhe.name, true, true) and causalUse(player.room, player) and
      table.find(data.cardIds, function(id) return isChildOf(id, player) end) ~= nil
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    resetSkill(player.room, player)
  end,
})

return fuyiqizhe
