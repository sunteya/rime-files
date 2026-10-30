# =====================================
# 此文件用于自定义数字键盘按键功能。
# 顶部的 Actions 区域用于统一管理上滑、下滑和长按功能。
# =====================================

local colors = import '../Constants/Colors.libsonnet';
local fonts = import '../Constants/Fonts.libsonnet';
local settings = import '../Settings.libsonnet';

{
  local root = self,

  # ---------------------------------------------------------
  # [快速配置区] 在这里统一修改数字键的上滑、下滑功能
  # ---------------------------------------------------------
  local Actions = {
    // 如果想给数字键加符号，在这里定义，例如：'1': '!',
    swipeUp: {
      // '1': '!', '2': '@', 
    },
    swipeDown: {
    },
    longPress: {
      // 默认长按为空，或自定义功能
    },
  },

  # ---------------------------------------------------------
  # [工具函数] 自动合并参数并处理颜色匹配
  # ---------------------------------------------------------
  local mkNumButton(name, char, params={}) = {
    name: name,
    params: {
      action: { character: char },
      // 引用 Actions 中的上滑定义
      [if std.objectHas(Actions.swipeUp, char) then 'swipeUp']: { action: { character: Actions.swipeUp[char] } },
      // 引用 Actions 中的下滑定义
      [if std.objectHas(Actions.swipeDown, char) then 'swipeDown']: { action: { character: Actions.swipeDown[char] } },
    } + params, // 合并传入的 params (包含关键的 insets)
  },

  # ---------------------------------------------------------
  # [按键定义区]
  # ---------------------------------------------------------

  // 1. 基础数字键
  oneButton:   mkNumButton('oneButton', '1'),
  twoButton:   mkNumButton('twoButton', '2'),
  threeButton: mkNumButton('threeButton', '3'),
  fourButton:  mkNumButton('fourButton', '4'),
  fiveButton:  mkNumButton('fiveButton', '5'),
  sixButton:   mkNumButton('sixButton', '6'),
  sevenButton: mkNumButton('sevenButton', '7'),
  eightButton: mkNumButton('eightButton', '8'),
  nineButton:  mkNumButton('nineButton', '9'),
  zeroButton:  mkNumButton('zeroButton', '0'),

  numericButtons: [
    self.oneButton, self.twoButton, self.threeButton,
    self.fourButton, self.fiveButton, self.sixButton,
    self.sevenButton, self.eightButton, self.nineButton,
    self.zeroButton,
  ],

  // 2. 数字键盘特殊功能键
  numericSpaceButton: {
    name: 'numericSpaceButton',
    params: { action: 'space', systemImageName: 'space' },
  },

  numericEqualButton: {
    name: 'numericEqualButton',
    params: { action: { character: '=' } },
  },

  numericColonButton: {
    name: 'numericColonButton',
    params: { action: { symbol: ':' } },
  },

  dotButton: {
    name: 'dotButton',
    params: {
      action: { symbol: '.' },
      whenPreeditChanged: { action: { character: '.' } }
    },
  },

  numericSymbolsCollection: {
    name: 'numericSymbolsCollection',
    params: { type: 'numericSymbols' },
  },

  numericCategorySymbolCollection: {
    name: 'numericCategorySymbolCollection',
    params: { type: 'categorySymbols' },
  },

  // 3. 行式布局及 16 进制按键（统一规范化结构）
  hyphenButton: {
    name: 'hyphenButton',
    params: {
      action: if settings.keyboardLayout=='bopomofo' then { symbol: '-' } else { character: '-' },
    },
  },

  forwardSlashButton: {
    name: 'forwardSlashButton',
    params: {
      action: { symbol: '/' },
      whenPreeditChanged: { action: { character: '/' } },
    },
  },

  colonButton: {
    name: 'colonButton',
    params: { action: { character: ':' }, text: '：', whenAlphabetic: { text: ':' } },
  },

  semicolonButton: {
    name: 'semicolonButton',
    params: { action: { character: ';' }, text: '；', whenAlphabetic: { text: ';' } },
  },

  leftParenthesisButton: {
    name: 'leftParenthesisButton',
    params: { action: { character: '(' } },
  },

  rightParenthesisButton: {
    name: 'rightParenthesisButton',
    params: { action: { character: ')' } },
  },

  moneyButton: {
    name: 'moneyButton',
    params: { action: { character: '$' }, text: '¥', whenAlphabetic: { text: '$' } },
  },

  atButton: {
    name: 'atButton',
    params: { action: { character: '@' } },
  },

  leftCurlyQuoteButton: {
    name: 'leftCurlyQuoteButton',
    params: { action: { symbol: '“' }, whenAlphabetic: { action: { symbol: "'" } } },
  },

  rightCurlyQuoteButton: {
    name: 'rightCurlyQuoteButton',
    params: { action: { symbol: '”' }, whenAlphabetic: { action: { symbol: '"' } } },
  },

  asteriskButton: {
    name: 'asteriskButton',
    params: { action: { character: '*' } },
  },

  plusButton: {
    name: 'plusButton',
    params: { action: { character: '+' } },
  },

  chinesePeriodButton: {
    name: 'chinesePeriodButton',
    params: { action: { symbol: '。' }, whenAlphabetic: { action: { symbol: '&' } } },
  },

  ideographicCommaButton: {
    name: 'ideographicCommaButton',
    params: { action: { symbol: '、' }, whenAlphabetic: { action: { symbol: '\\' } } },
  },

  questionMarkButton: {
    name: 'questionMarkEnButton',
    params: { action: { character: '?' } },
  },

  exclamationMarkButton: {
    name: 'exclamationMarkButton',
    params: { action: { character: '!' } },
  },

  hashButton: {
    name: 'hashButton',
    params: { action: { character: '#' } },
  },

  // 16 进制按键 (A-F)
  aHexButton: mkNumButton('aHexButton', 'a', { action: { symbol: 'a' }, longPress: [{ action: { symbol: 'A' } }] }),
  bHexButton: mkNumButton('bHexButton', 'b', { action: { symbol: 'b' }, longPress: [{ action: { symbol: 'B' } }] }),
  cHexButton: mkNumButton('cHexButton', 'c', { action: { symbol: 'c' }, longPress: [{ action: { symbol: 'C' } }] }),
  dHexButton: mkNumButton('dHexButton', 'd', { action: { symbol: 'd' }, longPress: [{ action: { symbol: 'D' } }] }),
  eHexButton: mkNumButton('eHexButton', 'e', { action: { symbol: 'e' }, longPress: [{ action: { symbol: 'E' } }] }),
  fHexButton: mkNumButton('fHexButton', 'f', { action: { symbol: 'f' }, longPress: [{ action: { symbol: 'F' } }] }),

  backSlashHexButton: {
    name: 'backSlashHexButton',
    params: { action: { symbol: '\\' } },
  },

  xHexButton: {
    name: 'xHexButton',
    params: { action: { symbol: 'x' }, longPress: [{ action: { symbol: 'X' } }] },
  },
}
