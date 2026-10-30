local settings = import '../Settings.libsonnet';
local layout9  = import 'iPhonePinyin9.libsonnet';
local layout14 = import 'iPhonePinyin14.libsonnet';
local layout17 = import 'iPhonePinyin17.libsonnet';
local layout18 = import 'iPhonePinyin18.libsonnet';
local layout26 = import 'iPhonePinyin26.libsonnet';
local layoutBopomofo = import 'iPhoneBopomofo.libsonnet';
local layoutSigma = import 'iPhonePinyinSigma.libsonnet';

{
  new(isDark, isPortrait):
    if settings.keyboardLayout == '9' then
      layout9.new(isDark, isPortrait)
    else if settings.keyboardLayout == '14' then
      layout14.new(isDark, isPortrait)
    else if settings.keyboardLayout == '17' then
      layout17.new(isDark, isPortrait)
    else if settings.keyboardLayout == '18' then
      layout18.new(isDark, isPortrait)
    else if settings.keyboardLayout == 'bopomofo' then
      layoutBopomofo.new(isDark, isPortrait)
    else if settings.keyboardLayout == 'sigma' then
      layoutSigma.new(isDark, isPortrait)
    else
      layout26.new(isDark, isPortrait),
}
