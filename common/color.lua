local Color = {}

function Color.explodeArgb(argb)
	local a = bit.band(bit.rshift(argb, 24), 0xFF)
	local r = bit.band(bit.rshift(argb, 16), 0xFF)
	local g = bit.band(bit.rshift(argb, 8), 0xFF)
	local b = bit.band(argb, 0xFF)
	return a, r, g, b
end

function Color.joinArgb(a, r, g, b)
	local argb = b
	argb = bit.bor(argb, bit.lshift(g, 8))
	argb = bit.bor(argb, bit.lshift(r, 16))
	argb = bit.bor(argb, bit.lshift(a, 24))
	return argb
end

function Color.argbToRgba(argb)
	local a, r, g, b = Color.explodeArgb(argb)
	return Color.joinArgb(r, g, b, a)
end

function Color.argbToAbgr(argb)
	return bit.bor(
		bit.lshift(bit.band(bit.rshift(argb, 24), 0xFF), 24),
		bit.lshift(bit.band(argb, 0xFF), 16),
		bit.lshift(bit.band(bit.rshift(argb, 8), 0xFF), 8),
		bit.band(bit.rshift(argb, 16), 0xFF)
	)
end

function Color.toHexTag(value)
	return '{' .. string.sub(bit.tohex(value), 3, 8) .. '}'
end

function Color.renderWorldLine(x1, y1, z1, x2, y2, z2, width, color, radius)
	local screenX1, screenY1 = convert3DCoordsToScreen(x1, y1, z1)
	local screenX2, screenY2 = convert3DCoordsToScreen(x2, y2, z2)
	if isPointOnScreen(x1, y1, z1, radius) or isPointOnScreen(x2, y2, z2, radius) then
		renderDrawLine(screenX1, screenY1, screenX2, screenY2, width, color)
	end
end

return Color
