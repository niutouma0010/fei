local mingzhihuo = fk.CreateSkill {
  name = "fei__mingzhihuo",
}

local used_mark = "fei__wangliang_basic_used-turn"

Fk:loadTranslationTable {
  ["fei__mingzhihuo"] = "冥之火",
  [":fei__mingzhihuo"] = "你可以无距离次数限制地视为使用一张本回合未被使用过的基本牌。",
  ["#fei__mingzhihuo"] = "冥之火：视为使用一张本回合未被使用过的基本牌",
}

local function usedBasicNames(player)
  return player:getTableMark(used_mark)
end

local function allBasicNames()
  local names = table.simpleClone(Fk:getAllCardNames("b"))
  table.insertIfNeed(names, "analeptic")
  return names
end

mingzhihuo:addEffect("viewas", {
  prompt = "#fei__mingzhihuo",
  interaction = function(self, player)
    local used = usedBasicNames(player)
    local choices = table.filter(allBasicNames(), function(name)
      local card = Fk:cloneCard(name)
      card.skillName = mingzhihuo.name
      return not table.contains(used, name) and player:canUse(card, { bypass_times = true })
    end)
    if #choices == 0 then return end
    return UI.ComboBox { choices = choices }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = mingzhihuo.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player.phase == Player.Play
  end,
})

mingzhihuo:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, mingzhihuo.name)
  end,
  bypass_distances = function(self, player, skill, card)
    return card and table.contains(card.skillNames, mingzhihuo.name)
  end,
})

mingzhihuo:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, mingzhihuo.name)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

mingzhihuo:addEffect(fk.CardUsing, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(mingzhihuo.name, true, true) and
      data.card and data.card.type == Card.TypeBasic and
      not table.contains(player:getTableMark(used_mark), data.card.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, used_mark, data.card.name)
  end,
})

return mingzhihuo
