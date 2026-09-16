local zuijiadadang = fk.CreateSkill {
  name = "fei__zuijiadadang",
  tags = { Skill.Compulsory },
}

local chanzhang_specs = {
  { "fei__chanzhang_offensive", Card.NoSuit, 0 },
  { "fei__chanzhang_defensive", Card.NoSuit, 0 },
}
local provided_specs = {
  { "kylin_bow", Card.NoSuit, 0 },
  { "silver_lion", Card.NoSuit, 0 },
}
local chanzhang_names = { "fei__chanzhang_offensive", "fei__chanzhang_defensive" }
local provided_mark = "fei__zuijiadadang_provided"
local slot_mark = "fei__zuijiadadang_slot"
local syncing_mark = "fei__zuijiadadang_syncing"

Fk:loadTranslationTable {
  ["fei__zuijiadadang"] = "最佳搭档",
  [":fei__zuijiadadang"] = "锁定技，每轮开始或你受到伤害时，你将【馋杖】置入一名角色的坐骑栏；若你场上有【馋杖】，你的装备区视为拥有【白银狮子】，否则改为【麒麟弓】。",
  ["#fei__zuijiadadang-choose"] = "最佳搭档：选择一名角色，将【馋杖】置入其坐骑栏",
  ["#fei__zuijiadadang-slot"] = "最佳搭档：选择将【馋杖】置入的坐骑栏",
  ["fei__chanzhang_offensive_slot"] = "进攻坐骑栏",
  ["fei__chanzhang_defensive_slot"] = "防御坐骑栏",
}

local function hasChanzhang(player)
  return table.find(player:getEquipCards(), function(card)
    return table.contains(chanzhang_names, card.name)
  end) ~= nil
end

local function providedCard(player)
  local room = player.room
  return table.find(player:getCardIds("e"), function(id)
    return Fk:getCardById(id, true):getMark(provided_mark) == player.id and
      room:getCardOwner(id) == player
  end)
end

local function desiredProvidedName(player)
  return hasChanzhang(player) and "silver_lion" or "kylin_bow"
end

local function desiredSlot(name)
  return name == "silver_lion" and Player.ArmorSlot or Player.WeaponSlot
end

local function desiredSubtype(name)
  return name == "silver_lion" and Card.SubtypeArmor or Card.SubtypeWeapon
end

local function clearExtraSlot(player)
  local room = player.room
  local slot = player:getMark(slot_mark)
  if type(slot) == "string" and slot ~= "" then
    room:removePlayerEquipSlots(player, slot)
    room:setPlayerMark(player, slot_mark, 0)
  end
end

local function ensureExtraSlot(player, slot)
  if player:getMark(slot_mark) == slot then return end
  clearExtraSlot(player)
  player.room:addPlayerEquipSlots(player, slot)
  player.room:setPlayerMark(player, slot_mark, slot)
end

local function syncProvidedEquip(player)
  if player.dead or not player:hasSkill(zuijiadadang.name, true) or
    player:getMark(syncing_mark) > 0 then
    return
  end
  local room = player.room
  room:setPlayerMark(player, syncing_mark, 1)
  local desired = desiredProvidedName(player)
  local slot = desiredSlot(desired)
  local subtype = desiredSubtype(desired)

  local current = providedCard(player)
  if current and Fk:getCardById(current, true).name ~= desired then
    room:moveCardTo(current, Card.Void, nil, fk.ReasonJustMove,
      zuijiadadang.name, nil, true, player)
    current = nil
  end

  local has_other = table.find(player:getEquipments(subtype), function(id)
    return id ~= current
  end) ~= nil
  if has_other then
    ensureExtraSlot(player, slot)
  else
    clearExtraSlot(player)
  end

  if not current then
    local cards = room:prepareDeriveCards(provided_specs,
      "fei__zuijiadadang_provided_" .. player.id)
    local id = table.find(cards, function(card_id)
      return Fk:getCardById(card_id, true).name == desired
    end)
    if id then
      room:setCardMark(Fk:getCardById(id, true), provided_mark, player.id)
      local virtual = Fk:cloneCard(desired, Card.NoSuit, 0)
      virtual:addSubcard(id)
      player:addVirtualEquip(virtual)
      room:moveCardTo(virtual, Card.PlayerEquip, player, fk.ReasonPut,
        zuijiadadang.name, nil, true, player)
    end
  end
  room:setPlayerMark(player, syncing_mark, 0)
