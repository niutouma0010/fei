# fei_core

非人学园服务器专用的独立客户端 UI 包。

本包通过 FreeKill 的 `UIPackage` 接口加载自定义对局页面，不替换、不修改玩家已有的
`packages/freekill-core`，从而避免自定义核心提交与官方仓库提交无法互相获取的问题。
