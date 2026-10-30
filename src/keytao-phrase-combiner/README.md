# KeyTao 接续组词

此目录保存接续组词扩展源码，与上游 `../KeyTao/` 分开维护。

## 复制到 Rime

在 Rime 根目录运行：

```bash
bash src/copy-keytao-phrase-combiner.sh
```

脚本先在 Rime 根目录生成词典，再复制 Lua 和配置到 Rime 根目录。之后手工重新部署鼠须管。
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
```

分号只用于标记特殊查询，查询时会删除所有分号。反引号不参与接续组词。以 `;` 开头的快符和 `;h` 保持原功能。
