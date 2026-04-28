# Agency

> What makes a human engineer 10x isn't raw skill — it's **agency**. The same turns out to be true of AI agents. This harness is named for the trait it's built to cultivate in them.

让 AI Agent 替你写代码，你只负责把关。

[English](README.md)

---

## 问题

如果你给 agent 写过 skill，你大概率经历过这些：

**写不完的过程式 workflow。** 开发任务一套流程，排查问题又一套，写测试再来一套。每套都是你手写的"第一步、第二步、第三步"，每一步都在替 agent 做决定。这些流程是天花板不是地板——agent 明明能做得更好，但被你的步骤限死了。而且它们会腐烂：模型一升级，你几个月前写的步骤可能就不适用了。

**效果不可验证的"神奇 prompt"。** 你往 prompt 里塞最佳实践、编码规范、行为引导，觉得应该有用。但 agent 代码写得好，到底是因为你那 500 token 的编码规范，还是没有它也一样？你积累了一堆谁也不敢删的 prompt，因为谁也证明不了它到底有没有用。

**瓶颈是你，不是 agent。** 没有结构的话，每个决策都要过你。Agent 有推理和行动能力，但它闲着等你下一条指令。真正的约束不是 agent 的能力——是你的带宽。

## 解决方案

Agency 建立在几条实践中摸索出来的原则上：

1. **声明式而非过程式** — 定义边界（质量门、退出标准），不定义步骤。Agent 自己选路径。不要告诉它*怎么*干活。
2. **默认最小化** — 不要告诉 agent 它已经知道的东西。每一条注入的上下文都必须通过实际观察证明有价值，不能靠猜。
3. **自底向上生长** — 起步几乎为空。知识从真实错误中积累，不靠提前预判。如果下一代模型不用你帮就能搞定，你写的 skill 就是多余的。
4. **高自主性 + 护栏** — Agent 自主驱动，你只在阶段边界审查。在约束内给予最大自由。

```
不用 Agency:   你写代码，AI 打辅助     →  每个决策都过你
用了 Agency:   AI 写代码，你当管理者   →  你只在质量门出现
```

结果是：agent 可以连续跑几个小时——研究代码、做设计、写实现、跑评审——在约束下自主运行，不需要你一直盯着。你在质量门看一眼，不用每一步都参与。而且每个 agent 独立运行，你可以同时管多个 agent 干多件事，就像 tech lead 带团队一样。

### Agent 自己搞定的事

- 自己研究代码库，不问你"某某在哪里"
- 自己提出目标和计划，不问你"我应该怎么做"
- 在约束内自己做设计决策，不问你"选 A 还是选 B"
- 并行派出多个子 agent 实现，不会一个一个串行
- 交给你之前先自己跑构建、测试、自查
- 犯了错主动反思总结，不用你催
- 需要你决策时带着背景、选项和建议来——不问空泛的问题

### Agent 停下来等你的时刻

强制检查点。Agent 做完一个阶段的工作后必须停下来汇报，你审批通过后它才继续。检查点之间完全自主。

```
你: "给用户列表 API 加分页"
  │
  ▼
Agent 研究代码库 ──────────► "我理解的需求是这样，计划是这样"
  │                                          你: ✓ 没问题
  ▼
Agent 做方案设计 ──────────► "推荐方案 A，也考虑了方案 B"
  │                                          你: ✓ 按 A 来
  ▼
Agent 实现并自查 ──────────► "代码评审通过，有几个发现"
  │                                          你: ✓ 可以
  ▼
Agent 准备 PR ─────────────► "准备好了，请过目"
                                             你: ✓ 合入
```

Agency 是纯 Markdown，没有运行时，没有依赖，不绑定平台。任何支持 skills 和子 agent 的编码 agent 都能用。Claude Code 和 Codex 开箱即用，Cursor、Gemini 等只需要简单适配。

## 核心机制

### 质量门与升级

