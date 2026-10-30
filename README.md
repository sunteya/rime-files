# rime-files

个人 Rime 配置，主要用于 macOS 鼠须管，以 [KeyTao（键道）](https://github.com/xkinput/KeyTao) 为主输入方案，通过本地维护的 [keytao-phrase-combiner](extra/keytao-phrase-combiner/README.md) 扩展支持长词组，并使用[雾凇拼音](https://github.com/iDvel/rime-ice)词典补充词语。

## 环境与源码

- 已安装支持 Lua 的 Rime 客户端（如鼠须管）。
- 命令行工具：Bash、rsync、Python 3.9+、Git；同步上游源码时需要网络连接。
- 以下命令均在本仓库根目录执行，macOS 下通常为 `~/Library/Rime`。

上游源码分别放在 `repo/KeyTao/` 和 `repo/rime-ice/`，这两个目录不随本仓库提交。同步脚本会在首次运行时自动克隆源码，无需手动准备；已有 Git 仓库时执行 `git pull --ff-only` 更新，成功后再复制文件。克隆或更新失败（如网络错误或分支分叉）时立即停止，不继续复制。

`extra/keytao-phrase-combiner/` 是本仓库维护的扩展源码，无需克隆。

## 生成流程

### 1. 更新并导入 KeyTao 输入方案

```bash
bash scripts/sync-keytao.sh
```

将 KeyTao 的词典、Lua 和桌面方案复制到 Rime 根目录，保留本仓库的 `default.custom.yaml` 等自定义配置。

### 2. 更新并导入雾凇词典

```bash
bash scripts/sync-rime-ice.sh
```

同步雾凇的词典及相关资源，供后续生成长词组使用。当前主输入方案仍是 KeyTao，不会因此切换为雾凇拼音。

### 3. 安装长词组扩展

```bash
bash scripts/sync-keytao-phrase-combiner.sh
```

该扩展在本仓库维护，不单独拉取上游。脚本先调用 `scripts/generate_phrase_combiner.py` 生成词库，再复制扩展的 Lua 和配置。`keytao.custom.yaml` 通过 `__include: phrase_combiner:/patch` 加载扩展。

**首次使用时必须先完成前两步**，否则生成器缺少基础词典或雾凇词典，扩展同步脚本会失败。

### 4. 生成最终词库

在更新 KeyTao、雾凇词典或生成规则后，可以单独重新生成：

```bash
python3 scripts/generate_phrase_combiner.py
```

生成器的输入与输出：

| 用途 | 文件 |
| --- | --- |
| 基础编码 | `keytao.extended.dict.yaml` 及其引用词典中的单字、两字词编码 |
| 待生成词语 | `keytao.phrase.dict.yaml`、`cn_dicts/ext.dict.yaml`、`cn_dicts/tencent.dict.yaml` |
| 最终输出 | `phrase_combiner.dict.yaml` |

生成器为包含至少三个汉字且能用基础编码完整组合的词语生成编码，默认不限制编码长度。雾凇词典只提供词语，不直接使用其拼音编码。

第 3 步已经自动生成过词库；如果此后没有更新输入词典或生成规则，无需重复执行第 4 步。若按“同步 KeyTao → 同步扩展 → 同步雾凇词典”的顺序更新，则最后必须重新运行生成器，以使用最新词典。

完成后，在鼠须管菜单中选择「重新部署」。以上脚本不会自动触发 Rime 部署。

## 自定义词条

- `user/keytao.user.dict.yaml`：KeyTao 自定义词条。
- `user/phrase_combiner.user.dict.yaml`：长词组扩展的手工词条，使用 Tab 分隔文字、编码和权重，编码不含分号或反引号。

KeyTao 和长词组扩展的同步脚本仅在对应用户词典不存在或为空时从模板初始化，并在 Rime 根目录建立同名软链接，不会覆盖已有的非空用户词典。`user/` 不纳入 Git，需要自行备份。

修改长词组手工词条后只需重新部署，不必重新生成词库；修改用于自动组词的 KeyTao 基础编码后，需要重新运行生成器并部署。

## 长词组输入

在编码中插入分号触发扩展查询，例如：

```text
zkxg;we
zk;xgwe
```

分号仅作为查询标记，查询时会移除；反引号不参与接续组词。以 `;` 开头的快符和 `;h` 保持原功能。更多说明见[扩展 README](extra/keytao-phrase-combiner/README.md)。

## 手机皮肤

[空山改键道及乱17助记](extra/空山改键道及乱17助记/) 是修改后的手机输入法皮肤，用于手机端输入。
