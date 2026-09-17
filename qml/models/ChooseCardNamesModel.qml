// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import Fk
import LunarLtk

QtObject {
  id: root

  // 可选的卡牌名称列表
  property list<var> choices: []
  
  // 所有卡牌名称的二维数组
  property list<var> allChoices: []
  
  // 最少选择数量
  property int minNum: 0
  
  // 最多选择数量
  property int maxNum: 0
  
  // 提示文本
  property string prompt: ""
  
  // 是否可取消
  property bool cancelable: false
  
  // 是否可重复选择同一卡牌
  property bool repeatable: false
  
  // 已选中的卡牌列表
  property list<var> result: []
  
  signal accepted()
  signal rejected()

  readonly property string promptText: Ltk.processPrompt(prompt || "#ChooseCardNames")

  readonly property bool feasible: {
    const len = result.length;
    return len >= minNum && len <= maxNum;
  }

  // 计算矩阵行长度紧凑布局的函数
  function processMatrixRowLengthCompact(matrix) {
    const arr1 = matrix.map(row => row?.length || 0);
    if (arr1.length === 0) return 0;
    
    const arr2 = arr1.map(v => v < 5 ? v : v < 9 ? 3 : Math.floor(Math.sqrt(v)));
    const max2 = Math.max(...arr2);
    if (max2 === 0) return 0;
    
    const sum = arr1.reduce((t, v) => t + Math.ceil(v / max2) * max2, 0);
    const sqrtSum = Math.floor(Math.sqrt(sum));
    
    return sqrtSum > 5 ? 6 : sqrtSum < 4 ? Math.max(sqrtSum, Math.max(...arr2)) : sqrtSum;
  }

  // 获取计算后的行数
  readonly property int lines: processMatrixRowLengthCompact(allChoices)

  // 切换选择卡牌
  function toggleChoose(choice) {
    if (!choices.includes(choice)) {
      return;
    }

    if (repeatable) {
      // 重复选择模式
      if (result.length < maxNum) {
        result.push(choice);
      }
    } else {
      // 普通选择模式
      const idx = result.indexOf(choice);
      if (idx !== -1) {
        // 取消选择
        result.splice(idx, 1);
      } else if (result.length < maxNum) {
        // 选择卡牌
        result.push(choice);
      }
    }

    // 如果是单选且不可取消，自动确认
    if (minNum === 1 && maxNum === 1 && !cancelable && result.length === 1) {
      accepted();
    }
  }

  // 清空所有选择
  function clearAll() {
    result = [];
  }

  // 获取卡牌的选择次数
  function getSelectionCount(choice) {
    return result.filter(x => x === choice).length;
  }

  // 检查卡牌是否可选
  function isChoiceEnabled(choice) {
    if (!choices.includes(choice)) {
      return false;
    }
    
    if (repeatable) {
      return result.length < maxNum;
    } else {
      return result.includes(choice) || result.length < maxNum;
    }
  }
}
