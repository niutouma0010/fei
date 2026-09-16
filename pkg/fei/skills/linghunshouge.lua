local linghunshouge = fk.CreateSkill {
  name = "fei__linghunshouge",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["fei__linghunshouge"] = "灵魂收割",
  [":fei__linghunshouge"] = "锁定技，若一名角色的体力值较之你：不大于，你对其使用牌无次数限制；不小于，你对其造成伤害后回复1点体力。",
}

linghunshouge:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(linghunshouge.name) and card and to and
      to.hp <= player.hp
  end,
})

linghunshouge:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(linghunshouge.name) and
      not player.dead and player:isWounded() and data.to and not data.to.dead and
      data.to.hp >= player.hp
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:recover {
      who = player,
      num = 1,
      recoverBy = player,
      skillName = linghunshouge.name,
    }
  end,
})

return linghunshouge
