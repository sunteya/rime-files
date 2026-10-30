# KeyTao 接续组词

`phrase_combiner` 是 KeyTao 的长词组查询扩展：将单字、两字词的编码接续输入，通过分号触发独立码表查询，输出完整词组。

它不是运行时的智能造句，而是查询预先收录了完整词语及其接续编码的词典，不会临时组合候选词。

## 输入方式

在已有编码后输入分号，再继续输入后续编码，例如词典中有 `自行车 → zkxgwe` 时：

```text
zkxg;we
zk;xgwe
```

两种输入都会按 `zkxgwe` 查询。分号只是触发标记，不是词典编码的一部分，也不限定分词边界。

- 第一个分号需要在已有候选时输入；进入接续查询后，可以继续输入字母或在字母后插入分号。
- 不接受连续分号，反引号不参与接续组词。
- 以 `;` 开头的快符和 `;h` 保持 KeyTao 原功能。
- 支持编码前缀补全，尚未输入完整编码时也可能出现词典中的长词组。

## 工作原理

1. **接管接续输入**：`phrase_combiner_processor.lua` 处理编码后的分号，并在接续状态下接收后续字母，避免被 KeyTao 原有处理器提前处理。
2. **识别特殊查询**：`phrase_combiner.yaml` 将以字母开头、包含分号的编码识别为扩展查询，并注册处理器、翻译器及码表依赖。
3. **去除分号查表**：`phrase_combiner_translator.lua` 删除输入中的所有分号，通过 Rime 的 `table_translator` 查询 `phrase_combiner` 词典。
4. **返回完整候选**：查询结果覆盖原始输入范围，预编辑文本保留分号，候选沿用码表返回的文本、注释和质量。

`phrase_combiner.schema.yaml` 仅作为 KeyTao 的部署依赖，用于编译独立词典和编码索引，不作为单独的输入方案。扩展启用编码补全，关闭自动造句和动态用户词典；手工词条通过静态词典导入。

## 词典格式

主词典为 `phrase_combiner.dict.yaml`，本目录提供了一份[示例词典](phrase_combiner.dict.yaml)，使用 Rime 文本词典格式：

```yaml
# Rime dictionary
---
name: phrase_combiner
version: "1.0"
sort: original
import_tables:
  - phrase_combiner.user
columns:
  - text
  - code
  - weight
...
```

`...` 之后是词条，每行依次为「词语、编码、权重」，字段之间使用 **Tab** 分隔：

```text
自行车	zkxgwe	100
遥控器	yzkyqk	100
```

- `text`：完整候选词语。
- `code`：由小写字母组成的完整接续编码，不含分号、反引号或空格。同一词语可以用多行记录不同编码。
- `weight`：词条权重，通常使用 `100`，可用于调整同码候选的优先级。

手工词典 `phrase_combiner.user.dict.yaml` 使用相同的词条格式，词典头的 `name` 为 `phrase_combiner.user`，无需声明 `import_tables`。它由主词典导入，与 Rime 自动学习的动态用户词典不同。
