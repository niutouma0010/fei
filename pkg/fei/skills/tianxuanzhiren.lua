local tianxuanzhiren = fk.CreateSkill {
  name = "fei__tianxuanzhiren",
}

Fk:loadTranslationTable {
  ["fei__tianxuanzhiren"] = "天选之人",
  [":fei__tianxuanzhiren"] = "你可以发动“天命”或“鬼才”，然后将因此进入弃牌堆的牌置于场上或牌堆一端。",

  ["#fei__tianxuanzhiren-tianming"] = "天选之人（天命）：你可以弃置两张牌（不足则全弃，无牌则不弃），然后摸两张牌",
  ["#fei__tianxuanzhiren-guicai"] = "天选之人（鬼才）：你可以打出一张手牌替换 %dest 的判定牌",
  ["#fei__tianxuanzhiren-place"] = "天选之人：将 %arg 置于场上、牌堆顶或牌堆底",
  ["fei__tianxuanzhiren_field"] = "场上",
  ["fei__tianxuanzhiren_top"] = "牌堆顶",
  ["fei__tianxuanzhiren_bottom"] = "牌堆底",
}

tianxuanzhiren:addAuxActiveSkill("fei__tianxuanzhiren_place", {
  card_num = 0,
  min_target_num = 0,
  max_target_num = 1,
  interaction = UI.ComboBox {
    choices = {
      "fei__tianxuanzhiren_field",
      "fei__tianxuanzhiren_top",
      "fei__tianxuanzhiren_bottom",
    },
  },
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards, card, extra_data)
    if self.interaction.data ~= "fei__tianxuanzhiren_field" or
      #selected > 0 or not extra_data.card_id then
      return false
    end
    local placed_card = Fk:getCardById(extra_data.card_id)
    if placed_card.type == Card.TypeEquip then
      return to_select:hasEmptyEquipSlot(placed_card.sub_type)
    elseif placed_card.sub_type == Card.SubtypeDelayedTrick then
      return not to_select:isProhibited(to_select, placed_card) and
        not to_select:hasDelayedTrick(placed_card.name)
    end
    return false
  end,
  feasible = function(self, player, selected, selected_cards)
    if self.interaction.data == "fei__tianxuanzhiren_field" then
      return #selected == 1
    end
    return self.interaction.data == "fei__tianxuanzhiren_top" or
      self.interaction.data == "fei__tianxuanzhiren_bottom"
  end,
})

---@param player ServerPlayer
---@param cards integer[]
local function placeDiscardCards(player, cards)
  local room = player.room
  for _, id in ipairs(cards) do
    if player.dead then return end
    if room:getCardArea(id) == Card.DiscardPile then
      local card = Fk:getCardById(id)
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "fei__tianxuanzhiren_place",
        prompt = "#fei__tianxuanzhiren-place:::" .. card:toLogString(),
        cancelable = false,
        extra_data = { card_id = id },
      })
      if not (success and dat) then
        dat = {
          cards = { id },
          targets = {},
          interaction = "fei__tianxuanzhiren_top",
        }
      end

      if dat.interaction == "fei__tianxuanzhiren_field" then
        local to = dat.targets[1]
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
          drawPilePosition = dat.interaction == "fei__tianxuanzhiren_bottom" and -1 or 1,
        }
      end
    end
  end
end

tianxuanzhiren:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
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

return tianxuanzhiren
