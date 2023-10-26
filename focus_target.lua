local Slab = LibStub("Slab")

local component = {
  dependencies = {'healthBar'}
}

local inset = 18

function component:build(slab)
  local parent = slab.components.healthBar.frame

  local holder = CreateFrame('Frame', parent:GetName() .. 'FocusMarkHolder', parent)
  holder:SetAllPoints()
  holder:Hide()

  local left_text = holder:CreateFontString(holder:GetName() .. 'LeftText', 'OVERLAY')
  left_text:SetPoint('CENTER', holder, 'LEFT', inset, 0)
  left_text:SetFont(Slab.font, Slab.scale(10), 'OUTLINE')
  left_text:SetTextColor(1,0,0,1)
  left_text:SetText('<')

  local right_text = holder:CreateFontString(holder:GetName() .. 'RightText', 'OVERLAY')
  right_text:SetPoint('CENTER', holder, 'RIGHT', -1 * inset, 0)
  right_text:SetFont(Slab.font, Slab.scale(10), 'OUTLINE')
  right_text:SetTextColor(1,0,0,1)
  right_text:SetText('>')

  holder.parent = parent
  holder.base_scale = parent:GetScale()
  holder.selected_multiplier = C_CVar.GetCVar('nameplateSelectedScale')

  return holder
end

function component:bind(settings)
  self.frame:RegisterEvent('PLAYER_FOCUS_CHANGED')
  self.frame:RegisterEvent('PLAYER_TARGET_CHANGED')
end

function component:unbind()
  self.frame:UnregisterAllEvents()
  self.frame:Hide()
end

function component:refresh_marks(settings)
  if UnitGUID(settings.tag) == UnitGUID('focus') then
    self.frame:Show()
    return
  end
  self.frame:Hide()
end

function component:refresh_scale(settings)
  if UnitGUID(settings.tag) == UnitGUID('target') then
    self.frame.parent:SetScale(self.frame.base_scale)
    return
  end
  if UnitGUID(settings.tag) == UnitGUID('focus') then
    self.frame.parent:SetScale(self.frame.base_scale * self.frame.selected_multiplier)
    return
  end
  self.frame.parent:SetScale(self.frame.base_scale)
end


function component:update(event)
  if event == 'PLAYER_FOCUS_CHANGED' then
    self:refresh_marks(self.settings)
    self:refresh_scale(self.settings)
  elseif event == 'PLAYER_TARGET_CHANGED' then
    self:refresh_scale(self.settings)
  end
end

Slab.RegisterComponent('focusTarget', component)
