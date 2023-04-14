local Slab = LibStub("Slab")

local component = {
    dependencies = {'healthBar'}
}

---@param number integer
---@return string
local function format_thousands(number)
  if number == 0 or number == math.huge or number == -math.huge then
    return 0
  end
  if number < 1000 then
    return number
  end
  local unit = ' kMGTPEZYRQ'
  local order = math.log10(number)
  local unit_index = math.floor(order / 3)
  local formatted_number = number / (10 ^ (unit_index * 3))
  return string.format('%.2f',formatted_number) .. string.sub(unit, unit_index + 1, unit_index + 1)
end

---@param number integer
---@param max integer
---@return string
local function format_percent(number, max)
  local percent_hp = number / max
  if percent_hp < 0.995 then
    return string.format('%.2f', number / max * 100) .. '%'
  end
  return '100%'
end


---@param slab Frame
---@return hptextframe
function component:build(slab)
    local parent = slab.components.healthBar.frame

    local hptextframe = CreateFrame('Frame', parent:GetName() .. 'HPTextHolder', parent)
    hptextframe:SetPoint('CENTER', parent, 'CENTER')

    local hptext = hptextframe:CreateFontString(hptextframe:GetName() .. 'Text', 'OVERLAY')
    hptext:SetPoint('CENTER', parent, 'CENTER', 0, 0)
    hptext:SetFont(Slab.font, Slab.scale(8), "OUTLINE")

    hptextframe.text = hptext
    return hptextframe
end

---@param settings SlabNameplateSettings
function component:bind(settings)
  self.frame:RegisterUnitEvent('UNIT_HEALTH', settings.tag)
end

function component:unbind()
    self.frame:UnregisterAllEvents()
end

---@param settings SlabNameplateSettings
function component:refresh(settings)
  local unitid = settings.tag
  local currenthp = UnitHealth(unitid)
  local maxhp = UnitHealthMax(unitid)
  local formattedhp = format_thousands(currenthp) .. ' ' .. format_percent(currenthp, maxhp)
  self.frame.text:SetText(formattedhp)
end

function component:update()
    self:refresh(self.settings)
end

Slab.DeregisterComponent('todIndicator')
Slab.RegisterComponent('hpNumbers', component)
