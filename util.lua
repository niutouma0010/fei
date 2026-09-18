local FeiUtil = {}

FeiUtil.askForChooseCardNames = function(room, player, names, minNum, maxNum,
    skillName, prompt, allNames, cancelable, repeatable)
  skillName = skillName or ""
  prompt = prompt or skillName
  cancelable = cancelable == true
  repeatable = repeatable == true
  if type(allNames) == "table" then
    if #allNames == 0 or type(allNames[1]) ~= "table" then
      allNames = { allNames }
    end
  else
    allNames = { names }
  end
  local result = room:askToCustomDialog(player, {
    skill_name = skillName,
    component = {
      url = "packages/fei/qml/ChooseCardNamesBox.qml",
      model = {
        url = "packages/fei/qml/models/ChooseCardNamesModel.qml",
        prop = {
          choices = names,
          minNum = minNum,
          maxNum = maxNum,
          prompt = prompt,
          allChoices = allNames,
          cancelable = cancelable,
          repeatable = repeatable,
        },
      },
    },
  })
  if result ~= "" then return result end
  if cancelable or minNum <= 0 then return {} end
  local choices = room:tableRandomPick(names, minNum)
  if #choices < minNum and repeatable then
    for _ = 1, minNum - #choices do table.insert(choices, names[1]) end
  end
  return choices
end

-- 与帝辛所用的 DIY 明置机制保持一致：明置状态记录在手牌标记上，
-- 再由 VisibilitySkill 令这张牌对所有角色持续可见。
-- 这不仅影响牌主自己的界面，也会影响其他角色选取、弃置这些牌时的显示。
MarkEnum.ShownCards = MarkEnum.ShownCards or "@@ShownCards-inhand"
local visibleMark = MarkEnum.ShownCards

local function hasShownMark(card)
  if card:getMark(visibleMark) > 0 then return true end
  return table.find(MarkEnum.TempMarkSuffix, function(suffix)
    return card:getMark(visibleMark .. suffix) > 0
  end) ~= nil
end

FeiUtil.cardIsVisible = function(room, card)
  if type(card) == "number" then card = Fk:getCardById(card) end
  return table.contains({ Card.PlayerEquip, Card.PlayerJudge }, room:getCardArea(card)) or
    hasShownMark(card)
end

FeiUtil.DisplayCardData = TriggerData:subclass("FeiDisplayCardData")
FeiUtil.DisplayCardTE = TriggerEvent:subclass("FeiDisplayCardEvent")
FeiUtil.CardDisplayed = FeiUtil.DisplayCardTE:subclass("FeiUtil.CardDisplayed")
FeiUtil.DisplayCardEvent = "FeiDisplayCard"

Fk:addGameEvent(FeiUtil.DisplayCardEvent, nil, function(self)
  local data = self.data
  local room = self.room
  local cards = table.filter(data.cards, function(card)
    return room:getCardArea(card) == Card.PlayerHand and
      not FeiUtil.cardIsVisible(room, card)
  end)
  if #cards == 0 then return false end
  room:addSkill("#fei__shown_cards")
  table.forEach(cards, function(card)
    room:setCardMark(card, visibleMark, 1)
  end)
  data.who:showCards(Card:getIdList(cards))
  room.logic:trigger(FeiUtil.CardDisplayed, data.who, data)
end)

FeiUtil.displayCards = function(player, cards)
  if type(cards[1]) == "number" then
    cards = table.map(cards, function(id) return Fk:getCardById(id) end)
  end
  local toDisplay = table.filter(cards, function(card)
    return player.room:getCardArea(card) == Card.PlayerHand and
      not FeiUtil.cardIsVisible(player.room, card)
  end)
  if #toDisplay == 0 then return end
  local data = FeiUtil.DisplayCardData:new { who = player, cards = cards }
  GameEvent[FeiUtil.DisplayCardEvent]:create(data):exec()
  return data
end

Fk:loadTranslationTable {
  [visibleMark] = "明置",
  ["Clear All"] = "清空",
  ["@!!fei_yinyangfish"] = "阴阳鱼",
  [":@!!fei_yinyangfish"] = "出牌阶段，你可弃一枚“阴阳鱼”摸一张牌；弃牌阶段开始时，你可弃一枚“阴阳鱼”，此回合手牌上限+2。",
}

return FeiUtil
