local buttons = import '../Buttons/Layout26.libsonnet';
local commonButtons = import '../Buttons/Common.libsonnet';
local toolbarParams = import '../Buttons/Toolbar.libsonnet';
local settings = import '../Settings.libsonnet';
local basicStyle = import 'BasicStyle.libsonnet';
local preedit = import 'Preedit.libsonnet';
local toolbar = import 'Toolbar.libsonnet';
local utils = import 'Utils.libsonnet';

local portraitNormalButtonSize = {
  size: { width: '112.5/1125' },
};

local KeyboardType = {
  Chinese: 0,
  English: 1,
  Temp26Key: 2,
};

local getSwitchButton(keyboardType) =
  if keyboardType == KeyboardType.English then
    commonButtons.pinyinButton
  else if keyboardType == KeyboardType.Temp26Key then
    commonButtons.goBackButton
  else
    commonButtons.alphabeticButton;

local keyboardLayout(keyboardType) = {
  keyboardLayout: [
    { HStack: { subviews: [ { Cell: buttons.qButton.name }, { Cell: buttons.wButton.name }, { Cell: buttons.eButton.name }, { Cell: buttons.rButton.name }, { Cell: buttons.tButton.name }, { Cell: buttons.yButton.name }, { Cell: buttons.uButton.name }, { Cell: buttons.iButton.name }, { Cell: buttons.oButton.name }, { Cell: buttons.pButton.name } ] } },
    { HStack: { subviews: [ { Cell: buttons.aButton.name }, { Cell: buttons.sButton.name }, { Cell: buttons.dButton.name }, { Cell: buttons.fButton.name }, { Cell: buttons.gButton.name }, { Cell: buttons.hButton.name }, { Cell: buttons.jButton.name }, { Cell: buttons.kButton.name }, { Cell: buttons.lButton.name } ] } },
    { HStack: { subviews: [ { Cell: commonButtons.shiftButton.name }, { Cell: buttons.zButton.name }, { Cell: buttons.xButton.name }, { Cell: buttons.cButton.name }, { Cell: buttons.vButton.name }, { Cell: buttons.bButton.name }, { Cell: buttons.nButton.name }, { Cell: buttons.mButton.name }, { Cell: commonButtons.backspaceButton.name } ] } },
    { HStack: { subviews: [ { Cell: commonButtons.numericButton.name }, { Cell: commonButtons.commaButton.name }, { Cell: commonButtons.spaceButton.name }, { Cell: getSwitchButton(keyboardType).name }, { Cell: commonButtons.enterButton.name } ] } },
  ],
};

local getAlphabeticButtonSize(name) =
  local extra = {
    [buttons.aButton.name]: {
      size: { width: '168.75/1125' },
      bounds: { width: '112.5/168.75', alignment: 'right' },
    },
    [buttons.lButton.name]: {
      size: { width: '168.75/1125' },
      bounds: { width: '112.5/168.75', alignment: 'left' },
    },
  };
  (if std.objectHas(extra, name) then extra[name] else portraitNormalButtonSize);

