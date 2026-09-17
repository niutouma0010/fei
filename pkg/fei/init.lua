local extension = Package:new("fei")
extension.extensionName = "fei"

extension:loadSkillSkelsByPath("./packages/fei/pkg/fei/skills")

local chanzhangOffensive = fk.CreateCard {
  name = "&fei__chanzhang_offensive",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeOffensiveRide,
  equip_skill = "fei__chanzhang_skill",
}
local chanzhangDefensive = fk.CreateCard {
  name = "&fei__chanzhang_defensive",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeDefensiveRide,
  equip_skill = "fei__chanzhang_skill",
}
local feiUnexpectation = fk.CreateCard {
  name = "fei__unexpectation",
  type = Card.TypeTrick,
  skill = "fei__unexpectation_skill",
  is_damage_card = true,
  damage_type = fk.NormalDamage,
}
extension:addCardSpec("fei__chanzhang_offensive", Card.NoSuit, 0)
extension:addCardSpec("fei__chanzhang_defensive", Card.NoSuit, 0)
extension:loadCardSkels { chanzhangOffensive, chanzhangDefensive, feiUnexpectation }

Fk:loadTranslationTable {
  ["fei__chanzhang_offensive"] = "馋杖",
  ["fei__chanzhang_defensive"] = "馋杖",
  ["fei__unexpectation"] = "出其不意",
  [":fei__chanzhang_offensive"] = "装备牌·进攻坐骑<br/><b>装备技能</b>：锁定技，此牌进入/离开装备栏时，你须使用一张非伤害/非基本牌；你可以弃置此牌以将区域内所有牌当【无中生有】使用。",
  [":fei__chanzhang_defensive"] = "装备牌·防御坐骑<br/><b>装备技能</b>：锁定技，此牌进入/离开装备栏时，你须使用一张非伤害/非基本牌；你可以弃置此牌以将区域内所有牌当【无中生有】使用。",
  [":fei__unexpectation"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名有手牌的其他角色<br/><b>效果</b>：你展示目标角色的一张手牌，若该牌与此【出其不意】花色不同，你对其造成1点伤害。",
}

General:new(extension, "fei__leizhenzi", "fei_kingdom", 3):addSkills {
  "fei__tianxuanzhiren",
  "fei__leifajiangshi",
}

General:new(extension, "fei__honghaier", "fei_kingdom", 4):addSkills {
  "fei__yanzhiquan",
}

General:new(extension, "fei__leimu", "fei_kingdom", 3, 3, General.Female):addSkills {
  "fei__leidianshaonv",
  "fei__tianleiyin",
}

General:new(extension, "fei__zhongkui", "fei_kingdom", 4):addSkills {
  "fei__chulingtegong",
  "fei__baiguiyexing",
}

General:new(extension, "fei__baigujing", "fei_kingdom", 3, 3, General.Female):addSkills {
  "fei__sanrenzuyeshi",
}

local yuzi = General:new(extension, "fei__yuzi", "fei_kingdom", 3, 3, General.Female)
yuzi:addSkills {
  "fei__hudiequan",
}
yuzi:addRelatedSkill("fei__yuzi_nifu")

General:new(extension, "fei__yanluo", "fei_kingdom", 3, 5, General.Female):addSkills {
  "fei__eguigaizao",
  "fei__linghunshouge",
}

General:new(extension, "fei__change", "fei_kingdom", 3, 3, General.Female):addSkills {
  "fei__buxiangqichuanga",
  "fei__xiaotutudata",
}

General:new(extension, "fei__wujing", "fei_kingdom", 3, 3, General.Female):addSkills {
  "fei__wukounvpu",
  "fei__dushehebo",
}

General:new(extension, "fei__jinchan", "fei_kingdom", 3):addSkills {
  "fei__zuijiadadang",
}

General:new(extension, "fei__degula", "fei_kingdom", 4):addSkills {
  "fei__chihuobenxing",
  "fei__fuyingchongchong",
}

General:new(extension, "fei__wangliang", "fei_kingdom", 3, 3, General.Female):addSkills {
  "fei__guilaile",
  "fei__mingzhihuo",
  "fei__mingzhiwu",
}

General:new(extension, "fei__baixiang", "fei_kingdom", 3):addSkills {
  "fei__fuyiqizhe",
}

Fk:loadTranslationTable {
  ["fei__leizhenzi"] = "雷震子",
  ["designer:fei__leizhenzi"] = "牛头马",
  ["!fei__leizhenzi"] = "吾，就是世界秩序的保障！",

  ["fei__honghaier"] = "红孩儿",
  ["designer:fei__honghaier"] = "牛头马",
  ["!fei__honghaier"] = "信不信本大爷烤了你！",

  ["fei__leimu"] = "雷姆",
  ["designer:fei__leimu"] = "牛头马",
  ["!fei__leimu"] = "雷电少女，闪亮登场！",

  ["fei__zhongkui"] = "钟馗",
  ["designer:fei__zhongkui"] = "牛头马",
  ["!fei__zhongkui"] = "专业素养，品质保证！",

  ["fei__baigujing"] = "白骨精",
  ["designer:fei__baigujing"] = "牛头马",
  ["!fei__baigujing"] = "白骨组，出击！",

  ["fei__yuzi"] = "玉子",
  ["designer:fei__yuzi"] = "牛头马",
  ["!fei__yuzi"] = "小蝴蝶等等我！",

  ["fei__yanluo"] = "琰萝",
  ["designer:fei__yanluo"] = "牛头马",
  ["!fei__yanluo"] = "你愿意做我的新玩具吗？",

  ["fei__change"] = "嫦娥",
  ["designer:fei__change"] = "牛头马",
  ["!fei__change"] = "Zzz……",

  ["fei__wujing"] = "悟静",
  ["designer:fei__wujing"] = "牛头马",
  ["!fei__wujing"] = "我是…悟静……",

  ["fei__jinchan"] = "金禅",
  ["designer:fei__jinchan"] = "牛头马",
  ["!fei__jinchan"] = "你给我闭嘴！",

  ["fei__degula"] = "德古拉",
  ["designer:fei__degula"] = "牛头马",
  ["!fei__degula"] = "好吃的，飞来！",

  ["fei__wangliang"] = "魍魉",
  ["designer:fei__wangliang"] = "牛头马",
  ["!fei__wangliang"] = "啊，有人欺负我",

  ["fei__baixiang"] = "白象",
  ["designer:fei__baixiang"] = "牛头马",
  ["!fei__baixiang"] = "局势反转！",
}

return extension
