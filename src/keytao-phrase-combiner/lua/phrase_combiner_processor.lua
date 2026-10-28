local kAccepted = 1
local kNoop = 2

local function is_letter(key_event)
  local keycode = key_event.keycode
  return keycode >= 0x61 and keycode <= 0x7a
end

local function is_plain_key(key_event)
  return not key_event:release() and not key_event:ctrl() and not key_event:alt()
end

local function process(key_event, env)
  if not is_plain_key(key_event) then
    return kNoop
  end

  local context = env.engine.context
  local input = context.input or ""
  local key = key_event:repr()

  if key == "semicolon" and (input == "" or input:sub(1, 1) == ";") then
    return kNoop
  end

  if key == "grave" or key == "semicolon" then
    if input:match("^[a-z][a-z`;]*$") and input:match("[a-z]$")
        and not input:find("[`;][`;]")
        and (input:find("[`;]") or context:has_menu()) then
      context:push_input(string.char(key_event.keycode))
    end
    return kAccepted
  end

  if input:match("^[a-z]") and input:find("[`;]") and is_letter(key_event) then
    if context:push_input(string.char(key_event.keycode)) then
      return kAccepted
    end
  end

  return kNoop
end

return { func = process }