end

local function putChanzhang(player)
  local room = player.room
  local targets = table.filter(room.alive_players, function(p)
    return #p:getAvailableEquipSlots(Card.SubtypeOffensiveRide) > 0 or
      #p:getAvailableEquipSlots(Card.SubtypeDefensiveRide) > 0
  end)
  if #targets == 0 then return end
  local to = room:askToChoosePlayers(player, {
    targets = targets,
    min_num = 1,
    max_num = 1,
    prompt = "#fei__zuijiadadang-choose",
    skill_name = zuijiadadang.name,
    cancelable = false,
  })[1]
  if not to then return end

  local choices = {}
  if #to:getAvailableEquipSlots(Card.SubtypeOffensiveRide) > 0 then
    table.insert(choices, "fei__chanzhang_offensive_slot")
  end
  if #to:getAvailableEquipSlots(Card.SubtypeDefensiveRide) > 0 then
    table.insert(choices, "fei__chanzhang_defensive_slot")
  end
  local choice = room:askToChoice(player, {
    choices = choices,
    skill_name = zuijiadadang.name,
    prompt = "#fei__zuijiadadang-slot::" .. to.id,
  })
  local name = choice == "fei__chanzhang_defensive_slot" and
    "fei__chanzhang_defensive" or "fei__chanzhang_offensive"

  local cards = room:prepareDeriveCards(chanzhang_specs,
    "fei__chanzhang_derive_" .. player.id)
  local id = table.find(cards, function(card_id)
    return Fk:getCardById(card_id, true).name == name
  end)
  if not id then return end
  for _, card_id in ipairs(cards) do
    if card_id ~= id and room:getCardArea(card_id) ~= Card.Void then
      room:moveCardTo(card_id, Card.Void, nil, fk.ReasonJustMove,
        zuijiadadang.name, nil, true, player)
    end
  end
  room:moveCardTo(id, Card.PlayerEquip, to, fk.ReasonPut,
    zuijiadadang.name, nil, true, player)
end

zuijiadadang:addEffect(fk.GameStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zuijiadadang.name)
  end,
  on_use = function(self, event, target, player, data)
    syncProvidedEquip(player)
  end,
})

zuijiadadang:addEffect(fk.RoundStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zuijiadadang.name)
  end,
  on_use = function(self, event, target, player, data)
    putChanzhang(player)
  end,
})

zuijiadadang:addEffect(fk.Damaged, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zuijiadadang.name)
  end,
  on_use = function(self, event, target, player, data)
    putChanzhang(player)
  end,
})

zuijiadadang:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(zuijiadadang.name, true) and
      player:getMark(syncing_mark) == 0
  end,
  on_refresh = function(self, event, target, player, data)
    syncProvidedEquip(player)
  end,
})

zuijiadadang:addAcquireEffect(function(self, player)
  if player.room:getBanner("RoundCount") then
    syncProvidedEquip(player)
  end
end)

zuijiadadang:addLoseEffect(function(self, player)
  local room = player.room
  room:setPlayerMark(player, syncing_mark, 1)
  local current = providedCard(player)
  if current then
    room:moveCardTo(current, Card.Void, nil, fk.ReasonJustMove,
      zuijiadadang.name, nil, true, player)
  end
  clearExtraSlot(player)
  room:setPlayerMark(player, syncing_mark, 0)
end)

return zuijiadadang
