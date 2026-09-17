local skill = fk.CreateSkill { name = "fei__yinyangfish_skill&" }

local function removeMark(room, player)
  room:removePlayerMark(player, "@!!fei_yinyangfish", 1)
  if player:getMark("@!!fei_yinyangfish") == 0 then
    room:handleAddLoseSkills(player, "-" .. skill.name)
  end
end

skill:addEffect("active", {
  prompt = "#fei__yinyangfish_skill&",
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:getMark("@!!fei_yinyangfish") > 0
  end,
  card_filter = Util.FalseFunc,
  target_num = 0,
  on_use = function(self, room, effect)
    removeMark(room, effect.from)
    effect.from:drawCards(1, skill.name)
  end,
})

skill:addEffect(fk.EventPhaseStart, {
  priority = 0.1,
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Discard and
      player:hasSkill(skill.name) and player:getMark("@!!fei_yinyangfish") > 0 and
      player:getHandcardNum() > player:getMaxCards()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = skill.name,
      prompt = "#fei__yinyangfish_max-ask",
    })
  end,
  on_use = function(self, event, target, player, data)
    removeMark(player.room, player)
    player.room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 2)
    player.room:broadcastProperty(player, "MaxCards")
  end,
})

Fk:loadTranslationTable {
  [skill.name] = "阴阳鱼",
  ["#fei__yinyangfish_skill&"] = "你可弃一枚“阴阳鱼”，摸一张牌",
  ["#fei__yinyangfish_max-ask"] = "你可弃一枚“阴阳鱼”，此回合手牌上限+2",
  [":" .. skill.name] = "出牌阶段，你可弃一枚“阴阳鱼”，摸一张牌；弃牌阶段开始时，你可弃一枚“阴阳鱼”，此回合手牌上限+2。",
}

return skill
