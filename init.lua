function process_line(file)
  local year = os.date("%Y")
  local time = (file.cha.modified or 0) // 1

  if time > 0 and os.date("%Y", time) == year then
    time = os.date("%b %d %H:%M", time)
  else
    time = time and os.date("%b %d  %Y", time) or ""
  end

  local size = file:size()
  return ui.Line(string.format(" %s %s ", size and ya.readable_size(size) or "-", time))
end

local version = 3.0

if version >= 3.0 then
  function Linemode:bearline()
    return process_line(self._file)
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

