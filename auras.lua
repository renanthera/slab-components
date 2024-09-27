local Slab = LibStub("Slab")

local HEIGHT = 24

local debuff_whitelist = {
  -- 121253, -- Keg Smash
  123725, -- Breath of Fire
  -- 386276, -- Bonedust Brew
  387179, -- Weapons of Order
  -- 325153, -- Exploding keg
}

local position = 'TOPRIGHT'

local component = {
    dependencies = {'healthBar'}
}

local function find_aura(pool, value, key)
  for widget in pool:EnumerateActive() do
    if widget[key] == value then
      return widget
    end
  end
end

-- Either use Blizzard Cooldown numbers or use OmniCC with the pattern of 'AuraContainerCooldown'

local function creationFunc(pool)
  local frame = CreateFrame('Frame', pool.parent:GetName() .. 'Container')
  frame:SetSize(Slab.scale(HEIGHT), Slab.scale(HEIGHT))

  if position == 'TOPRIGHT' then
    frame:SetPoint('BOTTOMRIGHT', pool.parent, 'BOTTOMRIGHT')
  end
  if position == 'BOTTOM' then
    frame:SetPoint('TOPRIGHT', pool.parent, 'TOP')
  end

  local cooldown = CreateFrame('Cooldown', pool.parent:GetName() .. 'Cooldown', frame, 'CooldownFrameTemplate')
  cooldown:SetAllPoints(frame)
  cooldown:SetReverse(true)

  local icon = frame:CreateTexture(pool.parent:GetName() .. 'Icon')
  icon:SetAllPoints(frame)

  local text = frame:CreateFontString(pool.parent:GetName() .. 'Stacks', 'OVERLAY')

  if position == 'TOPRIGHT' then
    text:SetPoint('CENTER', frame, 'TOP', 0, 1) -- above
  end
  if position == 'BOTTOM' then
    text:SetPoint('CENTER', frame, 'BOTTOM', 0, -1) -- below
  end
  text:SetFont(Slab.font, Slab.scale(16), "OUTLINE")

  frame.icon = icon
  frame.cooldown = cooldown
  frame.text = text

  return frame
end

local function resetterFunc(_, frame)
  frame:Hide()
  frame.text:SetText('')
end

---@param slab Frame
---@return hptextframe
function component:build(slab)
    local parent = slab.components.healthBar.frame

    local aura_container = CreateFrame('Frame', parent:GetName() .. 'AuraContainer', parent)
    aura_container:SetAllPoints(parent.bg)

    if position == 'TOPRIGHT' then
      aura_container:AdjustPointsOffset(0, Slab.scale(HEIGHT / 2 + 3)) -- above
    end
    if position == 'BOTTOM' then
      aura_container:AdjustPointsOffset(0, Slab.scale(-1 * HEIGHT / 2 - 3)) -- below
    end

    local texture_pool = CreateObjectPool(creationFunc, resetterFunc)

    texture_pool.parent = aura_container
    aura_container.pool = texture_pool

    return aura_container
end

---@param settings SlabNameplateSettings
function component:bind(settings)
  self.frame:RegisterUnitEvent('UNIT_AURA', settings.tag)
end

function component:unbind()
    self.frame:UnregisterAllEvents()
    self.frame.pool:ReleaseAll()
end

local function whitelist(spellID, table)
  for _, id in pairs(table) do
    if id == spellID then
      return true
    end
  end
  return false
end

function component:add_auras(settings, update)
  for _, aura in pairs(update) do
    -- DevTools_Dump(aura)
    if aura['sourceUnit'] == 'player' and whitelist(aura['spellId'], debuff_whitelist) then
      -- DevTools_Dump(aura)
      local frame = self.frame.pool:Acquire()
      frame.cooldown:SetCooldownDuration(aura['duration'], aura['timeMod'])
      frame.icon:SetTexture(aura['icon'])
      if aura['applications'] then
        if aura['applications'] > 1 then
          frame.text:SetText(aura['applications'])
        end
      end
      frame:Show()

      frame.aura_instance_id = aura['auraInstanceID']
      frame.spell_id = aura['spellId']
    end
  end
end

function component:update_auras(settings, update)
  for _, aura_instance_id in pairs(update) do
    local frame = find_aura(self.frame.pool, aura_instance_id, 'aura_instance_id')
    if frame then
      local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(settings.tag, aura_instance_id)
      if aura then
        if aura['sourceUnit'] == 'player' and whitelist(aura['spellId'], debuff_whitelist) then
          -- DevTools_Dump(aura)
          frame.cooldown:SetCooldownDuration(aura['duration'], aura['timeMod'])
          if aura['applications'] then
            if aura['applications'] > 1 then
              frame.text:SetText(aura['applications'])
            elseif aura['applications'] < 2 then
              frame.text:SetText('')
            end
          end
        end
      end
    end
  end
end

function component:remove_auras(settings, update)
  for _, aura in pairs(update) do
    local frame = find_aura(self.frame.pool, aura, 'aura_instance_id')
    if frame then
      self.frame.pool:Release(frame)
    end
  end
end

function component:full_update(settings)
  print('full update requested')
  -- do full update
end

function component:sort_auras()
  -- persist these to make updating faster?
  local count = self.frame.pool:GetNumActive()
  local spellIDs = {}
  for frame in self.frame.pool:EnumerateActive() do
    table.insert(spellIDs, frame.spell_id)
  end
  table.sort(spellIDs)
  for index, spellID in ipairs(spellIDs) do
    local frame = find_aura(self.frame.pool, spellID, 'spell_id')
    if position == 'TOPRIGHT' then
      frame:ClearPointsOffset()
      frame:AdjustPointsOffset(floor(-1 * (index - 1) * Slab.scale(HEIGHT + 2) - 2), 0)
    end
    if position == 'BOTTOM' then
      local odd = math.fmod(count, 2)
      frame:ClearPointsOffset()
      frame:AdjustPointsOffset(floor((index - count / 2) * Slab.scale(HEIGHT + 2)), 0)
    end
  end
end

---@param settings SlabNameplateSettings
function component:refresh(settings, update_info)
  if update_info == nil then
    return
  end
  if update_info['isFullUpdate'] then
    self:full_update(settings)
    self:sort_auras()
    return
  end
  if update_info['addedAuras'] then
    self:add_auras(settings, update_info['addedAuras'])
  end
  if update_info['updatedAuraInstanceIDs'] then
    self:update_auras(settings, update_info['updatedAuraInstanceIDs'])
  end
  if update_info['removedAuraInstanceIDs'] then
    self:remove_auras(settings, update_info['removedAuraInstanceIDs'])
  end
  self:sort_auras()
end

function component:update(_, unit_target, update_info)
  if self.settings.tag == unit_target then
    self:refresh(self.settings, update_info)
  end
end

Slab.RegisterComponent('auras', component)
