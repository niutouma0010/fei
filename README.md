# fei

“非人学园”武将扩展，代码名暂定为 `fei`。

## 目录

- `init.lua`：扩展入口。
- `pkg/fei/init.lua`：武将包入口与武将注册。
- `pkg/fei/skills/`：每个技能的独立 Lua 实现。
- `image/generals/`：武将立绘，文件名与武将代码名一致。
- `audio/skill/`：技能语音。
- `audio/death/`：阵亡语音。
- `audio/win/`：胜利语音。

武将与技能将按 `FEI001` 至 `FEI127` 的清单逐批加入。武将代码名和技能代码名统一使用 `fei__` 前缀。
所有武将统一使用势力代码 `fei_kingdom`，游戏内显示为“非”。