自主性高不代表失控。LLM 的输出是概率性的，长任务中每一步都可能轻微偏离你的意图。没有检查点的话，偏差会滚雪球——agent 基于一个错误的需求理解埋头干了几个小时，你到最后才发现方向错了，纠错成本最高。

Agency 用两个机制解决：

**质量门**是阶段之间的检查点——错误最好抓、漏掉代价最大的时刻。Agent 在门之间自由发挥，到了门必须停下来汇报。你看一眼，有问题就纠偏，没问题就放行。

其中两个门是**始终强制**的：**计划审批**（规划完毕、动手之前）和 **Final Review / PR 提交**（宣告完成之前）。下面表格里是**条件门**——任务需要时触发，不需要时标 N/A 并说明原因。

| 质量门 | 拦住什么 |
|--------|---------|
| 需求理解 | 理解偏差、遗漏范围、错误假设 |
| 方案设计 | 架构问题、没考虑备选方案 |
| 测试计划 | 覆盖不足、策略不对 |
| 运维/可观测 | 缺监控、配置问题、上线风险 |
| 代码评审 | 实现 bug、规范问题、安全隐患 |

修 bug 可能只在强制双门之外加一个代码评审；新功能通常会全走一遍。Agent 在 `plan.md` 里提议哪些门适用，由你拍板。

**临时升级**处理门与门之间的意外。遇到没有明确答案的权衡、缺少权限、或者真的拿不准，agent 会带着背景、选项和建议找你——不会丢一个"你觉得怎么办"过来。你拍板，它继续。

两个机制合力：agent 能做好的决策完全自主，只有真正需要人类判断的时候才到你这里。

### 跨模型协作

Claude 和 Codex 可以默认协同工作——两个模型独立判断能发现单一模型会漏掉的盲点：

- **审查模式**：主 agent 实现，同伴 agent 审查变更
- **并行模式**：两个模型独立处理同一问题，然后比较——减少盲点和锚定偏差

安装跨模型协作后，在每个质量门前，主 agent 必须先和同伴 agent 达成共识。你看到的始终是统一意见，而不是两边未解决的分歧。

### 基于约束的编排

没有固定流水线。Agent 在四个约束的空间内自由导航：

```
                    ┌──────────────┐
                    │  退出         │  "做完了吗？"
                    │  标准         │  （牵引向完成）
                    └──────┬───────┘
                           │
    ┌──────────────┐       │       ┌──────────────┐
    │  质量         │◄──────┼──────►│  领域        │
    │  门          │       │       │  知识         │
    │  （护栏）     │       │       │  （标准）      │
    └──────────────┘       │       └──────────────┘
                           │
                    ┌──────┴───────┐
                    │  操作         │  "该怎么做事？"
                    │  原则         │  （文化与判断）
                    └──────────────┘
```

Agent 自己选方法、定顺序、挑工具——只要不越界。

## 快速开始

告诉你的 agent：

```
"从 https://github.com/davidYichengWei/Agency 安装 Agency harness——
 clone 下来，读 README，跑 install.sh，然后读装好的根指令、rules 和 skills，
 搞清楚你以后该怎么干活。"
```

默认安装 Claude 作为主 agent，Codex 作为协作者。也可以显式选择主 agent：

```bash
./install.sh --main claude           # Claude main + Codex collaborator
./install.sh --main codex            # Codex main + Claude collaborator
./install.sh --main codex --single   # 只安装 Codex 行为，不追加跨模型协作
./install.sh --reverse --main claude # 将 live skills/rules 反向同步回仓库
```

搞定。Agent 自己装好并学会自己的工作方式。之后直接派活：

```
"修一下连接池的竞态条件"
"给公开 API 加上限流"
"查一下为什么昨天查询延迟飙了"
```

Agent 自己研究、规划、执行，到质量门停下来等你审批。

## 架构

