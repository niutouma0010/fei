local tianxuanzhiren = fk.CreateSkill {
  name = "fei__tianxuanzhiren",
}

Fk:loadTranslationTable {
  ["fei__tianxuanzhiren"] = "天选之人",
  [":fei__tianxuanzhiren"] = "你可以发动“天命”或“鬼才”，然后将因此进入弃牌堆的牌置于场上或牌堆一端中各一处。",

  ["#fei__tianxuanzhiren-tianming"] = "天选之人（天命）：你可以弃置两张牌（不足则全弃，无牌则不弃），然后摸两张牌",
  ["#fei__tianxuanzhiren-guicai"] = "天选之人（鬼才）：你可以打出一张手牌替换 %dest 的判定牌",
  ["#fei__tianxuanzhiren-place"] = "天选之人：将 %arg 置于场上、牌堆顶或牌堆底",
  ["fei__tianxuanzhiren_field"] = "场上",
  ["fei__tianxuanzhiren_top"] = "牌堆顶",
  ["fei__tianxuanzhiren_bottom"] = "牌堆底",
}

---@param player ServerPlayer
---@param cards integer[]
local function placeDiscardCards(player, cards)
  local room = player.room
  local used_places = {}
  for _, id in ipairs(cards) do
    if player.dead then return end
    if room:getCardArea(id) == Card.DiscardPile then
      local card = Fk:getCardById(id)
      local choices = table.filter({
        "fei__tianxuanzhiren_field",
        "fei__tianxuanzhiren_top",
        "fei__tianxuanzhiren_bottom",
      }, function(choice) return not used_places[choice] end)
      local field_targets = table.filter(room.alive_players, function(p)
        if card.type == Card.TypeEquip then
          return p:hasEmptyEquipSlot(card.sub_type)
        elseif card.sub_type == Card.SubtypeDelayedTrick then
          return not p:isProhibited(p, card) and not p:hasDelayedTrick(card.name)
        end
        return false
      end)
      if #field_targets == 0 then table.removeOne(choices, "fei__tianxuanzhiren_field") end
      if #choices == 0 then break end

      local place = room:askToChoice(player, {
        choices = choices,
        skill_name = tianxuanzhiren.name,
        prompt = "#fei__tianxuanzhiren-place:::" .. card:toLogString(),
      })

      if place == "fei__tianxuanzhiren_field" then
        local tos = room:askToChoosePlayers(player, {
          targets = field_targets,
          min_num = 1,
          max_num = 1,
          prompt = "#fei__tianxuanzhiren-place:::" .. card:toLogString(),
          skill_name = tianxuanzhiren.name,
          cancelable = false,
        })
        local to = tos[1]
        if card.type == Card.TypeEquip then
          room:moveCardIntoEquip(to, id, tianxuanzhiren.name, false, player)
        elseif card.sub_type == Card.SubtypeDelayedTrick then
          room:moveCardTo(id, Card.PlayerJudge, to, fk.ReasonPut,
            tianxuanzhiren.name, nil, true, player)
        end
      else
        room:moveCards {
          ids = { id },
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = tianxuanzhiren.name,
          proposer = player,
          moveVisible = true,
          drawPilePosition = place == "fei__tianxuanzhiren_bottom" and -1 or 1,
        }
      end
      used_places[place] = true
    end
  end
end

tianxuanzhiren:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  audio_index = { 1, 2 },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tianxuanzhiren.name) and
      data.card and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = table.filter(player:getCardIds("he"), function(id)
      return not player:prohibitDiscard(id)
    end)
    if #ids <= 2 then
      if room:askToSkillInvoke(player, {
        skill_name = tianxuanzhiren.name,
        prompt = "#fei__tianxuanzhiren-tianming",
      }) then
        event:setCostData(self, { cards = ids })
        return true
      end
    else
      local cards = room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = tianxuanzhiren.name,
        cancelable = true,
        prompt = "#fei__tianxuanzhiren-tianming",
        skip = true,
      })
      if #cards > 0 then
        event:setCostData(self, { cards = cards })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local discarded = table.simpleClone(event:getCostData(self).cards)
    if #discarded > 0 then
      room:throwCard(discarded, tianxuanzhiren.name, player, player)
    end
    if not player.dead then
      player:drawCards(2, tianxuanzhiren.name)
    end

    local highest = table.filter(room.alive_players, function(p)
      return table.every(room.alive_players, function(q)
        return p.hp >= q.hp
      end)
    end)
    if #highest == 1 and highest[1] ~= player then
      local to = highest[1]
      local ids = table.filter(to:getCardIds("he"), function(id)
        return not to:prohibitDiscard(id)
      end)
      local cards = {}
      if #ids <= 2 then
        if room:askToSkillInvoke(to, {
          skill_name = tianxuanzhiren.name,
          prompt = "#fei__tianxuanzhiren-tianming",
        }) then
          cards = ids
          if #cards > 0 then
            room:throwCard(cards, tianxuanzhiren.name, to, to)
          end
          if not to.dead then
            to:drawCards(2, tianxuanzhiren.name)
          end
        end
      else
        cards = room:askToDiscard(to, {
          min_num = 2,
          max_num = 2,
          include_equip = true,
          skill_name = tianxuanzhiren.name,
          cancelable = true,
          prompt = "#fei__tianxuanzhiren-tianming",
        })
        if #cards == 2 and not to.dead then
          to:drawCards(2, tianxuanzhiren.name)
        end
      end
      table.insertTableIfNeed(discarded, cards)
    end

    placeDiscardCards(player, discarded)
  end,
})

tianxuanzhiren:addEffect(fk.AskForRetrial, {
  anim_type = "control",
  audio_index = { 3, 4 },
  guicai = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tianxuanzhiren.name) and #player:getHandlyIds() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local ids = table.filter(player:getHandlyIds(), function(id)
      return not player:prohibitResponse(Fk:getCardById(id))
    end)
    local cards = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      skill_name = tianxuanzhiren.name,
      pattern = tostring(Exppattern { id = ids }),
      prompt = "#fei__tianxuanzhiren-guicai::" .. target.id,
      expand_pile = player:getHandlyIds(false),
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local old_id = data.card:getEffectiveId()
    local new_id = event:getCostData(self).cards[1]
    local judge_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Judge)
    player.room:changeJudge {
      card = Fk:getCardById(new_id),
      player = player,
      data = data,
      skillName = tianxuanzhiren.name,
      response = true,
    }

    local cards = { new_id }
    if old_id then
      table.insert(cards, old_id)
    end
    if judge_event then
      -- changeJudge会立即弃置原判定牌，而改判牌要等判定事件清理时才弃置。
      -- 挂在判定事件的清理回调中，确保两张牌均已进入弃牌堆后再处理。
      judge_event:addCleaner(function()
        placeDiscardCards(player, cards)
      end)
    else
      -- 理论上AskForRetrial总处于判定事件内；保留兜底以免异常流程漏掉原判定牌。
      placeDiscardCards(player, cards)
    end
  end,
})

-- 雷震子使用【杀】时播放其专属牌语音；此效果本身静默，避免重复播放技能语音。
tianxuanzhiren:addEffect(fk.CardUsing, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tianxuanzhiren.name, true, true) and
      data.card and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:broadcastPlaySound("./packages/fei/audio/skill/fei__leizhenzi_slash")
  end,
})

return tianxuanzhiren
