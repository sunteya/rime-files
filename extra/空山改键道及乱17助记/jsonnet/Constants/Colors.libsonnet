local settings = import '../Settings.libsonnet';

// 标签颜色常量定义
local labelColor = {
  primary: {
    light: '#000000',
    dark: '#FFFFFF',
  },
  secondary: {
    light: '#000000',
    dark: '#FFFFFF',
		#light: '#8a8a8a',
    #dark: '#3C4043',
  },
  tertiary: {
    light: '#c4c4c4',
    dark: '#5d5d5d',
  },
  quaternary: {
    light: '#dcdcdc',
    dark: '#404040',
  },
};

// 分割线颜色
local separatorColor = {
  light: '#C6C6C8',
  dark: '#38383A',
};

// 键盘背景色
local keyboardBackgroundColor = {
  light: '#ffffff03',
  dark: '#00000003',
};


// 按键背景颜色定义
local standardButtonBackgroundColor = {
  custom: {

    default: { light: '#FFFFFF', dark: '#D1D1D165',},

  // 第一排
  q: { light: '#86B953', dark: '#86B953' },
  w: { light: '#FF9800', dark: '#FF9800' },
#  e: { light: '#F8B285', dark: '#FF9800' },
#  r: { light: '#F9F7EB', dark: '#AC9B84' },
#  t: { light: '#F79781', dark: '#EB3855' },
#  y: { light: '#F8E2C2', dark: '#AC744D' },
  u: { light: '#00BCD4', dark: '#00BCD4' },
  i: { light: '#00BCD4', dark: '#00BCD4' },
  o: { light: '#00BCD4', dark: '#00BCD4' },
#  p: { light: '#DFE8EE', dark: '#6F7990' },

  // 第二排
  a: { light: '#00BCD4', dark: '#00BCD4' },
#  s: { light: '#E6E9EF', dark: '#9298A7' },
#  d: { light: '#F4EFED', dark: '#9C899A' },
  f: { light: '#86B953', dark: '#86B953' },
#  g: { light: '#F9F1D9', dark: '#B2A68E' },
#  h: { light: '#E9ECF0', dark: '#9298A7' },
  j: { light: '#FF9800', dark: '#FF9800' },
#  k: { light: '#F7F3F0', dark: '#B6A6A5' },
#  l: { light: '#F8B285', dark: '#FF9800' },

  // 第三排 
#  z: { light: '#F8E2C2', dark: '#AC744D' },
  x: { light: '#EB3855', dark: '#EB3855' },
#  c: { light: '#E1F1F2', dark: '#00BCD4' },
  v: { light: '#00BCD4', dark: '#00BCD4' },
#  b: { light: '#F6F9E9', dark: '#B5AB9E' },
#  n: { light: '#F7EDF3', dark: '#806C8A' },
#  m: { light: '#F9F7EB', dark: '#AC9B84' },


  },
};

// 标准按键按下时的背景色
local standardButtonHighlightedBackgroundColor = {
  light: '#E6E6E6',
  dark: '#D1D1D624',
};

// 标准按键前景色
local standardButtonForegroundColor = labelColor.primary;
local standardButtonHighlightedForegroundColor = standardButtonForegroundColor;

// 标准按键备用色
local alternativeForegroundColor = labelColor.secondary;
local alternativeHighlightedForegroundColor = alternativeForegroundColor;

// 标准按键阴影颜色
local standardButtonShadowColor = {
  light: '#898A8D',
  dark: '#000000',
};

// 系统按键背景颜色
local systemButtonBackgroundColor = {
  light: '#E6E6E6',
  dark: '#D1D1D624',
};

local systemButtonHighlightedBackgroundColor = {
  light: '#FFFFFF',
  dark: '#D1D1D659',
};

// 系统按键前景颜色
local systemButtonForegroundColor = labelColor.primary;
local systemButtonHighlightedForegroundColor = systemButtonForegroundColor;

// 强调色配置
local accentColors = [
  { background: '#da4357', foreground: '#ffffff' },
  { background: '#50A545', foreground: '#ffffff' },
  { background: '#E86E30', foreground: '#ffffff' },
  { background: '#2e67f8', foreground: '#ffffff' },
  { background: '#7A72B8', foreground: '#ffffff' },
];

