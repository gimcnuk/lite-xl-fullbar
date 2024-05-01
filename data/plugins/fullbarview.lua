-- mod-version:3 --lite-xl 2.1

local core = require "core"
local common = require "core.common"
local command = require "core.command"
local config = require "core.config"
local style = require "core.style"
local View = require "core.view"

local FullbarView = View:extend()

function FullbarView:new()
	FullbarView.super.new(self)
	
	--[[ config ]]--
	
	-- horizontal up = "hu", horizontal down = "hd", vertical left = "vl", vertical right = "vr"
	self.orient = "hu"
	
	--self.fufont = style.icon_big_font
	self.fufont = nil
	core.try(function() self.fufont = renderer.font.load(DATADIR .. "/fonts/tabler-icons.ttf", 23 * SCALE, {antialiasing="grayscale", hinting="full"}) end)
	core.try(function() self.fufont = renderer.font.load(USERDIR .. "/fonts/tabler-icons.ttf", 23 * SCALE, {antialiasing="grayscale", hinting="full"}) end)

	-- not implemented: 1 - button only, 2 - text only, 3 - button and text
	--self.show = 3
	self.visible = true
	self.size.x = 32 * 1.6 * SCALE
	self.size.y = 25 * 1.6 * SCALE

	
	self.sep = "--SEPARATOR--" -- 60052 for vertical, 60053 for horizontal

	-- dec codes from font table
	self.fucommands = {
		{symbol = utf8.char(60068), command = "core:new-doc", text = "New"},
		{symbol = utf8.char(60078), command = "core:open-file", text = "Open"},
		{symbol = utf8.char(60258), command = "doc:save", text = "Save"},
		{symbol = utf8.char(60052), command = self.sep, text = "Separator"},
		{symbol = utf8.char(60279), command = "doc:undo", text = "Undo"},
		{symbol = utf8.char(60280), command = "doc:redo", text = "Redo"},
		{symbol = utf8.char(60052), command = self.sep, text = "Separator"},
		{symbol = utf8.char(60188), command = "find-replace:find", text = "Search"},
		{symbol = utf8.char(61097), command = "search-replace:toggle", text = "Search"},
		{symbol = utf8.char(60381), command = "line-wrapping:toggle", text = "Wrap"},
		{symbol = utf8.char(60765), command = "core:find-file", text = ""},
		{symbol = utf8.char(60024), command = "core:find-command", text = ""},
		{symbol = utf8.char(60192), command = "core:open-user-module", text = ""},
		{symbol = utf8.char(60192), command = "ui:settings", text = ""},
		{symbol = utf8.char(60328), command = "core:quit", text = "Quit"},
	}
	
end

function FullbarView:get_icon_width()
	local max_dim = 0
	for i,v in ipairs(self.fucommands) do max_dim = math.max(max_dim, self.fufont:get_width(v.symbol)) end
	return max_dim
end

function FullbarView:each_item()
	local icon_h, icon_w = self.fufont:get_height(), self:get_icon_width()
	local fullbar_spacing = icon_h / 3
	local ox, oy = self:get_content_offset()
	local index = 0
	
	local iter = function()
		index = index + 1
		if index <= #self.fucommands then
			local dx, dy
			
			if self.orient == "vl" or self.orient == "vr" then
				dx = style.padding.x
				dy = style.padding.y + (icon_h + fullbar_spacing) * (index - 1)
				
				if dy + icon_h > self.size.y then return end
			else 
				dx = style.padding.x + (icon_w + fullbar_spacing) * (index - 1)
				dy = style.padding.y
				
				if dx + icon_w > self.size.x then return end
			end
			return self.fucommands[index], ox + dx, oy + dy, icon_w, icon_h
		end
	end
	return iter
end

function FullbarView:draw()
	if not self.visible then return end
	
	self:draw_background(style.background)

	for item, x, y, w, h in self:each_item() do
		local color = item == self.hovered_item and (command.is_valid(item.command) or item.command == self.sep) and style.text or style.dim
	
		--renderer.draw_rect(x, y, w, h, style.background2)
		common.draw_text(self.fufont, color, item.symbol, nil, x, y, w, h)
	end
end


function FullbarView:on_mouse_pressed(button, x, y, clicks)
	if not self.visible then return end
	local caught = FullbarView.super.on_mouse_pressed(self, button, x, y, clicks)
	if caught then return caught end
	core.set_active_view(core.last_active_view)
	if self.hovered_item and command.is_valid(self.hovered_item.command) and self.hovered_item.command ~= self.sep then
		command.perform(self.hovered_item.command)
	end
	return true
end


function FullbarView:on_mouse_moved(px, py, ...)
	if not self.visible then return end
	FullbarView.super.on_mouse_moved(self, px, py, ...)
	self.hovered_item = nil
	local x_min, x_max, y_min, y_max = self.size.x, 0, self.size.y, 0
	for item, x, y, w, h in self:each_item() do
		x_min, x_max = math.min(x, x_min), math.max(x + w, x_max)
		y_min, y_max = y, y + h
		if px > x and py > y and px <= x + w and py <= y + h then
			if item.command ~= self.sep then 
				self.hovered_item = item
				core.status_view:show_tooltip(command.prettify_name(item.command))
				self.tooltip = true
			end
			return
		end
	end
	if self.tooltip and not (px > x_min and px <= x_max and py > y_min and py <= y_max) then
		core.status_view:remove_tooltip()
		self.tooltip = false
	end
end

--[[ init ]]--

local fuview = FullbarView()
local funode = core.root_view:get_active_node()
local orient = fuview.orient

if orient == "vl" then
	fuview.node = funode:split("left", fuview, {x = true})
elseif orient == "vr" then
	fuview.node = funode:split("right", fuview, {x = true})
elseif orient == "hu" then
	fuview.node = funode:split("up", fuview, {y = true})
elseif orient == "hd" then
	fuview.node = funode:split("down", fuview, {y = true})
else
	--
end

return fuview
