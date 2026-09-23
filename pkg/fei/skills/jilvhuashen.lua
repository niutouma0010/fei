local jilvhuashen = fk.CreateSkill {
  name = "fei__jilvhuashen",
}

local target_mark = "fei__jilvhuashen_target"
local shadow_name = "fei__shadow"

Fk:loadTranslationTable {
  ["fei__jilvhuashen"] = "纪律化身",
  [":fei__jilvhuashen"] = "首轮开始时，你可以无距离限制地使用任意张手牌，然后获得【影】直到手牌数为唯一最多；本巡被你使用牌指定过的角色造成体力值变动后重铸你的一张手牌，然后若你手牌中没有【影】，你可展示所有手牌并再次发动此技能。",
  ["#fei__jilvhuashen-invoke"] = "纪律化身：你可以无距离限制地使用任意张手牌，然后获得【影】直到手牌数为唯一最多",
  ["#fei__jilvhuashen-use"] = "纪律化身：使用一张手牌，或取消并获得【影】直到手牌数为唯一最多",
  ["#fei__jilvhuashen-recast"] = "纪律化身：请选择 %dest 的一张手牌令其重铸",
  ["#fei__jilvhuashen-again"] = "纪律化身：你可以展示所有手牌并再次发动此技能",
}

local function hasShadow(player)
  return table.find(player:getCardIds("h"), function(id)
    return Fk:getCardById(id, true).name == shadow_name
  end) ~= nil
end

local function gainShadows(player)
  local room = player.room
  local max_other = 0
  for _, p in ipairs(room.alive_players) do
    if p ~= player then max_other = math.max(max_other, p:getHandcardNum()) end
  end
  local n = max_other + 1 - player:getHandcardNum()
  if n <= 0 then return end

  local specs = {}
  for _ = 1, 40 do table.insert(specs, { shadow_name, Card.Spade, 1 }) end
  local cards = room:prepareDeriveCards(specs, "fei__jilvhuashen_shadow_" .. player.id)
  cards = table.filter(cards, function(id)
    return room:getCardArea(id) == Card.Void
  end)
  if #cards == 0 then return end
  local chosen = room:tableRandomPick(cards, math.min(n, #cards))
  for _, id in ipairs(chosen) do
    room:setCardMark(Fk:getCardById(id, true), MarkEnum.DestructIntoDiscard, 1)
  end
  room:moveCardTo(chosen, Card.PlayerHand,
    player, fk.ReasonPrey, jilvhuashen.name, nil, true, player)
end

local function activate(player)
  local room = player.room
  -- “本巡”从本次发动开始，到下一次发动前结束。
  for _, p in ipairs(room.players) do
    local owners = p:getTableMark(target_mark)
    table.removeOne(owners, player.id)
    room:setPlayerMark(p, target_mark, #owners > 0 and owners or 0)
  end
  while not player.dead and not player:isKongcheng() do
    local use = room:askToUseCard(player, {
      -- 此处是主动使用牌，不能把仅能响应的【闪】或【无懈可击】当作可使用牌。
      pattern = "^(jink,nullification)|.|.|hand",
      skill_name = jilvhuashen.name,
      prompt = "#fei__jilvhuashen-use",
      cancelable = true,
      extra_data = {
        bypass_times = true,
        bypass_distances = true,
        extraUse = true,
      },
    })
    if not use then break end
    use.extraUse = true
    room:useCard(use)
  end
  if not player.dead then gainShadows(player) end
end

local function hpChangeSource(room, data)
  if data.damageEvent then return data.damageEvent.from end
  if data.hpLostEvent then return data.hpLostEvent.proposer end
  if data.reason == "recover" then
    local recover_event = room.logic:getCurrentEvent():findParent(GameEvent.Recover, true)
    if recover_event then return recover_event.data.recoverBy or recover_event.data.who end
  end
  return data.who
end

jilvhuashen:addEffect(fk.RoundStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jilvhuashen.name) and player.room:getBanner("RoundCount") == 1
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = jilvhuashen.name,
      prompt = "#fei__jilvhuashen-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    activate(player)
  end,
})

jilvhuashen:addEffect(fk.TargetSpecifying, {
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(jilvhuashen.name, true, true) and
      data.to and not data.to.dead
  end,
  on_refresh = function(self, event, target, player, data)
    local targets = { data.to }
    table.insertTableIfNeed(targets, data.subTargets or {})
    for _, to in ipairs(targets) do
      -- 装备、桃和酒由规则自动指向自己，不属于玩家实际指定自己。
      if not (to == player and (data.card.type == Card.TypeEquip or
        data.card.trueName == "peach" or data.card.trueName == "analeptic")) then
        player.room:addTableMarkIfNeed(to, target_mark, player.id)
      end
    end
  end,
})

jilvhuashen:addEffect(fk.HpChanged, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    local source = hpChangeSource(player.room, data)
    return source and player:hasSkill(jilvhuashen.name) and
      table.contains(source:getTableMark(target_mark), player.id) and
      not player:isKongcheng()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local source = hpChangeSource(room, data)
    if not source then return end
    local id = room:askToChooseCard(source, {
      target = player,
      flag = "h",
      skill_name = jilvhuashen.name,
      prompt = "#fei__jilvhuashen-recast::" .. player.id,
    })
    if not id then return end
    room:recastCard({ id }, player, jilvhuashen.name)
    if player.dead or hasShadow(player) then return end
    if room:askToSkillInvoke(player, {
      skill_name = jilvhuashen.name,
      prompt = "#fei__jilvhuashen-again",
    }) then
      if not player:isKongcheng() then player:showCards(player:getCardIds("h"), player) end
      activate(player)
    end
  end,
})

return jilvhuashen
