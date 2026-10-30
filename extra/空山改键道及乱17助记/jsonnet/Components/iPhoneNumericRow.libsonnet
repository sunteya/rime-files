local numericButtons = import '../Buttons/LayoutNumeric.libsonnet';
local symbolicButtons = import '../Buttons/LayoutSymbolic.libsonnet';
local commonButtons = import '../Buttons/Common.libsonnet';
local fonts = import '../Constants/Fonts.libsonnet';
local basicStyle = import 'BasicStyle.libsonnet';
local preedit = import 'Preedit.libsonnet';
local toolbar = import 'Toolbar.libsonnet';
local utils = import 'Utils.libsonnet';
local settings = import '../Settings.libsonnet';

local portraitNormalButtonSize = {
  size: { width: '112.5/1125' },
};

local KeyboardType = {
  Chinese: 0,
  English: 1,
};

local keyboardLayout = {
  keyboardLayout: [
    {
      HStack: {
        subviews: [
          { Cell: numericButtons.oneButton.name },
          { Cell: numericButtons.twoButton.name },
          { Cell: numericButtons.threeButton.name },
          { Cell: numericButtons.fourButton.name },
          { Cell: numericButtons.fiveButton.name },
          { Cell: numericButtons.sixButton.name },
          { Cell: numericButtons.sevenButton.name },
          { Cell: numericButtons.eightButton.name },
          { Cell: numericButtons.nineButton.name },
          { Cell: numericButtons.zeroButton.name },
        ],
      },
    },
    {
      HStack: {
        subviews: [
          { Cell: numericButtons.hyphenButton.name },
          { Cell: numericButtons.forwardSlashButton.name },
          { Cell: numericButtons.colonButton.name },
          { Cell: numericButtons.semicolonButton.name },
          { Cell: numericButtons.leftParenthesisButton.name },
          { Cell: numericButtons.rightParenthesisButton.name },
          { Cell: numericButtons.moneyButton.name },
          { Cell: numericButtons.atButton.name },
          { Cell: numericButtons.leftCurlyQuoteButton.name },
          { Cell: numericButtons.rightCurlyQuoteButton.name },
        ],
      },
    },
    {
      HStack: {
        subviews: [
          { Cell: commonButtons.symbolicButton.name },
          { Cell: numericButtons.plusButton.name },
          { Cell: numericButtons.asteriskButton.name },
          { Cell: numericButtons.ideographicCommaButton.name },
          { Cell: numericButtons.hashButton.name },
          { Cell: numericButtons.questionMarkButton.name },
          { Cell: numericButtons.exclamationMarkButton.name },
          { Cell: numericButtons.dotButton.name },
          { Cell: commonButtons.backspaceButton.name },
        ],
      },
    },
    {
      HStack: {
        subviews: [
          { Cell: commonButtons.gotoPrimaryKeyboardButton.name },
          { Cell: numericButtons.chinesePeriodButton.name },
          { Cell: numericButtons.numericSpaceButton.name },
          { Cell: numericButtons.numericEqualButton.name },
          { Cell: commonButtons.enterButton.name },
        ],
      },
    },
  ],
};

local getButtonSize(name) =
  local extra = {
    [numericButtons.chinesePeriodButton.name]: portraitNormalButtonSize,
    [numericButtons.numericEqualButton.name]: portraitNormalButtonSize,
    [commonButtons.symbolicButton.name]: {
      size: { width: '168.75/1125' },
      bounds: { width: '151/168.75', alignment: 'left' },
    },
    [commonButtons.backspaceButton.name]: {
      size: { width: '168.75/1125' },
      bounds: { width: '151/168.75', alignment: 'right' },
    },
    [commonButtons.enterButton.name]: { size: { width: { percentage: 0.22 } } },
    [commonButtons.gotoPrimaryKeyboardButton.name]: { size: { width:  { percentage: 0.20 } } },
  };
  (if std.objectHas(extra, name) then extra[name] else {});

