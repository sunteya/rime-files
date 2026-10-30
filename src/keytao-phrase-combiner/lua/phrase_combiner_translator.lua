local M = {}

function M.init(env)
  env.translator = Component.TableTranslator(env.engine, "phrase_combiner", "table_translator")
end

function M.func(input, segment, env)
  if not input:find(";") or not input:match("^[a-z][a-z;]*$")
      or input:find(";;") then
    return
  end

  local code = input:gsub(";", "")
  local lookup_segment = Segment(0, #code)
  lookup_segment.tags = Set({ "phrase_combiner" })
  local translation = env.translator:query(code, lookup_segment)
  if not translation then
    return
  end

  for candidate in translation:iter() do
    local result = Candidate("phrase_combiner", segment.start, segment._end, candidate.text, candidate.comment)
    result.quality = candidate.quality
    result.preedit = input
    yield(result)
  end
end

return M
