# rime-files

个人 Rime 配置，主要用于 macOS 鼠须管，使用 [KeyTao（键道）](https://github.com/xkinput/KeyTao) 输入方案，并支持长词组输入。

## 基本使用

首次配置时，在仓库根目录依次运行以下命令：

### 输入法和扩展

```bash
./scripts/sync-keytao.sh
./scripts/sync-keytao-phrase-combiner.sh
```

### 下载词库

```bash
./scripts/sync-wanxiang-data.sh
./scripts/sync-kaikki.py --update
./scripts/sync-sogou-scel.rb
```

### 生成词库

```bash
./scripts/generate_keytao_dicts.py
```

全部完成后，在鼠须管菜单中选择「重新部署」。以后更新输入方案或词库时，运行对应同步脚本、重新生成词库，再部署 Rime。

## 自定义词条

- `user/keytao.user.dict.yaml`：KeyTao 自定义词条。
- `user/phrase_combiner.user.dict.yaml`：长词组自定义词条。

修改词条后重新部署即可。`user/` 不纳入 Git，请自行备份。

## 长词组输入

在编码中插入分号即可查询长词组，例如：

```text
zkxg;we
zk;xgwe
```

更多设置见[长词组扩展说明](extra/keytao-phrase-combiner/README.md)。
