local basicStyle = import 'BasicStyle.libsonnet';
local collectionData = import '../Constants/collectionData.libsonnet';
local symbolic = import 'symbolic_portrait.libsonnet';
local preedit = import 'Preedit.libsonnet';

{
  new(isDark, isPortrait): 
    local theme = if isDark then "dark" else "light";
    
    // 1. 调用 symbolic 的 getKeyboard 获取纯净布局（不带符号数据）
    // 注意：这里必须是 getKeyboard (大写 K)，与你提供的符号键盘一致
    local kbd = symbolic.getKeyboard(theme);
    
    // 2. 注入表情数据源并修正样式
    kbd {
        // 根据屏幕方向动态设置高度
        keyboardHeight: if isPortrait then kbd.keyboardHeight.portrait else kbd.keyboardHeight.landscape
    } 
    // 关键点：直接合并 emojiDataSource，确保 category 等字段在 YAML 根部
    + collectionData.emojiDataSource 
    + preedit.new(isDark) 
    + basicStyle.newKeyboardBackgroundStyle(isDark)
}
