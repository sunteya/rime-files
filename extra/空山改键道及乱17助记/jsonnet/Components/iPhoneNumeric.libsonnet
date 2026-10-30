local settings = import '../Settings.libsonnet';
local numeric9 = import 'iPhoneNumeric9.libsonnet';
local numericRow = import 'iPhoneNumericRow.libsonnet';
local numericHex = import 'iPhoneNumericHex.libsonnet';

{
  new(isDark, isPortrait):
    if settings.numericLayout == 'row' then
      numericRow.new(isDark, isPortrait, numericRow.KeyboardType.Chinese)
    else if settings.numericLayout == 'hex' then
      numericHex.new(isDark, isPortrait)
    else
      numeric9.new(isDark, isPortrait)
}
