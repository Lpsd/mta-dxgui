components = Table.new()

Component = {}

function Component.new(typ, x, y, w, h)
	check('nnnn', {x, y, w, h}, 5)
	local self = inherit({}, Component)
	self.ox = x
	self.oy = y
	self.x = x
	self.y = y
	self.w = w
	self.h = h
	self.offx = 0
	self.offy = 0
	self.type = typ
	self.value = ''
	self.children = Table.new()
	self.events = Table.new()
	self.parent = nil
	self.visible = true
	self.focused = false
	self.mouseOver = false
	self.mouseDown = false

	components:insert(1, self)

	return self
end

function Component:update()
	if (not self.visible) then return end

	local parent = self.parent
	
	if (parent) then
		self.x = parent.x + self.ox + parent.offx
		self.y = parent.y + self.oy + parent.offy
		self.focused = parent.focused -- children need a separate focus to fix child z-order issue
	end
	
	if (self.draw) then
		self:draw()
	end

	if (self.drawBorders) then
		self:drawBorders()
	end
	
	for i=#self.children, 1, -1 do
		self.children[i]:update()
	end

	self.mouseOver = (self.focused or not parent) and isMouseOverPos(self.x, self.y, self.w, self.h)
end

function Component:focus()
	if self.parent then
		self.parent.focused = true
	else
		self.focused = true
	end
	for i=1, #components do
		if self ~= components[i] then
			components[i].focused = false
		end
	end
end

function Component:destroy()
	local children = self.children
	for i=#children, 1, -1 do
		children[i]:destroy()
	end

	local parent = self.parent
	if (parent) then
		parent.children:removeByValue(self)
	else
		components:removeByValue(self)
	end

	dxCallEvent(self, "destroy", self)

	for k in pairs(self) do
		self[k] = nil
	end

	collectgarbage()
end

function Component:setParent(parent)
	if not isComponent(parent) then
		error("the parent doesn't exist or was destroyed", 2)
	end

	if self.parent then
		self:removeParent()
	end
	parent.children:insert(self)
	self.parent = parent
	components:removeByValue(self)
	return self
end

function Component:addChildren(children)
	if isComponent(children) then
		children:setParent(self)
	elseif type(children) == 'table' then
		for i=1, #children do
			if isComponent(children[i]) then
				children[i]:setParent(self)
			end
		end
	end
end

function Component:removeParent()
	if not self.parent then
		return self
	end
	self.parent.children:removeByValue(self)
	self.parent = nil
	components:insert(self)
	return self
end

function Component:setOnTop()
	local comps = self.parent and self.parent.children or components
	if comps[1] ~= self then
		comps:removeByValue(self)
		comps:insert(1, self)
	end
	self:focus()
	return self
end

function Component:setToBack()
	local comps = self.parent and self.parent.children or components
	if comps[#comps] ~= self then
		comps:removeByValue(self)
		comps:insert(self)
	end
	return self
end

function Component:on(event, callback)
	self.events:insert({
		event = event,
		callback = callback
	})
	return self
end

function Component:once(event, callback)
	self.events:insert({
		event = event,
		callback = callback,
		once = true
	})
	return self
end

function Component:removeOn(event, callback)
	for i=1, #self.events do
		local evt = self.events[i]
		if evt.event == event and evt.callback == callback then
			table.remove(self.events, i)
		end
	end
	return self
end

function Component:getPosition()
	return self.x, self.y
end

function Component:setPosition(x, y)
	x = x or self.x
	y = y or self.y
	self.ox, self.oy = x, y
	self.x, self.y = x, y
	return self
end

function Component:getSize()
	return self.w, self.h
end

function Component:setSize(w, h)
	self.w, self.h = w, h
	return self
end

function Component:getVisible()
	return self.visible
end

function Component:setVisible(v)
	self.visible = v
	return self
end

function Component:getText()
	return self.value
end

function Component:setText(v)
	self.value = v
	return self
end

function Component:align(state)
	local sw, sh = guiGetScreenSize()
	if (self.parent) then
		if (state == "center" or state == "centerX") then
			self.ox = self.parent.w/2-self.w/2
		end
		if (state == "center" or state == "centerY") then
			self.oy = self.parent.h/2-self.h/2
		end
	else
		if (state == "center" or state == "centerX") then
			self.x = sw/2-self.w/2
		end
		if (state == "center" or state == "centerY") then
			self.y = sh/2-self.h/2
		end
	end
	return self
end