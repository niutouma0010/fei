// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import Fk
import Fk.Components.Common
import LunarLtk

Column {
  id: root

  required property PhotoModel dataModel
  property string kingdom: ""
  property var colors: ["#F4180E", "#F4180E", "#E3B006", "#25EC27"]

  // 非人勾玉遵循新月杀原版：满血为绿，其他状态按体力百分比分为绿/黄/红三档。
  function getMagatamaState() {
    const hp = dataModel.hp;
    const maxHp = dataModel.maxHp;
    if (kingdom === "fei_kingdom") {
      if (hp <= 0 || maxHp <= 0) return 0;
      if (hp >= maxHp) return 5;
      return Math.max(0, Math.ceil(hp / maxHp * 3) * 2 - 1);
    }
    return (hp >= 3 || hp >= maxHp) ? 3 : (hp <= 0 ? 0 : hp);
  }

  Shield {
    id: shield
    value: root.dataModel.shield
  }

  Repeater {
    id: repeater
    model: column.visible ? 0 : root.dataModel.maxHp
    Magatama {
      kingdom: root.kingdom
      state: {
        const value = root.dataModel.hp;
        const maxValue = root.dataModel.maxHp;
        if (maxValue - 1 - index >= value) {
          return 0;
        } else {
          return root.getMagatamaState();
        }
      }
    }
  }

  Column {
    id: column
    visible: {
      const maxHp = root.dataModel.maxHp;
      const hp = root.dataModel.maxHp;
      const shield = root.dataModel.shield;
      return maxHp > 4 || hp > maxHp || (shield > 0 && maxHp > 3)
    }
    spacing: -4

    Magatama {
      kingdom: root.kingdom
      state: {
        return root.getMagatamaState();
      }
    }

    GlowText {
      id: hpItem
      width: root.width
      text: root.dataModel.hp
      color: {
        if (root.kingdom === "fei_kingdom") {
          return ["#e90000", "#e92222", "#e97422", "#c3c322", "#8dc322", "#42ae22"][root.getMagatamaState()];
        }
        let idx;
        const hp = root.dataModel.hp;
        const maxHp = root.dataModel.maxHp;
        if (hp >= 3 || hp >= maxHp) {
          idx = 3;
        } else if (hp <= 0) {
          idx = 0;
        } else {
          idx = hp;
        }
        return root.colors[idx];
      }
      font.family: Config.libianName
      font.pixelSize: 16
      font.bold: true
      horizontalAlignment: Text.AlignHCenter

      glow.color: root.kingdom === "fei_kingdom" ? "transparent" : "#3E3F47"
      glow.spread: root.kingdom === "fei_kingdom" ? 0 : 0.8
      glow.radius: root.kingdom === "fei_kingdom" ? 0 : 6
      //glow.samples: 12
    }

    GlowText {
      id: splitter
      height: 12
      width: root.width
      text: "/"
      z: -10
      rotation: 40
      color: hpItem.color
      font.family: Config.libianName
      font.pixelSize: 14
      font.bold: true
      horizontalAlignment: hpItem.horizontalAlignment

      glow.color: hpItem.glow.color
      glow.spread: hpItem.glow.spread
      glow.radius: hpItem.glow.radius
      //glow.samples: hpItem.glow.samples
    }

    GlowText {
      id: maxHpItem
      width: root.width
      text: root.dataModel.maxHp
      color: hpItem.color
      font: hpItem.font
      horizontalAlignment: hpItem.horizontalAlignment

      glow.color: hpItem.glow.color
      glow.spread: hpItem.glow.spread
      glow.radius: hpItem.glow.radius
      //glow.samples: hpItem.glow.samples
    }
  }
}
