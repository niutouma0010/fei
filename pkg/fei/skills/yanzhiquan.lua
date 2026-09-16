local yanzhiquan = fk.CreateSkill {
  name = "fei__yanzhiquan",
}

local U = require "packages.utility.utility"

local fire_card_names = { "fire__slash", "fire_attack", "fan" }
local fire_name_mark = "fei__yanzhiquan-inhand-turn"

local function isFireDamageCard(id)
  local card = Fk:getCardById(id)
  if card.damage_type == fk.FireDamage then return true end
  local name = card:getMark(fire_name_mark)
  return type(name) == "string" and name ~= "" and
    Fk:cloneCard(name).damage_type == fk.FireDamage
end

local function addFilterEffect(skill)
  skill:addEffect("filter", {
    card_filter = function(self, card, player)
      return card:getMark(fire_name_mark) ~= 0 and
        table.contains(player:getCardIds("h"), card.id)
    end,
    view_as = function(self, player, card)
      local c = Fk:cloneCard(card:getMark(fire_name_mark), card.suit, card.number)
      c.skillName = yanzhiquan.name
      return c
    end,
  })
end

addFilterEffect(yanzhiquan)

Fk:loadTranslationTable {
  ["fei__yanzhiquan"] = "炎之拳",
  [":fei__yanzhiquan"] = "当你使用牌后，你可以令一名目标角色的当前手牌均视为任意火属性牌直到本回合结束；" ..
    "当你对一名角色使用伤害牌时，其邻家可以重铸一张火属性伤害牌以令此牌伤害+1。",

  ["#fei__yanzhiquan-choose"] = "炎之拳：你可以令一名目标角色的当前手牌均视为任意火属性牌直到本回合结束",
  ["#fei__yanzhiquan-card-name"] = "炎之拳：选择 %dest 的当前手牌视为的火属性牌名",
  ["#fei__yanzhiquan-recast"] = "炎之拳：你可以重铸一张火属性伤害牌以令此牌伤害+1",
}

yanzhiquan:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(yanzhiquan.name) then return false end
    local targets = table.filter(data.tos or {}, function(p)
      return not p.dead and not p:isKongcheng()
    end)
    if #targets == 0 then return false end
    event:setCostData(self, { tos = targets })
    return true
  end,
  on_cost = function(self, event, target, player, data)
    local cost_data = event:getCostData(self)
    local tos = player.room:askToChoosePlayers(player, {
      targets = cost_data.tos,
      min_num = 1,
      max_num = 1,
      prompt = "#fei__yanzhiquan-choose",
      skill_name = yanzhiquan.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost_data = event:getCostData(self)
    local to = cost_data.tos[1]
    local choice = U.askForChooseCardNames(room, player, fire_card_names, 1, 1,
      yanzhiquan.name, "#fei__yanzhiquan-card-name::" .. to.id, fire_card_names, false)[1]
    if not choice then return end
    for _, id in ipairs(to:getCardIds("h")) do
      room:setCardMark(Fk:getCardById(id), fire_name_mark, choice)
    end
  end,
})

yanzhiquan:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(yanzhiquan.name) or
      not data.card.is_damage_card or data.to.dead then
      return false
    end
    local neighbors = {}
    for _, p in ipairs({ data.to:getLastAlive(), data.to:getNextAlive() }) do
      if p ~= data.to and not table.contains(neighbors, p) then
        local ids = table.filter(p:getCardIds("he"), isFireDamageCard)
        if #ids > 0 then
          table.insert(neighbors, p)
        end
      end
    end
    if #neighbors == 0 then return false end
    player.room:sortByAction(neighbors)
    event:setCostData(self, { tos = neighbors })
    return true
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local recasts = {}
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p.dead then
        local ids = table.filter(p:getCardIds("he"), isFireDamageCard)
        if #ids > 0 then
          local cards = room:askToCards(p, {
            min_num = 1,
            max_num = 1,
            include_equip = true,
            skill_name = yanzhiquan.name,
            pattern = tostring(Exppattern { id = ids }),
            prompt = "#fei__yanzhiquan-recast:" .. player.id .. ":" .. data.to.id .. ":" .. data.card:toLogString(),
            cancelable = true,
          })
          if #cards > 0 then
            table.insert(recasts, { p, cards[1] })
          end
        end
      end
    end
    if #recasts > 0 then
      event:setCostData(self, { recasts = recasts })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, recast in ipairs(event:getCostData(self).recasts) do
      local p, id = recast[1], recast[2]
      if not p.dead and room:getCardOwner(id) == p and
        table.contains(p:getCardIds("he"), id) then
        room:recastCard({ id }, p, yanzhiquan.name)
        n = n + 1
      end
    end
    data.additionalDamage = (data.additionalDamage or 0) + n
  end,
})

return yanzhiquan
