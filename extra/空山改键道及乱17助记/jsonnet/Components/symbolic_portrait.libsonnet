local basicStyle = import 'BasicStyle.libsonnet';
local collectionData = import '../Constants/collectionData.libsonnet';
local colors = import '../Constants/Colors.libsonnet';
local fonts = import '../Constants/Fonts.libsonnet';
local commonButtons = import '../Buttons/Common.libsonnet';
local keyboardParams = import '../Buttons/Toolbar.libsonnet';
local preedit = import 'Preedit.libsonnet';

local keyboard(theme, isPortrait) = 
{
  // --- 基础尺寸计算 ---
  local baseKbdHeight = commonButtons.keyboardHeight, 
  local toolbarHeight = keyboardParams.toolbar.height, 

  local totalHeight = baseKbdHeight.portrait + toolbarHeight,
  local h1 = baseKbdHeight.portrait * 0.75 + toolbarHeight,
  local h2 = baseKbdHeight.portrait * 0.25,

  keyboardHeight: {
    portrait: baseKbdHeight.portrait + toolbarHeight,
    landscape: baseKbdHeight.landscape + toolbarHeight,
  },

  keyboardLayout: [
    {
      HStack: {
        style: 'HStackStyle1',
        subviews: [
          { Cell: 'categoryCollection' },
          { Cell: 'descriptionCollection' },
        ],
      },
    },
    {
      HStack: {
        style: 'HStackStyle2',
        subviews: [
          { Cell: 'returnButton' },
          { Cell: 'lockButton' },
          { Cell: 'backspaceButton' },
          { Cell: 'enterButton' },
        ],
      },
    },
  ],

  keyboardStyle: {
//insets: { top: 3, bottom: 3, left: 3, right: 3 },
    backgroundStyle: 'keyboardBackgroundStyle',
  },

  keyboardBackgroundStyle: {
    buttonStyleType: 'geometry',
    normalColor: colors.keyboardBackgroundColor[theme],
  },

  HStackStyle1: { 
    size: { height: std.format("%f/%f", [h1, totalHeight]) } 
  },
  HStackStyle2: { 
    size: { height: std.format("%f/%f", [h2, totalHeight]) } 
  },

  categoryCollection: {
    size: { width: '65/375' },
    type: 'classifiedSymbols',
    dataSource: 'category', 
    insets: { top: 8, bottom: 8 },
    backgroundStyle: 'listBackgroundStyle',
    cellStyle: 'collectionCellStyle',
  },
  listBackgroundStyle: {
    buttonStyleType: 'geometry',
    normalColor: colors.labelColor.quaternary[theme],
    cornerRadius: 7,
    normalLowerEdgeColor: colors.lowerEdgeOfButtonNormalColor[theme],
  },

  descriptionCollection: {
    size: { width: '310/375' },
    type: 'subClassifiedSymbols',
    insets: { top: 8, bottom: 8 },
    displaySeparatorLine: true,
    separatorLineColor: colors.separatorColor[theme],
    maximumRow: 5,
    backgroundStyle: 'descriptionCollectionBackgroundStyle',
    cellStyle: 'descriptionCollectionCellStyle',
  },
  descriptionCollectionBackgroundStyle: {
    buttonStyleType: 'geometry',
    insets: { left: 4, right: 4 },
    normalColor: colors.labelColor.quaternary[theme], 
    cornerRadius: 7,
    normalLowerEdgeColor: colors.lowerEdgeOfButtonNormalColor[theme],
  },

  collectionCellStyle: {
    backgroundStyle: 'collectionCellBackgroundStyle',
    foregroundStyle: 'collectionCellForegroundStyle',
  },
  collectionCellBackgroundStyle: {
    buttonStyleType: 'geometry',
    insets: { left: 4, right: 4 },
    normalColor: colors.labelColor.quaternary[theme], 
    highlightColor: colors.candidateHighlightColor[theme],
    cornerRadius: 7,
  },
  collectionCellForegroundStyle: {
    buttonStyleType: "text",
    normalColor: colors.labelColor.primary[theme],
    highlightColor: colors.labelColor.secondary[theme],
    fontSize: fonts.candidateIndexFontSize, 
    fontWeight: 0,
  },
  descriptionCollectionCellStyle: {
    backgroundStyle: 'collectionCellBackgroundStyle',
    foregroundStyle: 'descriptionCollectionCellForegroundStyle',
  },
  descriptionCollectionCellForegroundStyle: {
    buttonStyleType: "text",
    normalColor: colors.labelColor.primary[theme],
    highlightColor: colors.labelColor.primary[theme],
    fontSize: fonts.candidateTextFontSize, 
    badgeFontSize: 8,
  },

  local currentInsets = if isPortrait then commonButtons.backgroundInsets.portrait else commonButtons.backgroundInsets.landscape,
  
  returnButton: {
    size: { width: { percentage: 0.20 } },
    backgroundStyle: 'colorButtonBackgroundStyle', 
    foregroundStyle: ['returnButtonForegroundStyle'],
    action: 'returnPrimaryKeyboard', 
  },
  returnButtonForegroundStyle: {
    buttonStyleType: "systemImage",
    systemImageName: "arrow.backward",
    normalColor: colors.systemButtonForegroundColor.dark,
    fontSize: fonts.systemButtonImageFontSize,
  },

  lockButton: {
    size: { width: { percentage: 0.29 } },
    backgroundStyle: 'systemButtonBackgroundStyle',
    foregroundStyle: [
      { styleName: "unlockButtonForegroundStyle", conditionKey: "$symbolicKeyboardLockState", conditionValue: false },
      { styleName: "lockButtonForegroundStyle", conditionKey: "$symbolicKeyboardLockState", conditionValue: true }
    ],
    action: 'symbolicKeyboardLockStateToggle',
    notification: "symbolicKeyboardLockStateNotification"
  },

  backspaceButton: {
    size: { width: { percentage: 0.29 } },
    backgroundStyle: 'systemButtonBackgroundStyle',
    foregroundStyle: ['backspaceButtonForegroundStyle'],
    action: 'backspace',
    repeatAction: 'backspace',
  },

  enterButton: {
    size: { width: { percentage: 0.22 } },
    backgroundStyle: 'colorButtonBackgroundStyle', 
    foregroundStyle: ['enterButtonForegroundStyle'],
    action: 'enter', 
  },

  colorButtonBackgroundStyle: {
    buttonStyleType: 'geometry',
    insets: currentInsets,
    normalColor: colors.colorButtonBackgroundColor[theme], 
    highlightColor: colors.colorButtonHighlightedBackgroundColor[theme],
    cornerRadius: 8.5,
    normalLowerEdgeColor: colors.lowerEdgeOfButtonNormalColor[theme],
    highlightLowerEdgeColor: colors.lowerEdgeOfButtonHighlightColor[theme],
  },
  systemButtonBackgroundStyle: {
    buttonStyleType: 'geometry',
    insets: currentInsets,
    normalColor: colors.systemButtonBackgroundColor[theme],
    highlightColor: colors.systemButtonHighlightedBackgroundColor[theme],
    cornerRadius: 8.5,
    normalLowerEdgeColor: colors.lowerEdgeOfButtonNormalColor[theme],
    highlightLowerEdgeColor: colors.lowerEdgeOfButtonHighlightColor[theme],
  },
  backspaceButtonForegroundStyle: {
    buttonStyleType: "systemImage",
    systemImageName: 'delete.left',
    normalColor: colors.systemButtonForegroundColor[theme],
    fontSize: fonts.systemButtonImageFontSize,
    center: { y: 0.53 },
  },
  enterButtonForegroundStyle: {
    text: "$returnKeyType", 
    notification: ['returnKeyTypeChangedNotification'],
    buttonStyleType: "text",
    normalColor: colors.systemButtonForegroundColor.dark,
    highlightColor: colors.systemButtonForegroundColor.dark,
    fontSize: fonts.systemButtonTextFontSize * 0.9,
  },

  lockButtonForegroundStyle: {
    buttonStyleType: "systemImage",
    systemImageName: 'lock',
    normalColor: colors.systemButtonForegroundColor[theme],
    fontSize: fonts.systemButtonImageFontSize,
    targetScale: 0.6,
  },
  unlockButtonForegroundStyle: {
    buttonStyleType: "systemImage",
    systemImageName: 'lock.open',
    normalColor: colors.systemButtonForegroundColor[theme],
    fontSize: fonts.systemButtonImageFontSize,
    targetScale: 0.6,
  },

  symbolicKeyboardLockStateNotification: {
    notificationType: "symbolicKeyboardLockedState",
    lockedState: true,
    backgroundStyle: "systemButtonBackgroundStyle",
    foregroundStyle: "lockButtonForegroundStyle"
  }
};

{
  new(isDark, isPortrait): 
    local theme = if isDark then "dark" else "light";
    local kbd = keyboard(theme, isPortrait);
    
    kbd {
        keyboardHeight: if isPortrait then kbd.keyboardHeight.portrait else kbd.keyboardHeight.landscape
    } 
    + collectionData.symbolicDataSource 
    + preedit.new(isDark) 
    + basicStyle.newKeyboardBackgroundStyle(isDark),
    
  getKeyboard(theme, isPortrait=true): keyboard(theme, isPortrait)
}
