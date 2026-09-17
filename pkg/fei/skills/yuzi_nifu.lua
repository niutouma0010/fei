local yuzi_nifu = fk.CreateSkill {
  name = "fei__yuzi_nifu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["fei__yuzi_nifu"] = "匿伏",
  [":fei__yuzi_nifu"] = "锁定技，每名角色的回合结束时，你将手牌摸或弃至三张。",
}

yuzi_nifu:addEffect(fk.TurnEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yuzi_nifu.name, true)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player.dead then
      player:broadcastSkillInvoke("nifu")
      local n = player:getHandcardNum() - 3
      if n < 0 then
        room:notifySkillInvoked(player, yuzi_nifu.name, "drawcard")
        player:drawCards(-n, yuzi_nifu.name)
      elseif n > 0 then
        room:notifySkillInvoked(player, yuzi_nifu.name, "negative")
        room:askToDiscard(player, {
          min_num = n,
          max_num = n,
          include_equip = false,
          skill_name = yuzi_nifu.name,
          cancelable = false,
        })
      end
    end
    room:handleAddLoseSkills(player, "-" .. yuzi_nifu.name, "fei__hudiequan", false)
  end,
})

return yuzi_nifu
