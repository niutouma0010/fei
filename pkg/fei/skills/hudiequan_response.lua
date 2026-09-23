local mobileUtil = require "packages.fei.util"

local skill = fk.CreateSkill { name = "fei__hudiequan_response" }
local main_skill = "fei__hudiequan"

local function isInstantCard(card)
  return card.type == Card.TypeBasic or card:isCommonTrick()
end

local function enterNifu(player)
  local room = player.room
  room:invalidateSkill(player, main_skill, "-turn")
  room:invalidateSkill(player, skill.name, "-turn")
  if not player:hasSkill("fei__yuzi_nifu", true) then
    room:handleAddLoseSkills(player, "fei__yuzi_nifu", main_skill, false)
  end
end

Fk:loadTranslationTable {
  ["fei__hudiequan_response"] = "狐蝶拳",
  [":fei__hudiequan_response"] = "你可以将给出一张即时牌并视为使用或打出之。",
}

skill:addEffect("viewas", {
  anim_type = "control",
  pattern = ".",
  prompt = "#fei__hudiequan-use",
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 or not table.contains(player:getCardIds("h"), to_select) then
      return false
    end
    local original = Fk:getCardById(to_select)
    if not isInstantCard(original) then return false end
    local card = Fk:cloneCard(original.name, original.suit, original.number)
    card.skillName = main_skill
    card:addSubcard(to_select)
    return player:canUseOrResponseInCurrent(card)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local original = Fk:getCardById(cards[1])
    local card = Fk:cloneCard(original.name, original.suit, original.number)
    card.skillName = main_skill
    card:addSubcards(cards)
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local id = use.card.subcards[1]
    if not id or room:getCardOwner(id) ~= player or
      room:getCardArea(id) ~= Card.PlayerHand then
      return skill.name
    end
    local recipients = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player),
      min_num = 1,
      max_num = 1,
      skill_name = main_skill,
      prompt = "#fei__hudiequan-response-recipient",
      cancelable = true,
    })
    if #recipients == 0 then return skill.name end
    local recipient = recipients[1]
    local original = Fk:getCardById(id)
    local was_displayed = mobileUtil.cardIsVisible(room, original)
    room:moveCardTo(id, Card.PlayerHand, recipient, fk.ReasonGive,
      main_skill, nil, was_displayed, player)
    use.card:clearSubcards()
    if not player.dead and (not was_displayed or
      not table.contains(use.tos or {}, recipient)) then
      enterNifu(player)
    end
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    return #Fk:currentRoom().alive_players > 1
  end,
  enabled_at_nullification = function(self, player, data)
    return #Fk:currentRoom().alive_players > 1 and table.find(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == "nullification"
    end) ~= nil
  end,
})

return skill
