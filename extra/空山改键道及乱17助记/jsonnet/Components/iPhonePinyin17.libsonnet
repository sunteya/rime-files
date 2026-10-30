local buttons = import '../Buttons/Layout17.libsonnet';
local commonButtons = import '../Buttons/Common.libsonnet';
local basicStyle = import 'BasicStyle.libsonnet';
local utils = import 'Utils.libsonnet';
local preedit = import 'Preedit.libsonnet';
local toolbar = import 'Toolbar.libsonnet';

# =====================================
# 1. 键盘布局定义
# =====================================
local keyboardLayout = {
  keyboardLayout: [
    { HStack: { subviews: [ { Cell: buttons.hButton.name }, { Cell: buttons.sButton.name }, { Cell: buttons.zButton.name }, { Cell: buttons.bButton.name }, { Cell: buttons.xButton.name }, { Cell: buttons.mButton.name } ] } },
    { HStack: { subviews: [ { Cell: buttons.lButton.name }, { Cell: buttons.dButton.name }, { Cell: buttons.yButton.name }, { Cell: buttons.wButton.name }, { Cell: buttons.jButton.name }, { Cell: buttons.nButton.name } ] } },
    { HStack: { subviews: [ { Cell: buttons.cButton.name }, { Cell: buttons.qButton.name }, { Cell: buttons.gButton.name }, { Cell: buttons.fButton.name }, { Cell: buttons.tButton.name }, { Cell: commonButtons.backspaceButton.name } ] } },
    { HStack: { subviews: [ { Cell: commonButtons.numericButton.name }, { Cell: commonButtons.commaButton.name }, { Cell: commonButtons.spaceButton.name }, { Cell: commonButtons.alphabeticButton.name }, { Cell: commonButtons.enterButton.name } ] } },
  ],
};

# =====================================
# 2. 键位渲染逻辑
# =====================================
local newKeyLayout(isDark=false, isPortrait=true) =
  local currentInsets = if isPortrait then commonButtons.backgroundInsets.portrait else commonButtons.backgroundInsets.landscape;
  {
    keyboardHeight: if isPortrait then commonButtons.keyboardHeight.portrait else commonButtons.keyboardHeight.landscape,
    keyboardStyle: utils.newBackgroundStyle(style=basicStyle.keyboardBackgroundStyleName),
  }
  + keyboardLayout
  
  // 字母键：动态注入所有 params
  + std.foldl(function(acc, button)
      acc + basicStyle.newAlphabeticButton(
        button.name, isDark, 
        { insets: currentInsets } + button.params + basicStyle.hintStyleSize + basicStyle.textCenterWhenShowSwipeText
      ),
      buttons.letterButtons, {})

  // 系统与功能键
  + basicStyle.newSystemButton(commonButtons.backspaceButton.name, isDark, { insets: currentInsets } + commonButtons.backspaceButton.params)
  + basicStyle.newSystemButton(commonButtons.numericButton.name, isDark, { insets: currentInsets, size: { width: { percentage: 0.2 } } } + commonButtons.numericButton.params)
  + basicStyle.newAlphabeticButton(commonButtons.commaButton.name, isDark, { insets: currentInsets, size: { width: { percentage: 0.12 } } } + commonButtons.commaButton.params + basicStyle.hintStyleSize, swipeTextFollowSetting=false)
  + basicStyle.newAlphabeticButton(commonButtons.spaceButton.name, isDark, basicStyle.newSpaceButtonForegroundStyle(commonButtons.spaceButton.params + { insets: currentInsets }, '$rimeSchemaName', isDark), needHint=false)
  + basicStyle.newSystemButton(commonButtons.alphabeticButton.name, isDark, { insets: currentInsets, size: { width: { percentage: 0.12 } } } + commonButtons.alphabeticButton.params)
  + basicStyle.newColorButton(commonButtons.enterButton.name, isDark, { insets: currentInsets, size: { width: { percentage: 0.22 } } } + commonButtons.enterButton.params);

# =====================================
# 3. 构造函数 (入口)
# =====================================
{
  new(isDark, isPortrait):
    local currentInsets = if isPortrait then commonButtons.backgroundInsets.portrait else commonButtons.backgroundInsets.landscape;
    local extraParams = { insets: currentInsets };

    preedit.new(isDark) 
    + toolbar.new(isDark, isPortrait) 
    + basicStyle.newKeyboardBackgroundStyle(isDark)
    
    // 基础背景样式
    + basicStyle.newAlphabeticButtonBackgroundStyle(isDark, extraParams)
    + basicStyle.newSystemButtonBackgroundStyle(isDark, extraParams)
    + basicStyle.newColorButtonBackgroundStyle(isDark, extraParams)
    
    // 交互反馈样式
    + basicStyle.newAlphabeticHintBackgroundStyle(isDark, { cornerRadius: 10 })
    
    + basicStyle.newLongPressSymbolsBackgroundStyle(isDark, extraParams)
    + basicStyle.newLongPressSymbolsSelectedBackgroundStyle(isDark, extraParams)
    
    // 注入布局内容
    + newKeyLayout(isDark, isPortrait)
    
    // 通知中心
    + basicStyle.rimeSchemaChangedNotification 
    + basicStyle.returnKeyTypeChangedNotification,
}
