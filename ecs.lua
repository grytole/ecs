----- Minimal ECS Library 0.1 -----

-- System Callbacks:
--   system:onSystemAdded()        - when system added to the world
--   system:onSystemStarted(dt)    - before system starts to iterate through entities
--   system:onSystemUpdated(e, dt) - called for each entity
--   system:onSystemFinished(dt)   - after system finished iterating through entities
--   system:onSystemRemoved()      - when system removed from the world
--   system:onEntityAdded(e)       - when entity manageable by this system added to the world
--   system:onEntityRemoved(e)     - when entity manageable by this system removed from the world

-- System/Entity Filters:
--   filter(object) - returns true value if object passes implemented check (eg has a field)
--   ecs:filterPassAny(...) - returns filter function that checks for existance of any of passed args in object
--   ecs:filterPassAll(...) - returns filter function that checks for existance of all passed args in object

local ecs = {
  systems = {},
  entities = {}
}

local systemsIndex = {}
local entitiesIndex = {}

-- System API

function ecs:addSystem(system)
  if systemsIndex[system] then
    return nil, 'addSystem(): system already exists'
  end
  table.insert(self.systems, system)
  systemsIndex[system] = #self.systems
  if system.onSystemAdded then system:onSystemAdded() end
  return self, nil
end

function ecs:removeSystem(system)
  if not systemsIndex[system] then
    return nil, 'removeSystem(): system not found'
  end
  table.remove(self.systems, systemsIndex[system])
  systemsIndex[system] = nil
  if system.onSystemRemoved then system:onSystemRemoved() end
  return self, nil
end

-- Entity API

function ecs:addEntity(entity)
  if entitiesIndex[entity] then
    return nil, 'addEntity(): entity already exists'
  end
  table.insert(self.entities, entity)
  entitiesIndex[entity] = #self.entities
  for _, system in ipairs(self.systems) do
    if system.onEntityAdded then
      if not system.filter or system.filter(entity) then
        system:onEntityAdded(entity)
      end
    end
  end
  return self, nil
end

function ecs:removeEntity(entity)
  if not entitiesIndex[entity] then
    return nil, 'removeEntity(): entity not found'
  end
  table.remove(self.entities, entitiesIndex[entity])
  entitiesIndex[entity] = nil
  for _, system in ipairs(self.systems) do
    if system.onEntityRemoved then
      if not system.filter or system.filter(entity) then
        system:onEntityRemoved(entity)
      end
    end
  end
  return self, nil
end

-- World API

function ecs:update(dt, filter)
  for _, system in ipairs(self.systems) do
    if not filter or filter(system) then
      if system.onSystemStarted then system:onSystemStarted(dt) end
      for _, entity in ipairs(self.entities) do
        if system.onSystemUpdated then
          if not system.filter or system.filter(entity) then
            system:onSystemUpdated(entity, dt)
          end
        end
      end
      if system.onSystemFinished then system:onSystemFinished(dt) end
    end
  end
end

-- Filter API

function ecs:filterPassAny(...)
  local items = {}
  for i = 1, select('#', ...) do
    items[i] = select(i, ...)
  end
  return function(object)
    for i = 1, #items do
      if nil ~= object[items[i]] then return true end
    end
    return false
  end
end

function ecs:filterPassAll(...)
  local items = {}
  for i = 1, select('#', ...) do
    items[i] = select(i, ...)
  end
  return function(object)
    for i = 1, #items do
      if nil == object[items[i]] then
        return false
      end
    end
    return true
  end
end

return ecs

----- 01/Dec/24 grytole@gmail.com -----
