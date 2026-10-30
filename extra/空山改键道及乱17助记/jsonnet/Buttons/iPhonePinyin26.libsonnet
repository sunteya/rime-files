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

// 枚举键盘类型
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
    {
      HStack: {
        subviews: [
          { Cell: buttons.qButton.name },
          { Cell: buttons.wButton.name },
          { Cell: buttons.eButton.name },
          { Cell: buttons.rButton.name },
          { Cell: buttons.tButton.name },
          { Cell: buttons.yButton.name },
          { Cell: buttons.uButton.name },
          { Cell: buttons.iButton.name },
          { Cell: buttons.oButton.name },
          { Cell: buttons.pButton.name },
        ],
      },
    },
    {
      HStack: {
        subviews: [
          { Cell: buttons.aButton.name },
          { Cell: buttons.sButton.name },
          { Cell: buttons.dButton.name },
          { Cell: buttons.fButton.name },
          { Cell: buttons.gButton.name },
          { Cell: buttons.hButton.name },
          { Cell: buttons.jButton.name },
          { Cell: buttons.kButton.name },
          { Cell: buttons.lButton.name },
        ],
      },
    },
    {
      HStack: {
        subviews: [
          { Cell: commonButtons.shiftButton.name },
          { Cell: buttons.zButton.name },
          { Cell: buttons.xButton.name },
          { Cell: buttons.cButton.name },
          { Cell: buttons.vButton.name },
          { Cell: buttons.bButton.name },
          { Cell: buttons.nButton.name },
          { Cell: buttons.mButton.name },
          { Cell: commonButtons.backspaceButton.name },
        ],
      },
    },
    {
      HStack: {
        subviews: [
          { Cell: commonButtons.numericButton.name },
          { Cell: commonButtons.commaButton.name },
          { Cell: commonButtons.spaceButton.name },
          { Cell: getSwitchButton(keyboardType).name },
          { Cell: commonButtons.enterButton.name },
        ],
      },
    },
  ],
};

local getAlphabeticButtonSize(name) =
  local extra = {
    [buttons.aButton.name]: {
      size:
        { width: '168.75/1125' },
      bounds:
        { width: '111/168.75', alignment: 'right' },
    },
    [buttons.lButton.name]: {
      size:
        { width: '168.75/1125' },
      bounds:
        { width: '111/168.75', alignment: 'left' },
    },
  };
  (
  if std.objectHas(extra, name) then
    extra[name]
  else
    portraitNormalButtonSize
  );

local newKeyLayout(isDark=false, isPortrait=true, keyboardType=KeyboardType.Chinese) =
  local isAlphabetic = keyboardType == KeyboardType.English;
  local currentInsets = if isPortrait then commonButtons.backgroundInsets.portrait else commonButtons.backgroundInsets.landscape;
  local switchButton = getSwitchButton(keyboardType);
  
  {
    keyboardHeight: if isPortrait then commonButtons.keyboardHeight.portrait else commonButtons.keyboardHeight.landscape,
    keyboardStyle: utils.newBackgroundStyle(style=basicStyle.keyboardBackgroundStyleName),
  }
  + keyboardLayout(keyboardType)

  // 字母键生成
  + std.foldl(function(acc, button)
      acc +
      basicStyle.newAlphabeticButton(
        button.name,
        isDark,
        getAlphabeticButtonSize(button.name) +
        utils.processButtonParams(isAlphabetic, button.params) + 
        basicStyle.hintStyleSize + 
        basicStyle.textCenterWhenShowSwipeText +
        { insets: currentInsets } + 
        button.params + // 核心：保持 params 优先级最高以触发 BasicStyle 取色
        (
          // 如果是非英文模式，且开启了大写显示
          if keyboardType != KeyboardType.English && settings.uppercaseForChinese then
            // 仅合并文字内容，不再合并 ForegroundStyle，防止颜色被系统黑色/灰白覆盖
            basicStyle.getKeyboardActionText(button.params.uppercased)
          else {}
        )),
      buttons.letterButtons,
      {})

  // 第三行功能键
  + basicStyle.newSystemButton(
    commonButtons.shiftButton.name,
    isDark,
    (
      if settings.keyboardLayout=='26b' then portraitNormalButtonSize else
      {
        size:
          { width: '168.75/1125' },
        bounds:
          { width: '151/168.75', alignment: 'left' },
      }
    )
    + { insets: currentInsets }
    + utils.processButtonParams(isAlphabetic, commonButtons.shiftButton.params)
  )

  + basicStyle.newSystemButton(
    commonButtons.backspaceButton.name,
    isDark,
    (
      if settings.keyboardLayout=='26b' then
      {
        size: { width: '225/1125' },
      }
      else
      {
        size:
          { width: '168.75/1125' },
        bounds:
          { width: '151/168.75', alignment: 'right' },
      }
    )
    + { insets: currentInsets }
    + utils.processButtonParams(isAlphabetic, commonButtons.backspaceButton.params),
  )

  // 第四行功能键
  + basicStyle.newSystemButton(
    commonButtons.numericButton.name,
    isDark,
    { size: { width: '225/1125' }, insets: currentInsets }
    + utils.processButtonParams(isAlphabetic, commonButtons.numericButton.params)
  )

  + basicStyle.newAlphabeticButton(
    commonButtons.commaButton.name,
    isDark,
    portraitNormalButtonSize + { insets: currentInsets } + utils.processButtonParams(isAlphabetic, commonButtons.commaButton.params) + basicStyle.hintStyleSize,
    swipeTextFollowSetting=false,
  )
  + basicStyle.newAlphabeticButton(
    commonButtons.spaceButton.name,
    isDark,
    basicStyle.newSpaceButtonForegroundStyle(
      utils.processButtonParams(isAlphabetic, commonButtons.spaceButton.params) + { insets: currentInsets },
      if keyboardType == KeyboardType.English then 'English' else if keyboardType == KeyboardType.Temp26Key then '临时中文' else '$rimeSchemaName',
      isDark
    ),
    needHint=false,
  )
  + basicStyle.newSystemButton(
    switchButton.name,
    isDark,
    portraitNormalButtonSize + { insets: currentInsets }
    + utils.processButtonParams(isAlphabetic, switchButton.params)
  )
  + basicStyle.newColorButton(
    commonButtons.enterButton.name,
    isDark,
    {
      size: { width: '250/1125' },
      insets: currentInsets,
    } + utils.processButtonParams(isAlphabetic, commonButtons.enterButton.params)
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
    + basicStyle.newAlphabeticButtonBackgroundStyle(isDark, extraParams)
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