local colorButtonBackgroundColor = if settings.accentColor == 0 then systemButtonBackgroundColor else
  local color = accentColors[settings.accentColor - 1].background;
  { light: color, dark: color };

local colorButtonForegroundColor = if settings.accentColor == 0 then systemButtonForegroundColor else
  local color = accentColors[settings.accentColor - 1].foreground;
  { light: color, dark: color };

local colorButtonHighlightedBackgroundColor = systemButtonHighlightedBackgroundColor;
local colorButtonHighlightedForegroundColor = labelColor.primary;

// 按键边缘颜色
local lowerEdgeOfButtonNormalColor = { light: '#898A8D', dark: '#1E1E1E' };
local lowerEdgeOfButtonHighlightColor = { light: '#898A8D', dark: '#1D1D1D' };

// 气泡系统
local standardCalloutBackgroundColor = { light: '#f8f8f8', dark: '#6B6B6B' };
local standardCalloutForegroundColor = standardButtonForegroundColor;
local standardCalloutHighlightedForegroundColor = colorButtonForegroundColor;
local standardCalloutSelectedBackgroundColor = colorButtonBackgroundColor;
local standardCalloutBorderColor = { light: '#C6C6C8', dark: '#606060' };

// 其他显示字段
local preeditForegroundColor = standardButtonForegroundColor;
local toolbarButtonForegroundColor = standardButtonForegroundColor;
local toolbarButtonHighlightedForegroundColor = standardButtonForegroundColor;

// 候选词系统：取e键颜色
local candidateHighlightColor = standardButtonBackgroundColor.custom.default;
local candidateForegroundColor = standardButtonForegroundColor;
local candidateSeparatorColor = separatorColor;

// 最终导出
{
  labelColor: labelColor,
  separatorColor: separatorColor,
  keyboardBackgroundColor: keyboardBackgroundColor,
  standardButtonBackgroundColor: standardButtonBackgroundColor,
  standardButtonHighlightedBackgroundColor: standardButtonHighlightedBackgroundColor,
  standardButtonForegroundColor: standardButtonForegroundColor,
  standardButtonHighlightedForegroundColor: standardButtonHighlightedForegroundColor,
  alternativeForegroundColor: alternativeForegroundColor,
  alternativeHighlightedForegroundColor: alternativeHighlightedForegroundColor,
  standardButtonShadowColor: standardButtonShadowColor,
  systemButtonBackgroundColor: systemButtonBackgroundColor,
  systemButtonHighlightedBackgroundColor: systemButtonHighlightedBackgroundColor,
  systemButtonForegroundColor: systemButtonForegroundColor,
  systemButtonHighlightedForegroundColor: systemButtonHighlightedForegroundColor,
  colorButtonBackgroundColor: colorButtonBackgroundColor,
  colorButtonHighlightedBackgroundColor: colorButtonHighlightedBackgroundColor,
  colorButtonForegroundColor: colorButtonForegroundColor,
  colorButtonHighlightedForegroundColor: colorButtonHighlightedForegroundColor,
  lowerEdgeOfButtonNormalColor: lowerEdgeOfButtonNormalColor,
  lowerEdgeOfButtonHighlightColor: lowerEdgeOfButtonHighlightColor,
  standardCalloutBackgroundColor: standardCalloutBackgroundColor,
  standardCalloutForegroundColor: standardCalloutForegroundColor,
  standardCalloutHighlightedForegroundColor: standardCalloutHighlightedForegroundColor,
  standardCalloutSelectedBackgroundColor: standardCalloutSelectedBackgroundColor,
  standardCalloutBorderColor: standardCalloutBorderColor,
  preeditForegroundColor: preeditForegroundColor,
  toolbarButtonForegroundColor: toolbarButtonForegroundColor,
  toolbarButtonHighlightedForegroundColor: toolbarButtonHighlightedForegroundColor,
  candidateHighlightColor: candidateHighlightColor,
  candidateForegroundColor: candidateForegroundColor,
  candidateSeparatorColor: candidateSeparatorColor,
}