```
Agency/
├── shared/                    # 跨 agent 共享的资源
│   ├── rules/                 # 始终生效的行为约束
│   │   ├── activity-tracking.md
│   │   ├── escalation.md
│   │   ├── measurement-driven-analysis.md
│   │   └── receiving-feedback.md
│   ├── agents/                # 子 agent
│   │   ├── researcher.md          # 只读代码探索
│   │   ├── implementer.md         # 隔离环境中写代码
│   │   ├── reviewer-*.md          # 多维度代码审查（规范、标准、健壮性、性能、证明义务）
│   │   └── validator.md           # 独立验证完成的工作
│   ├── skills/                # 按需加载
│   │   ├── planning/              # plan.md
│   │   ├── requirements-clarification/  # spec.md 前半段
│   │   ├── system-design/         # spec.md 后半段
│   │   ├── task-planning/         # tasks.md 任务拆解
│   │   ├── code-review/           # 多 agent 代码评审
│   │   ├── codex-collaboration/   # 跨模型共识协议
│   │   ├── claude-collaboration/  # 跨模型共识协议
│   │   ├── process-cr-comments/   # 处理 PR 评审意见
│   │   ├── consolidate-agent-dir/ # 清理 .agent 任务目录
│   │   └── reflect/               # 从错误与经验中总结
│   └── PROJECT.md             # （可选）项目专属上下文，安装时自动追加到 CLAUDE.md / AGENTS.md
├── claude/
│   ├── CLAUDE-main.md         # Claude 作为主 agent
│   ├── CLAUDE-collaborator.md # Claude 作为同伴审查/分析 agent
│   └── cross-model-codex.md   # Codex 作为同伴时追加的协作说明
├── codex/
│   ├── AGENTS-main.md         # Codex 作为主 agent
│   ├── AGENTS-collaborator.md # Codex 作为同伴审查/分析 agent
│   └── cross-model-claude.md  # Claude 作为同伴时追加的协作说明
└── install.sh                 # 安装与同步脚本
```

### 三层结构

```
┌─────────────────────────────────────────────┐
│       第三层：领域知识                        │
│  项目特有的 skills（实践中积累或手动添加）     │
├─────────────────────────────────────────────┤
│       第二层：交付物模板                      │
│  需求澄清、方案设计、任务拆解的结构化模板     │
├─────────────────────────────────────────────┤
│       第一层：核心 Harness                    │
│  编排、质量门、升级、活动追踪、反思             │
├─────────────────────────────────────────────┤
│       第零层：Agent 运行时                    │
│  Claude Code、Codex 或其他兼容 agent          │
└─────────────────────────────────────────────┘
```

第一层随 Agency 发布。第二层提供常用交付物的模板。第三层初始为空，用着用着就长出来了。

## 定制

### 添加项目知识

Agency 出厂不带任何项目特定知识——通用的软件工程知识模型本身就会。只在你发现 agent 反复踩同一个坑的时候才加 skill：

```bash
mkdir -p ~/.claude/skills/my-convention/
cat > ~/.claude/skills/my-convention/SKILL.md << 'EOF'
---
name: my-convention
description: Our project's naming conventions for database models
---
# My Convention
...
EOF
```

### 自底向上生长

reflect skill 会把错误教训记到 `reflection.md`。同一个模式反复出现时，你把它提升为持久化的 rule 或 skill：

```
Day 0:  只有核心 harness
        ↓ agent 干活，踩坑
Day N:  reflection.md 记下 "又忘了检查向后兼容"
        ↓ 你看了觉得确实该加条规则
Day M:  harness 自然长出了一套领域知识
        都是这个项目真正需要的，不是臆想的
```

## 兼容性

Agency 就是 Markdown + YAML frontmatter，适配任何支持以下能力的 agent：
- **Claude Code**：skills、rules、自定义 agents（`~/.claude/`）
- **Codex**：AGENTS.md、自定义 agents（`~/.codex/`）
- **其他**：把 Markdown 文件复制到你的 agent 配置目录就行

## 许可证

[MIT](LICENSE)
