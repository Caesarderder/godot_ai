# Workbench 浏览器真人验证

用于把需要真人完成的学习验证、可用性观察或操作测试放进 Workbench HTML。默认交互必须是
极简反馈链：一次只展示一个问题，用户只选“满意 / 要修改”，再按需补充一句自然语言。
设备、浏览器、计时和结构化归档由页面自动处理，不要求用户充当测试记录员。

## 边界

- 浏览器 session 是原始观察数据，不是 Caesar Loop Evidence。
- 保存 session 不得自动修改 gate、finding、iteration 或 Loop 状态。
- 负责人审查样本量、测试条件和原始记录后，仍须通过受管
  `caesar_artifacts.py evidence-append` 命令登记正式证据。
- 只收集匿名参与者编号、设备和浏览器；不要在 spec 或 session 中收集姓名、邮箱等个人信息。

## 1. 编写验证 spec

在仓库内创建 JSON 文件：

```json
{
  "validation_id": "mobile-ui-learning-v1",
  "title": "移动 UI 两秒理解验证",
  "run_id": "mobile-ui-refresh",
  "gate_id": "gate_player_learning",
  "participant_target": 5,
  "pass_threshold": 4,
  "instructions": [
    "使用新存档，主持人不讲解界面。",
    "每个任务点击开始后，逐字记录参与者首次回答。"
  ],
  "tasks": [
    {
      "task_id": "battle",
      "title": "战斗界面",
      "prompt": "请说出目标、最大风险和下一步操作。",
      "dimensions": ["goal", "risk", "action"]
    }
  ]
}
```

`validation_id` 和 `task_id` 只能使用字母、数字、点、下划线和连字符。`dimensions`
只接受不重复的 `goal`、`risk`、`action`。阈值必须为 `1..participant_target`。

## 2. 同步并打开

```bash
python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py validation-sync \
  --input ".caesar-input/mobile-ui-learning.json"

python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py serve
```

`validation-sync` 校验 spec，将 `validation #<validation_id>` fence 写入
`docs/workbench/hq.md`，并重建 HTML。`serve` 只监听 `127.0.0.1`，打开带随机会话
token 的页面。

## 3. 浏览器反馈

1. 每次只看一个界面或结果，以及一个直接问题。
2. 选择“满意”或“要修改”。
3. 只有需要解释时才补充一句自然语言；说明永远可选。
4. 点下一步，完成全部问题后一次提交。服务模式原子写入
   `docs/workbench/human-validation/<validation-id>/sessions/*.json`；静态 HTML
   则下载同结构 JSON。

页面只汇总“满意 / 要修改”，不向用户展示内部 schema、设备字段或秒表。旧版逐维度计时
session 仍可读取；新反馈 session 只有所有问题均为 `approve` 时摘要为满意。正式结论仍由
验证合同和受管 Evidence 决定。

## 交互原则

- 一个屏幕只做一个判断，不把研究表格暴露给用户。
- 默认只有两个明确选择，补充文字可选。
- 自然语言反馈优先，后台再结构化；不得要求用户理解 gate、run、dimension 等内部术语。
- 评价对象必须与问题相邻，避免用户在页面和说明文档之间来回寻找。
- 保存前可以返回修改；切换 Workbench Tab 不得丢失当前反馈。

## 4. 验证与交接

```bash
python3 .codex/skills/caesar-awesome/scripts/test_workbench_hq.py
python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py render
```

交接时报告 spec 路径、session 目录、完成样本数、通过数和任何偏离主持条件的记录。不得只
报告汇总数字而隐藏失败、求助或阻碍。
