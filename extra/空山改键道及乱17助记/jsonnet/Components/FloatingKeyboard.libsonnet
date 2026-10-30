local toolbarParams = import '../Buttons/Toolbar.libsonnet';
local basicStyle = import 'BasicStyle.libsonnet';
local utils = import 'Utils.libsonnet';

local floatingKeyboardButtonsDefine = {
  // 浮动键盘面板按钮定义，格式如下：

  // 第一个浮动键盘名称: [
  //    [按钮行1],
  //    [按钮行2],
  // ],
  // 第二个浮动键盘名称: [
  //    [按钮行1],
  //    [按钮行2],
  // ],

  panel: [
    [
      toolbarParams.toolbarButton.toolbarHamster3Button,
      toolbarParams.toolbarButton.toolbarKeyboardDefinition,
      toolbarParams.toolbarButton.toolbarFeedbackButton,
      toolbarParams.toolbarButton.toolbarCheckUpdateButton,
    ],
    [
      toolbarParams.toolbarButton.toolbarSkinButton,
      toolbarParams.toolbarButton.toolbarSkinPreference,
      toolbarParams.toolbarButton.toolbarRimeSyncButton,
      toolbarParams.toolbarButton.toolbarToggleEmbeddedButton,
    ],
  ],
};

local newKeyLayout(buttonsInRow, isDark=false, isPortrait=false) =
  local floatTargetScale = if isPortrait then toolbarParams.floatingKeyboard.floatTargetScale.portrait else toolbarParams.floatingKeyboard.floatTargetScale.landscape;
  {
    floatTargetScale: floatTargetScale,
    keyboardStyle: {
        insets: toolbarParams.floatingKeyboard.insets,
      }
      + utils.newBackgroundStyle(style=basicStyle.keyboardBackgroundStyleName),
  }
  + utils.newRowKeyboardLayout(buttonsInRow)
  + std.foldl(function(acc, button) acc +
      basicStyle.newFloatingKeyboardButton(button.name, isDark, button.params),
      std.flattenArrays(buttonsInRow),
      {});

local newFloatingKeyboard(buttonsInRow, isDark=false, isPortrait=false) =
  basicStyle.newKeyboardBackgroundStyle(isDark)
  + basicStyle.newFloatingKeyboardButtonBackgroundStyle(isDark)
  + newKeyLayout(buttonsInRow, isDark, isPortrait);

{
  new(isDark=false, isPortrait=false):
    {
      [name]: newFloatingKeyboard(floatingKeyboardButtonsDefine[name], isDark, isPortrait)
      for name in std.objectFields(floatingKeyboardButtonsDefine)
    }
}
