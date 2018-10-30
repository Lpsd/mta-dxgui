Gridlist = {}
Gridlist.__index = Gridlist


function Gridlist.new(x, y, w, h)
	local self = setmetatable(Component.new("gridlist", x, y, w, h), Gridlist)
	self.titleh = 25
	self.columns = {}
	self.items = {}
	self.itemh = 45
	self.itemSpacing = 2
	self.maxItems = nil
	self.sp = 1
	self.ep = nil
	self.selectedItem = 0
	self.rt = DxRenderTarget(self.w, self.h, true)
	self.rt_updated = false
	self.scrollbarWidth = 15
	self.paddingLeft = 6
	self.scrollbarVisible = true
	self.textSize = 1.3
	self.titleSpacing = 27
	self.autoSizeColumn = true
	return self
end

local function updateRT(self)
	dxSetRenderTarget(self.rt, true)
	self:fitItemsToColumns()
	self:drawItems()
	dxSetRenderTarget()
end

local function parseItemValues(self, values, parseSingle)
	values = type(values) == 'table' and values or {values}
	local parsed = {}
	for i=1, #values do
		local val = {}
		val.value = tostring(values[i])
		val.width = dxGetTextWidth(val.value, self.textSize)

		if self.columns[i].checkThumbnails then
			if not fileExists(val.value) then
				val.value = 'img/broken.png'
			end
			val.width = self.itemh
		end

		table.insert(parsed, val)
	end
	return parseSingle and parsed[1] or parsed
end

function Gridlist:addColumn(title, width)
	check('s', {title})

	local col = {
		autosize = not width,
		value = tostring(title),
		titleWidth = dxGetTextWidth(title, self.textSize),
		checkThumbnails = false
	}
	col.width = width or col.titleWidth
	table.insert(self.columns, col)
	return col
end

function Gridlist:removeColumn(title)
	check('s', {title})

	for i=#self.columns, 1, -1 do
		if self.columns[i].value == title then
			table.remove(self.columns, i)
		end
	end	
end

function Gridlist:setColumnCheckThumbnails(colIndex, state)
	check('b', {state})

	self.columns[colIndex].checkThumbnails = state
	if state then
		for i=1, #self.items do
			local val = self.items[i].values[colIndex].value
			self.items[i].values[colIndex] = parseItemValues(self, val, true)
		end
	end
end

function Gridlist:getSelectedItemIndex()
	return self.selectedItem
end

function Gridlist:getItemValue(itemIndex, colIndex)
	check('nn', {itemIndex, colIndex})
	return self.items[itemIndex].values[colIndex]
end

function Gridlist:setColumnWidth(colIndex, width)
	check('nn', {colIndex, width})
	self.columns[colIndex].width = width
end

function Gridlist:fitItemsToColumns()
	if not self.autoSizeColumn then return end
	for i=1, #self.columns do
		local col = self.columns[i]

		col.width = col.titleWidth + self.titleSpacing

		for j=1, #self.items do
			local itemVal = self.items[j].values[i].width + self.titleSpacing
			col.width = math.max(itemVal, col.width)
		end
	end
end

