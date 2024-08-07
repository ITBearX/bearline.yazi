function process_line(file, git_st)
  local year = os.date("%Y")
  local time = (file.cha.modified or 0) // 1

  if time > 0 and os.date("%Y", time) == year then
    time = os.date("%b %d %H:%M", time)
  else
    time = time and os.date("%b %d  %Y", time) or ""
  end

  local size = file:size()
  return ui.Line(string.format(" %s %s %s ", git_st, size and ya.readable_size(size) or "-", time))
end

local version = 3.0

if version >= 3.0 then

  local set_state = ya.sync(function(state)
    if cx.active.conf.linemode ~= "bearline" then
      return
    end
    local handle = io.popen("git rev-parse --is-inside-work-tree 2>/dev/null")
    local result = handle:read("*a")
    handle:close()
    if result:match("true") ~= nil then
      state.is_git = true
      local handle = io.popen("git status --porcelain")
      local result = handle:read("*a")
      handle:close()
      state.git_info = {}
      for line in result:gmatch("[^\n]+") do
        local mod = line:sub(1, 2)
        local filename = line:sub(4)
        state.git_info[filename] = mod
      end
    else
      state.is_git = false
    end
  end)

  local get_state = ya.sync(function(state, filename)
    if cx.active.conf.linemode ~= "bearline" then
      return ""
    end
    if state.is_git then
      return string.format("[%s]", state.git_info[filename] or "  ")
    end
    return ""
  end)

  local basic_render = Linemode.render
  function Linemode.render(self, files)
    set_state()
    return basic_render(self, files)
  end

  function Linemode:bearline()
    git_st = get_state(self._file.name)
    return process_line(self._file, git_st)
  end

  return Linemode
end

local old_linemode = Folder.linemode
function Folder:linemode(area)
  if cx.active.conf.linemode ~= "bearline" then
    return old_linemode(self, area)
  end
  local lines = {}
  for _, f in ipairs(self:by_kind(self.CURRENT).window) do
    lines[#lines + 1] = process_line(f)
  end
  return ui.Paragraph(area, lines):align(ui.Paragraph.RIGHT)
end
return Folder

