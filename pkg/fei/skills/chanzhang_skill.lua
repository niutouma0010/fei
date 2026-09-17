local chanzhang = fk.CreateSkill {
  name = "fei__chanzhang_skill",
  tags = { Skill.Compulsory },
}

local using_mark = "fei__chanzhang_using"
local force_mark = "fei__chanzhang_force"
local names = { "fei__chanzhang_offensive", "fei__chanzhang_defensive" }

Fk:loadTranslationTable {
  ["fei__chanzhang_skill"] = "馋杖",
  [":fei__chanzhang_skill"] = "你可以弃置此牌以将区域内所有牌当【无中生有】使用。",
  ["#fei__chanzhang_skill"] = "馋杖：弃置“馋杖”，将你区域内其余所有牌当【无中生有】使用",
  ["#fei__chanzhang-enter"] = "馋杖：你须使用一张非伤害牌；选择“馋杖”则弃置此牌，将区域内其余所有牌当【无中生有】使用",
  ["#fei__chanzhang-leave"] = "馋杖：你须使用一张非基本牌",
  ["fei__chanzhang-normal"] = "使用符合条件的牌",
  ["fei__chanzhang-convert"] = "发动“馋杖”",
}

local function allAreaCards(player)
  return player:getCardIds("hej")
end

local function chanzhangId(player)
  return table.find(player:getCardIds("e"), function(id)
    return table.contains(names, Fk:getCardById(id).name)
  end)
end

local function convertCards(player, costId)
  return table.filter(allAreaCards(player), function(id)
    return id ~= costId
  end)
end

local function canConvert(player)
  local id = chanzhangId(player)
  return id and not player:prohibitDiscard(id) and #convertCards(player, id) > 0
end

local function makeExNihilo(player, costId)
  local card = Fk:cloneCard("ex_nihilo")
  card:addSubcards(convertCards(player, costId))
  card.skillName = chanzhang.name
  return card
end

chanzhang:addEffect("viewas", {
  anim_type = "drawcard",
  pattern = "ex_nihilo",
  prompt = "#fei__chanzhang_skill",
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {},
  },
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local id = chanzhangId(player)
    if not id or not canConvert(player) then return end
    return makeExNihilo(player, id)
  end,
  before_use = function(self, player, use)
    local room = player.room
    local id = chanzhangId(player)
    if not id then return end
    room:setPlayerMark(player, using_mark, 1)
    room:throwCard(id, chanzhang.name, player, player)
  end,
  after_use = function(self, player, use)
    player.room:setPlayerMark(player, using_mark, 0)
  end,
  enabled_at_play = function(self, player)
    return canConvert(player)
  end,
  enabled_at_response = Util.FalseFunc,
})

chanzhang:addEffect("prohibit", {
  global = true,
  prohibit_use = function(self, player, card)
    local branch = player:getMark(force_mark)
    if branch == "enter" then
      return card.is_damage_card
    elseif branch == "leave" then
      return card.type == Card.TypeBasic
    end
  end,
})

local function movedBranch(player, data)
  for _, move in ipairs(data) do
    for _, info in ipairs(move.moveInfo) do
      if move.from == player and info.fromArea == Card.PlayerEquip and
        table.contains(names, info.beforeCard.name) then
        return "leave"
      end
      local moved = move.virtualEquip and
        move.virtualEquip:getEffectiveId() == info.cardId and move.virtualEquip or
        Fk:getCardById(info.cardId, true)
      if move.to == player and move.toArea == Card.PlayerEquip and
        table.contains(names, moved.name) then
        return "enter"
      end
    end
  end
end

local function usableRealCards(player, branch)
  return table.filter(player:getCardIds("h"), function(id)
    local card = Fk:getCardById(id)
    local matches = branch == "enter" and not card.is_damage_card or
      branch == "leave" and card.type ~= Card.TypeBasic
    return matches and not player:prohibitUse(card) and
      #card:getAvailableTargets(player, { bypass_times = true }) > 0
  end)
end

chanzhang:addEffect(fk.AfterCardsMove, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead or player:getMark(using_mark) > 0 then return false end
    local branch = movedBranch(player, data)
    if branch then
      event:setCostData(self, branch)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local branch = event:getCostData(self)
    local cards = usableRealCards(player, branch)
    local convert = canConvert(player)
    if #cards == 0 and not convert then return end
    local choice = #cards > 0 and "fei__chanzhang-normal" or "fei__chanzhang-convert"
    if #cards > 0 and convert then
      choice = room:askToChoice(player, {
        choices = { "fei__chanzhang-normal", "fei__chanzhang-convert" },
        skill_name = chanzhang.name,
        prompt = branch == "enter" and "#fei__chanzhang-enter" or "#fei__chanzhang-leave",
      })
    end
    if choice == "fei__chanzhang-normal" then
      room:setPlayerMark(player, force_mark, branch)
      local use = room:askToUseCard(player, {
        pattern = ".",
        skill_name = chanzhang.name,
        prompt = branch == "enter" and "#fei__chanzhang-enter" or "#fei__chanzhang-leave",
        cancelable = false,
      })
      room:setPlayerMark(player, force_mark, 0)
      if use then
        room:useCard(use)
        return
      end
    end
    local id = chanzhangId(player)
    if not id or not canConvert(player) then return end
    local card = makeExNihilo(player, id)
    room:setPlayerMark(player, using_mark, 1)
    room:throwCard(id, chanzhang.name, player, player)
    if player.dead then
      room:setPlayerMark(player, using_mark, 0)
      return
    end
    room:useCard {
      from = player,
      tos = { player },
      card = card,
      extraUse = true,
    }
    room:setPlayerMark(player, using_mark, 0)
  end,
})

return chanzhang