function Gridlist:addItem(values, onClick)
	assert(#self.columns ~= 0, "the gridlist doesn't have any columns")

	local item = {
		values = parseItemValues(self, values),
		onClick = onClick or nil
	}

	table.insert(self.items, item)
	updateRT(self)
	return item
end

function Gridlist:removeItem(itemIndex)
	check('n', {itemIndex})
	table.remove(self.items, itemIndex)
	updateRT(self)	
end

function Gridlist:setItemValue(itemIndex, colIndex, value)
	check('nns', {itemIndex, colIndex, value})
	self.items[itemIndex].values[colIndex] = parseItemValues(self, value, true)
end

function Gridlist:getItemByIndex(itemIndex)
	check('n', {itemIndex})
	return self.items[itemIndex]
end

function Gridlist:getCount()
	return #self.items
end

function Gridlist:clear()
	self.items = {}
	self.selectedItem = 0
	self.sp = 1
	updateRT(self)
end

function Gridlist:sort(reverse)
	-- need to sort numbers first then strings?
	local col = self.columns[1]

	if (col) then
		table.sort(self.items, function(a, b)
			if (reverse) then
				return a.values[1] > b.values[1]
			end
			return a.values[1] < b.values[1]
		end)
		updateRT(self)
	end
end

function Gridlist:sortByColumn(colIndex, reverse)
	check('n', {colIndex})
	local col = self.columns[colIndex]

	if (col) then
		table.sort(self.items, function(a, b)
			if (reverse) then
				return a.values[colIndex] > b.values[colIndex]
			end
			return a.values[colIndex] < b.values[colIndex]
		end)
		updateRT(self)
	end
end

function Gridlist:draw()
	if (not self.visible) then return end

	self.mouseOver = mouseX and isMouseOverPos(self.x, self.y, self.w, self.h)
	self.maxItems = math.floor((self.h-self.titleh)/(self.itemh+self.itemSpacing))

	dxDrawRectangle(self.x, self.y, self.w, self.h, tocolor(0,0,0,150))

	if (not self.rt_updated or self.mouseOver and self.focused) then
		updateRT(self) -- draw items onto the render target
		self.rt_updated = true
	end
	
	dxDrawImage(self.x, self.y, self.w, self.h, self.rt)

	self:drawScrollBar()
end

function Gridlist:drawScrollBar()
	if not self.scrollbarVisible then return end
	local itemCount = #self.items
	if itemCount > self.maxItems then
		local shaftw = self.scrollbarWidth
		local shafth = self.h

		local thumbw = self.scrollbarWidth
		local thumbh = (shafth/(itemCount-self.maxItems+1))

		local thumbPos = thumbh * (self.sp - 1)

		-- shaft
		dxDrawRectangle(self.x + self.w - shaftw, self.y, shaftw, shafth, tocolor(66,66,66,200))
		-- thumb
		dxDrawRectangle(self.x + self.w - thumbw, self.y + thumbPos, thumbw, thumbh, tocolor(55,55,255,255))
	end
end

function Gridlist:drawItems()
	if (not self.maxItems) then return end
	local itemCount = #self.items
	self.ep = itemCount < self.maxItems and itemCount or self.sp + self.maxItems - 1

	local paddingX = self.paddingLeft
	local yOff = self.titleh
	local xOff = paddingX

	local columnCount = #self.columns

	-- column titles
	for i=1, columnCount do
		local col = self.columns[i]
		
		if (self.titleh > 0) then
			dxDrawText(col.value, xOff, 0, xOff + col.width, self.titleh, tocolor(255,255,220), self.textSize, "default-bold", "left", "center")
		end

		xOff = xOff + col.width
	end

	-- rows
	for i=self.sp, self.ep do
		local xOff = 0

		local item = self.items[i]
		item.pos = {
			x = self.x,
			y = self.y + yOff,
			w = self.w - self.scrollbarWidth,
			h = self.itemh
		}

		-- styles (temporary, eventually will be replaced with global styles)
		local mo = self.focused and isMouseOverPos(item.pos.x, item.pos.y, item.pos.w, item.pos.h)
		local textColor = (self.selectedItem == i and tocolor(255,255,255)) or (mo and tocolor(55,55,255,255)) or item.color or tocolor(255,255,255)
		local bgColor = (self.selectedItem == i and tocolor(55,55,255,255)) or (mo and tocolor(15,15,15,255)) or item.bgColor or tocolor(23,23,23,255)

		-- item background
		dxDrawImage(xOff, yOff, item.pos.w, self.itemh, "./img/button.png", 0, 0, 0, bgColor)

		for j=1, columnCount do
			local col = self.columns[j]
			local val = item.values[j].value

			if val then
				if col.checkThumbnails then
					dxDrawImage(xOff, yOff, self.itemh, self.itemh, val, 0, 0, 0)
				else
					dxDrawText(val, xOff + paddingX, yOff, xOff + paddingX + col.width, yOff + self.itemh, textColor, self.textSize, 'arial', "left", "center", true, false, false, false, false)
				end
			end

			xOff = xOff + col.width
		end

		yOff = yOff + self.itemh + self.itemSpacing
	end
end

function Gridlist:onKey(key, down)
	if (not self.mouseOver or not self.focused) then return end
	
	self.updated = false

	if (key == "mouse_wheel_down") then
		if (self.sp <= #self.items - self.maxItems) then
			self.sp = self.sp + 1
		end

	elseif (key == "mouse_wheel_up") then
		if (self.sp > 1) then
			self.sp = self.sp - 1
		end

	elseif (key == 'mouse1' and not down) then
		for i=self.sp, self.ep do
			local item = self.items[i]

			if (self.mouseDown and isMouseOverPos(item.pos.x, item.pos.y, item.pos.w, item.pos.h)) then
				self.selectedItem = i
				if item.onClick and type(item.onClick) == 'function' then
					item.onClick()
				end
			end
		end
	end
end

setmetatable(Gridlist, {__call = function(_, ...) return Gridlist.new(...) end})