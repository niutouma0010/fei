// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import Fk

Item {
  id: root
  property string kingdom: ""
  state: "3"

  // 槽位尺寸始终固定。非人勾玉的每一种血量状态都是一张完整成品图，
  // 不再将底图、顶图、描边叠加或缩放，因此不会有任一层被拉伸或压缩。
  width: 12
  height: 14

  function feiMagatamaSource() {
    const suffix = ({
      "0": "0-disabled",
      "1": "1-red",
      "2": "2-orange",
      "3": "3-yellow",
      "4": "4-lime",
      "5": "5-green"
    })[String(root.state)] || "0-disabled";
    return SkinBank.searchPkgResourceWithExtension(
      "fei", "/image/kingdom/magatama/", suffix, ".png");
  }

  Image {
    anchors.fill: parent
    source: root.kingdom === "fei_kingdom"
      ? root.feiMagatamaSource()
      : SkinBank.getPhotoMagatama(root.kingdom, Number(root.state))
    fillMode: Image.PreserveAspectFit
    horizontalAlignment: Image.AlignHCenter
    verticalAlignment: Image.AlignVCenter
    smooth: true
  }
}
