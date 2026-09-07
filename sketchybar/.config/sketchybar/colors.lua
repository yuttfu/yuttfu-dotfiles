local colors = require("desktop-theme").colors

function colors.with_alpha(color, alpha)
  if alpha < 0 or alpha > 1 then return color end
  return (color & 0x00ffffff) | (math.floor(alpha * 255) << 24)
end

return colors
