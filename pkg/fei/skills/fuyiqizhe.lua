local fuyiqizhe = fk.CreateSkill {
  name = "fei__fuyiqizhe",
}

local U = require "packages.fei.util"
local used_mark = "fei__fuyiqizhe_used-round"
local choices = { "unexpectation", "bogus_flower", "underhanding" }
local actual_names = {
  unexpectation = "fei__unexpectation",
  bogus_flower = "bogus_flower",
  underhanding = "underhanding",
}

Fk:loadTranslationTable {
  ["fei__fuyiqizhe"] = "夫弈棋者",
  [":fei__fuyiqizhe"] = "每轮每牌名限一次，每回合结束时，你可以展示一张牌，然后视为将之当【出其不意】/【树上开花】/【瞒天过海】中的若干张依次令一名角色使用，展示牌因此：进入弃牌堆后，你与失去者各失去1点体力；为所有角色可见后，你重置此技能。",
  ["#fei__fuyiqizhe-owner"] = "夫弈棋者：选择一名有牌的角色",
  ["#fei__fuyiqizhe-card"] = "夫弈棋者：选择并展示 %dest 区域内的一张牌",
  ["#fei__fuyiqizhe-names"] = "夫弈棋者：选择要依次视为使用的牌名",
  ["#fei__fuyiqizhe-user"] = "夫弈棋者：选择一名角色，令其使用【%arg】",
  ["#fei__fuyiqizhe-use"] = "夫弈棋者：请使用【%arg】",
}

local function availableNames(player)
  local used = player:getTableMark(used_mark)
  return table.filter(choices, function(name)
    return not table.contains(used, name) and Fk.all_card_types[actual_names[name]] ~= nil
  end)
end

local function canUseName(player, name)
  local card = Fk:cloneCard(actual_names[name])
  card.skillName = fuyiqizhe.name
  return not player:prohibitUse(card) and player:canUse(card) and
    #card:getAvailableTargets(player) > 0
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
          prompt = "#fei__fuyiqizhe-user:::" .. actual_names[name],
          skill_name = fuyiqizhe.name,
          cancelable = false,
        })
        local user = chosen[1]
        if user then
          local use = room:askToUseVirtualCard(user, {
            name = actual_names[name],
            skill_name = fuyiqizhe.name,
            prompt = "#fei__fuyiqizhe-use:::" .. actual_names[name],
            cancelable = false,
            skip = true,
          })
          if use then
            room:addTableMarkIfNeed(player, used_mark, name)
            room:useCard(use)
          end
        end
      end
    end

    if room:getCardArea(id) == Card.DiscardPile then
      if not player.dead then room:loseHp(player, 1, fuyiqizhe.name) end
      if not owner.dead then room:loseHp(owner, 1, fuyiqizhe.name) end
    elseif table.contains({ Card.PlayerEquip, Card.PlayerJudge, Card.Processing }, room:getCardArea(id)) then
      room:setPlayerMark(player, used_mark, 0)
    end
  end,
})

return fuyiqizhe
