local shownCards = fk.CreateSkill {
  name = "#fei__shown_cards",
}

-- 采用帝辛的明置牌可见性实现。只要牌仍带有明置标记，所有客户端在
-- 手牌区以及其他角色操作这些牌时都会得到真实牌面，而非仅由牌主可见。
shownCards:addEffect("visibility", {
  card_visible = function(self, player, card)
    if card:getMark(MarkEnum.ShownCards) > 0 then return true end
    if table.find(MarkEnum.TempMarkSuffix, function(suffix)
      return card:getMark(MarkEnum.ShownCards .. suffix) > 0
    end) then
      return true
    end
  end,
})

return shownCards
