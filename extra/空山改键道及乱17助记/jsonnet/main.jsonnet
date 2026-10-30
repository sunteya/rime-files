local iPhonePinyin = import 'Components/iPhonePinyin.libsonnet';
local temp26KeyLayout = import 'Components/Temp26KeyLayout.libsonnet';
local iPhoneAlphabetic = import 'Components/iPhoneAlphabetic.libsonnet';
local iPhoneNumeric = import 'Components/iPhoneNumeric.libsonnet';
local iPhoneNumericRowEn = import 'Components/iPhoneNumericRowEn.libsonnet';
local panel = import 'Components/Panel.libsonnet';
local settings = import 'Settings.libsonnet';
// 引入符号键盘组件
local iPhoneSymbolic = import 'Components/symbolic_portrait.libsonnet'; local iPhoneEmoji = import 'Components/emoji_portrait.libsonnet'; 

local nameToComponent = {
  pinyin: iPhonePinyin,
  alphabetic: iPhoneAlphabetic,
  numeric: iPhoneNumeric,
  panel: panel,
  // 注册符号键盘映射名
  symbolics: iPhoneSymbolic,
  emoji:iPhoneEmoji,
  [if !std.startsWith(settings.keyboardLayout, '26') then 'temp26Key']: temp26KeyLayout,
  [if settings.numericLayout == 'row' then 'numericRowEn']: iPhoneNumericRowEn,
};

local getFileName(componentName, isPortrait) =
  componentName + (if isPortrait then 'Portrait' else 'Landscape');

local config = {
  [name]: {
    iPhone: {
      portrait: getFileName(name, isPortrait=true),
      landscape: getFileName(name, isPortrait=false),
    },
    iPad: {
      portrait: getFileName(name, isPortrait=true),
      landscape: getFileName(name, isPortrait=false),
      floating: getFileName(name, isPortrait=true),
    },
  } for name in std.objectFields(nameToComponent)
};

function(debug=false)
  local toString =
    if debug then
      function(x) std.manifestYamlDoc(x, indent_array_in_object=false, quote_keys=false)
    else
      function(x) std.toString(x);
{
  'config.yaml': std.manifestYamlDoc(config, indent_array_in_object=true, quote_keys=false),
}
// 自动生成所有键盘布局文件: light/dark × portrait/landscape
+ std.foldl(function(acc, x) acc + x, [
  {
    [theme + '/' + getFileName(name, isPortrait=isPortrait) + '.yaml']:
      // 这里会调用你组件里的 new(isDark, isPortrait)
      toString(nameToComponent[name].new(isDark=(theme == 'dark'), isPortrait=isPortrait))
    for name in std.objectFields(nameToComponent)
  }
  for theme in ['light', 'dark']
  for isPortrait in [true, false]
], {})
