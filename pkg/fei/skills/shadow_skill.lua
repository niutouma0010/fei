local skill = fk.CreateSkill { name = "fei__shadow_skill" }

skill:addEffect("cardskill", {
  target_num = 0,
  can_use = Util.FalseFunc,
})

return skill
