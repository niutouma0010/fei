local mingzhiwu = fk.CreateSkill {
  name = "fei__mingzhiwu",
}

local used_mark = "fei__wangliang_basic_used-turn"

Fk:loadTranslationTable {
  ["fei__mingzhiwu"] = "冥之雾",
  [":fei__mingzhiwu"] = "你可以对攻击范围内的所有角色使用一张本回合被使用过的基本牌。",
  ["#fei__mingzhiwu"] = "冥之雾：对攻击范围内的所有角色使用一种本回合被使用过的基本牌",
}

local function usedBasicNames(player)
  return player:getTableMark(used_mark)
end

local function targetsFor(player, name)
  local card = Fk:cloneCard(name)
  card.skillName = mingzhiwu.name
  local targets = table.filter(Fk:currentRoom().alive_players, function(p)
    return p ~= player and player:inMyAttackRange(p)
  end)
  if #targets == 0 or player:prohibitUse(card) or not player:canUse(card) then return {} end
  if card.trueName == "peach" then
    if table.every(targets, function(p)
      return p:isWounded() and not player:isProhibited(p, card)
    end) then
      return targets
    end
    return {}
  end
  if table.every(targets, function(p)
    return player:canUseTo(card, p)
  end) then
    return targets
  end
  return {}
end

mingzhiwu:addEffect("active", {
  anim_type = "offensive",
  prompt = "#fei__mingzhiwu",
  card_num = 0,
  target_num = 0,
  interaction = function(self, player)
    local choices = table.filter(usedBasicNames(player), function(name)
      return #targetsFor(player, name) > 0
    end)
    if #choices == 0 then return end
    return UI.ComboBox { choices = choices }
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player.phase == Player.Play and table.find(usedBasicNames(player), function(name)
      return #targetsFor(player, name) > 0
    end) ~= nil
  end,
  on_use = function(self, room, effect)
    local name = self.interaction.data
    if not name then return end
    local targets = targetsFor(effect.from, name)
    if #targets == 0 then return end
    local card = Fk:cloneCard(name)
    card.skillName = mingzhiwu.name
    room:useCard {
      from = effect.from,
      tos = targets,
      card = card,
    }
  end,
})


mingzhiwu:addEffect(fk.CardUsing, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(mingzhiwu.name, true, true) and
      data.card and data.card.type == Card.TypeBasic and
      not table.contains(player:getTableMark(used_mark), data.card.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, used_mark, data.card.name)
  end,
})

return mingzhiwu
