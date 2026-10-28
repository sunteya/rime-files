# KeyTao 接续组词

此目录保存接续组词扩展源码，与上游 `../KeyTao/` 分开维护。

## 生成词典

在本目录运行：

```bash
python3 scripts/generate_phrase_combiner.py
```

默认读取 `../KeyTao/rime/keytao.extended.dict.yaml` 及其导入的词典，输出本目录的 `phrase_combiner.dict.yaml`。
只生成至少三个汉字的完整词，优先复用已有词组编码，每个汉字对应两码，不限制最终编码长度。

## 复制到 Rime

在 Rime 根目录运行：

```bash
bash src/copy-keytao-phrase-combiner.sh
```

脚本先生成词典，再复制 Lua、配置和生成词典到 Rime 根目录。之后手工重新部署鼠须管。
更新上游时，先运行 `bash src/copy-keytao.sh`，再运行本扩展的复制脚本。

`keytao.custom.yaml` 通过以下配置引用本扩展，不需要修改上游 `rime.lua`：

```yaml
patch:
  __include: phrase_combiner:/patch
```

## 手工词语

在 `user/phrase_combiner.user.dict.yaml` 中添加词条，使用 Tab 分隔文字、编码和权重。
编码不包含分号或反引号。修改后只需重新部署，不必运行生成器。

本目录的同名文件是初始化模板，仅在用户词典不存在或为空时复制。
Rime 根目录的 `phrase_combiner.user.dict.yaml` 是指向用户词典的软链接，复制脚本不会覆盖已有的非空用户词典。

## 输入

```text
zkxg;we
zk;xgwe
zkxg`we
```

分号或反引号只用于标记特殊查询，查询时会删除所有分隔符。以 `;` 开头的快符和 `;h` 保持原功能。
