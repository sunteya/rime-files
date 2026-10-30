local settings = import '../Settings.libsonnet';
local numericRow = import 'iPhoneNumericRow.libsonnet';

{
  new(isDark, isPortrait):
    numericRow.new(isDark, isPortrait, numericRow.KeyboardType.English)
}
