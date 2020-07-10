# rime-files

主要功能, 仅供参考

* 自然码双拼
* 支持输入 emoji
* 下载生成搜狗词库 (scripts/sougou.rb)
* 生成 mac 联系人字典 (scripts/contacts.rb)
* 默认英文标点 (shift + space 切换全角)
* 屏蔽 shfit 切换中英文 (结合其他软件用 caplock 切换)
* (第三方软件 caplock 切换, mac: [Hammerspoon](https://www.hammerspoon.org/), win: [AutoHotKey](https://www.autohotkey.com/))

## 1. 安装预设配置

````
git clone https://github.com/sunteya/rime-files ~/Library/Rime
cd ~/Library/Rime
git submodule update
./plum-update
````

## 2. 生成自定义词库

````
cd ~/Library/Rime/scripts
bundle

cd ~/Library/Rime
ruby scripts/sogou.rb
ruby scripts/contacts.rb # 5~10 minutes
````
