// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import Fk
import Fk.Components.Common

import LunarLtk.Pages.Popups
import "models"

GraphicsBox {
  id: root

  required property ChooseCardNamesModel dataModel

  readonly property int lines: dataModel.lines

  title.text: dataModel.promptText
  width: 600
  height: lines * 45 + title.height + 10 + 60

  Component {
    id: innerGridComponent
    GridLayout {
      id: gridLayout
      required property var modelData
      columns: Math.ceil(modelData.length / lines)  // 计算列数
      columnSpacing: 10  // 列间距
      rowSpacing: 10     // 行间距

      Repeater {
        id: cardRepeater
        model: parent.modelData

        delegate: Rectangle {
          id: cardItem
          required property string modelData
          width: 80
          height: 35
          clip: true
          border {
            color: "#FEF7D6"  // 边框颜色
            width: 2          // 边框宽度
          }
          radius: 2  // 圆角半径

          // 自定义属性
          property string name: modelData               // 卡牌名称
          property int num: root.dataModel.getSelectionCount(modelData)

          enabled: root.dataModel.isChoiceEnabled(modelData)

          // 阴影效果
          layer.effect: DropShadow {
            color: "#845422"  // 阴影颜色
            radius: 5         // 阴影半径
            samples: 25       // 阴影采样数
            spread: 0.7       // 阴影扩散度
          }

          // 卡牌图片区域
          Rectangle {
            id: cardImageArea
            anchors.centerIn: parent
            width: parent.width - 4
            height: parent.height - 4
            color: "transparent"
            clip: true

            // 卡牌图片
            Image {
              id: cardImage
              anchors.fill: parent
              anchors.topMargin: -20  // 上边距调整
              source: SkinBank.getCardPicture(cardItem.modelData)
              fillMode: Image.PreserveAspectCrop
              scale: 1.05
            }
          }

          // 不可选状态的灰罩
          Rectangle {
            id: cardGrey
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.7)  // 半透明黑色
            opacity: 0.7
            visible: !parent.enabled      // 不可选时显示
            z: 2                          // 置顶显示
          }

          // 重复选择计数标记
          Item {
            width: parent.width / 2
            height: 16
            visible: root.dataModel.repeatable && num !== 0  // 可重复选择且有选择次数时显示

            // 标记背景
            Rectangle {
              id: mark_rect
              width: mark_text.width + 12
              height: 16
              radius: 4
              // 渐变背景
              gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.7; color: "#A50330" }
                GradientStop { position: 1.0; color: "transparent" }
              }
            }

            // 计数文本
            Text {
              id: mark_text
              x: 2
              font {
                pixelSize: 16
                family: Config.libianName
                letterSpacing: -0.6
              }
              text: "×" + num.toString()
              color: "white"
              style: Text.Outline
              styleColor: "purple"
            }
          }

          // 选中标记（非重复选择模式）
          Image {
            id: chosen
            visible: !root.dataModel.repeatable && num > 0  // 非重复模式且已选中时显示
            source: SkinBank.cardDir + "chosen"
            anchors.horizontalCenter: parent.horizontalCenter
            y: -5
            scale: 0.8
            z: 1
          }

          // 卡牌名称文本
          GlowText {
            id: cardName
            text: Lua.tr(cardItem.modelData)  // 本地化文本
            font {
              family: Config.li2Name
              pixelSize: 15
              bold: true
            }
            color: "#111111"
            glow {
              color: "#EEEEEE"
              spread: 0.6
            }
            anchors {
              bottom: parent.bottom
              right: parent.right
              rightMargin: 1
            }
          }

          // 鼠标点击区域
          MouseArea {
            anchors.fill: parent
            enabled: cardItem.enabled  // 仅当卡牌可选时启用

            // 点击事件处理
            onClicked: {
              root.dataModel.toggleChoose(cardItem.modelData);

              // 如果是单选且不可取消，Model 会自动触发 accepted 信号
              // 这里只需要处理界面关闭
              if (root.dataModel.minNum === 1 && root.dataModel.maxNum === 1 && 
              !root.dataModel.cancelable && root.dataModel.result.length === 1) {
                root.dataModel.accepted();
              }
            }
          }
        }
      }
    }
  }

  Flickable {
    id: flickableContainer
    contentWidth: cardArea.implicitWidth
    contentHeight: cardArea.implicitHeight
    
    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
      bottom: buttonArea.top
      topMargin: title.height
      leftMargin: Math.max(10, (parent.width - contentWidth) / 2)
      rightMargin: 10
      bottomMargin: 10
      fill: parent
    }
    
    flickableDirection: Flickable.HorizontalFlick
    interactive: contentWidth > width
    clip: true
    
    Row {
      id: cardArea
      anchors {
        horizontalCenter: parent.horizontalCenter  // 水平居中
        top: parent.top                            // 顶部对齐
        topMargin: 10                              // 可选的顶部边距
      }
      spacing: 20  // 卡牌组间距

      // 重复器：遍历所有卡牌组
      Repeater {
        id: areaRepeater
        model: root.dataModel.allChoices
        
        delegate: innerGridComponent
      }
    }
  }

  // 按钮区域
  Item {
    id: buttonArea
    anchors {
      topMargin: 10
      bottomMargin: 10
      fill: parent
    }
    height: 40
    visible: (root.dataModel.minNum != 1 || root.dataModel.maxNum != 1 || 
              root.dataModel.cancelable || root.dataModel.repeatable)
    
    // 按钮行
    Row {
      anchors {
        horizontalCenter: parent.horizontalCenter
        bottom: parent.bottom
      }
      spacing: 30

      // 清空按钮
      MetroButton {
        id: buttonClear
        Layout.fillWidth: true
        enabled: root.dataModel.result.length > 0
        opacity: enabled ? 1.0 : 0  // 禁用时完全透明
        text: Lua.tr("Clear All")
        
        // 点击事件：清空所有选择
        onClicked: {
          root.dataModel.clearAll();
        }
      }

      // 确认按钮
      MetroButton {
        id: buttonConfirm
        width: 120
        Layout.fillWidth: true
        text: Lua.tr("OK")
        enabled: root.dataModel.feasible  // 达到最小选择数时才可用
        
        onClicked: {
          root.dataModel.accepted();
        }
      }

      // 取消按钮
      MetroButton {
        id: buttonCancel
        Layout.fillWidth: true
        text: Lua.tr("Cancel")
        enabled: root.dataModel.cancelable  // 仅在可取消时可用
        
        onClicked: {
          root.dataModel.rejected();
        }
      }
    }
  }
}