local newKeyLayout(isDark=false, isPortrait=true, keyboardType=KeyboardType.Chinese) =
  local isAlphabetic = keyboardType == KeyboardType.English;
  local insets = if isPortrait then commonButtons.backgroundInsets.portrait else commonButtons.backgroundInsets.landscape;

  {
    keyboardHeight: if isPortrait then commonButtons.keyboardHeight.portrait else commonButtons.keyboardHeight.landscape,
    keyboardStyle: utils.newBackgroundStyle(style=basicStyle.keyboardBackgroundStyleName),
  }
  + keyboardLayout

  // 1. 数字与普通符号按键处理
  + std.foldl(
    function(acc, button)
      local p = button.params + utils.processButtonParams(isAlphabetic, button.params) + { insets: insets };
      local size = getButtonSize(button.name);
      
      // 核心修改：区分数字和普通符号的字号
      local isNumber = std.member(numericButtons.numericButtons, button);
      local customFontSize = if isNumber then fonts.numericButtonTextFontSize else fonts.standardButtonTextFontSize;
      
      local actionParams = if isNumber && utils.numericActionNeedSymbol(settings.keyboardLayout) then {
        action: utils.replaceCharacterToSymbolRecursive(button.params.action),
        whenPreeditChanged: { action: button.params.action },
      } else {};

      acc + basicStyle.newAlphabeticButton(
        button.name, isDark,
        p + size + basicStyle.hintStyleSize + actionParams + { fontSize: customFontSize }
      ) + basicStyle.newAlphabeticButtonBackgroundStyle(isDark, p + { name: button.name }),
    // 包含所有数字和普通符号列表
    numericButtons.numericButtons + [
      numericButtons.hyphenButton, numericButtons.forwardSlashButton, numericButtons.colonButton,
      numericButtons.semicolonButton, numericButtons.leftParenthesisButton, numericButtons.rightParenthesisButton,
      numericButtons.moneyButton, numericButtons.atButton, numericButtons.leftCurlyQuoteButton,
      numericButtons.rightCurlyQuoteButton, numericButtons.plusButton, numericButtons.asteriskButton,
      numericButtons.ideographicCommaButton, numericButtons.hashButton, numericButtons.questionMarkButton,
      numericButtons.exclamationMarkButton, numericButtons.dotButton, numericButtons.chinesePeriodButton,
      numericButtons.numericEqualButton
    ],
    {})

  // 2. 空格键 (继承 standardButtonTextFontSize)
  + (
    local p = numericButtons.numericSpaceButton.params + utils.processButtonParams(isAlphabetic, numericButtons.numericSpaceButton.params) + { insets: insets };
    basicStyle.newAlphabeticButton(numericButtons.numericSpaceButton.name, isDark, p + { fontSize: fonts.standardButtonTextFontSize }, needHint=false)
  )

  // 3. 系统按键 (Symbolic, Backspace) - 使用 systemButtonTextFontSize
  + std.foldl(
    function(acc, button)
      local p = button.params + utils.processButtonParams(isAlphabetic, button.params) + { insets: insets };
      acc + basicStyle.newSystemButton(button.name, isDark, p + getButtonSize(button.name))
          + basicStyle.newSystemButtonBackgroundStyle(isDark, p + { name: button.name }),
    [commonButtons.symbolicButton, commonButtons.backspaceButton],
    {})

  // 4. 返回/主键盘键 (ColorButton)
  + (
    local p = commonButtons.gotoPrimaryKeyboardButton.params + utils.processButtonParams(isAlphabetic, commonButtons.gotoPrimaryKeyboardButton.params) + { insets: insets };
    basicStyle.newColorButton(commonButtons.gotoPrimaryKeyboardButton.name, isDark, p + getButtonSize(commonButtons.gotoPrimaryKeyboardButton.name))
    + basicStyle.newColorButtonBackgroundStyle(isDark, p + { name: commonButtons.gotoPrimaryKeyboardButton.name })
  )

  // 5. Enter 键
  + (
    local p = commonButtons.enterButton.params + utils.processButtonParams(isAlphabetic, commonButtons.enterButton.params) + { insets: insets };
    basicStyle.newColorButton(commonButtons.enterButton.name, isDark, p + getButtonSize(commonButtons.enterButton.name))
    + basicStyle.newColorButtonBackgroundStyle(isDark, p + { name: commonButtons.enterButton.name })
  );

{
  KeyboardType:: KeyboardType,

  new(isDark, isPortrait, keyboardType=KeyboardType.Chinese):
    local insets = if isPortrait then commonButtons.backgroundInsets.portrait else commonButtons.backgroundInsets.landscape;

    preedit.new(isDark) + 
    toolbar.new(isDark, isPortrait) + 
    basicStyle.newKeyboardBackgroundStyle(isDark) + 
    basicStyle.newAlphabeticHintBackgroundStyle(isDark, { cornerRadius: 10 }) + 
    basicStyle.newLongPressSymbolsBackgroundStyle(isDark, { insets: insets }) + 
    basicStyle.newLongPressSymbolsSelectedBackgroundStyle(isDark, { insets: insets }) + 
    basicStyle.newButtonAnimation() + 
    newKeyLayout(isDark, isPortrait, keyboardType) +
    basicStyle.rimeSchemaChangedNotification + 
    basicStyle.returnKeyTypeChangedNotification,
}
