local Slab = LibStub("Slab")

local component = {
  dependencies = {'healthBar'}
}

function component:build(slab)
  local parent = slab.components.healthBar.frame
  parent.name:ClearAllPoints()
  parent.name:SetPoint('LEFT', parent.reactionIndicator, 'RIGHT')
  parent.name:SetFont(Slab.font, Slab.scale(7), 'OUTLINE')

  return nil
end

function component:bind(settings)
end

function component:unbind()
end

function component:refresh_marks(settings)
end

function component:refresh_scale(settings)
end


function component:update(event)
end

Slab.RegisterComponent('misc', component)
