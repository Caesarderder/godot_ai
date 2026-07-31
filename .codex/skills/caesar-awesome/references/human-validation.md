# Workbench 浏览器真人验证

用于把需要真人完成的学习验证、可用性观察或操作测试放进 Workbench HTML。它提供统一的
主持界面、秒表、逐字答案记录、误触/求助/阻碍采集、仓库落盘和 JSON 导出。

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

## 3. 浏览器主持

1. 填写匿名参与者编号、设备和浏览器。
2. 每个任务展示稳定后点“开始”。
3. 参与者首次说出一个维度的答案时，逐字填写并点该行“记录”。
4. 补充误触次数、是否求助和可见阻碍。
5. 点“保存本次记录”。服务模式原子写入
   `docs/workbench/human-validation/<validation-id>/sessions/*.json`；静态 HTML
   则下载同结构 JSON。

页面汇总已保存人数与两秒通过数。`passed_two_second` 只有在该 session 所有要求维度
均不超过 2 秒时为真；这是显示用摘要，正式结论仍由验证合同和受管 Evidence 决定。

## 4. 验证与交接

```bash
python3 .codex/skills/caesar-awesome/scripts/test_workbench_hq.py
python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py render
```

交接时报告 spec 路径、session 目录、完成样本数、通过数和任何偏离主持条件的记录。不得只
报告汇总数字而隐藏失败、求助或阻碍。