local newKeyLayout(isDark=false, isPortrait=true, keyboardType=KeyboardType.Chinese) =
  local isAlphabetic = keyboardType == KeyboardType.English;
  local currentInsets = if isPortrait then commonButtons.backgroundInsets.portrait else commonButtons.backgroundInsets.landscape;

  {
    keyboardHeight: if isPortrait then commonButtons.keyboardHeight.portrait else commonButtons.keyboardHeight.landscape,
    keyboardStyle: utils.newBackgroundStyle(style=basicStyle.keyboardBackgroundStyleName),
  }
  + keyboardLayout(keyboardType)

  // 1. 字母按键区：循环合并 Insets 并关联私有 Style
  + std.foldl(function(acc, button)
      local char = std.strReplace(button.name, 'Button', '');
      acc +
      basicStyle.newAlphabeticButton(
        button.name,
        isDark,
        getAlphabeticButtonSize(button.name) +
        utils.processButtonParams(isAlphabetic, button.params) + 
        basicStyle.hintStyleSize + 
        basicStyle.textCenterWhenShowSwipeText +
        { 
            insets: currentInsets,
            style: 'custom.' + char // 核心：强制指向私有颜色样式
        } +
        (if keyboardType != KeyboardType.English && settings.uppercaseForChinese then
          { text: std.asciiUpper(button.params.action.character) }
        else {})),
      buttons.letterButtons,
      {})

  // 2. 第三行功能键
  + basicStyle.newSystemButton(
    commonButtons.shiftButton.name,
    isDark,
    { insets: currentInsets } +
    (if settings.keyboardLayout=='26b' then portraitNormalButtonSize else { size: { width: '168.75/1125' }, bounds: { width: '151/168.75', alignment: 'left' } })
    + utils.processButtonParams(isAlphabetic, commonButtons.shiftButton.params)
  )

  + basicStyle.newSystemButton(
    commonButtons.backspaceButton.name,
    isDark,
    { insets: currentInsets } +
    (if settings.keyboardLayout=='26b' then { size: { width: '225/1125' } } else { size: { width: '168.75/1125' }, bounds: { width: '151/168.75', alignment: 'right' } })
    + utils.processButtonParams(isAlphabetic, commonButtons.backspaceButton.params),
  )

  // 3. 第四行功能键
  + basicStyle.newSystemButton(
    commonButtons.numericButton.name,
    isDark,
    { size: { width: { percentage: 0.20 } }, insets: currentInsets }
    + utils.processButtonParams(isAlphabetic, commonButtons.numericButton.params)
  )

  + basicStyle.newAlphabeticButton(
    commonButtons.commaButton.name,
    isDark,
    { insets: currentInsets, style: 'custom.q' } + // 示例：让逗号跟随 q 的颜色
    portraitNormalButtonSize + 
    utils.processButtonParams(isAlphabetic, commonButtons.commaButton.params) + 
    basicStyle.hintStyleSize,
    swipeTextFollowSetting=false,
  )

  + basicStyle.newAlphabeticButton(
    commonButtons.spaceButton.name,
    isDark,
    { insets: currentInsets } + // 注入间隙
    basicStyle.newSpaceButtonForegroundStyle(
      utils.processButtonParams(isAlphabetic, commonButtons.spaceButton.params),
      if keyboardType == KeyboardType.English then 'English' else '$rimeSchemaName',
      isDark
    ),
    needHint=false,
  )

  + local switchButton = getSwitchButton(keyboardType);
    basicStyle.newSystemButton(
    switchButton.name,
    isDark,
    { insets: currentInsets } + portraitNormalButtonSize + utils.processButtonParams(isAlphabetic, switchButton.params)
  )

  + basicStyle.newColorButton(
    commonButtons.enterButton.name,
    isDark,
    { size: { width: { percentage: 0.22 } }, insets: currentInsets } + utils.processButtonParams(isAlphabetic, commonButtons.enterButton.params)
  )
;

{
  KeyboardType:: KeyboardType,
  new(isDark, isPortrait, keyboardType=KeyboardType.Chinese):
    local insets = if isPortrait then commonButtons.backgroundInsets.portrait else commonButtons.backgroundInsets.landscape;
    local extraParams = { insets: insets };

    preedit.new(isDark)
    + toolbar.new(isDark, isPortrait)
    + basicStyle.newKeyboardBackgroundStyle(isDark)
    // 移除全局 AlphabeticButtonBackgroundStyle，改用动态私有
    + basicStyle.newSystemButtonBackgroundStyle(isDark, extraParams)
    + basicStyle.newColorButtonBackgroundStyle(isDark, extraParams)
    + basicStyle.newAlphabeticHintBackgroundStyle(isDark, { cornerRadius: 10 })
    + basicStyle.newLongPressSymbolsBackgroundStyle(isDark, extraParams)
    + basicStyle.newLongPressSymbolsSelectedBackgroundStyle(isDark, extraParams)
    + basicStyle.newButtonAnimation()
    + newKeyLayout(isDark, isPortrait, keyboardType)
    + basicStyle.rimeSchemaChangedNotification
    + basicStyle.returnKeyTypeChangedNotification,
}
