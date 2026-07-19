local colors = {
  base = 0xff1e1e2e,
  mantle = 0xff181825,
  crust = 0xff11111b,
  text = 0xffcdd6f4,
  subtext0 = 0xffa6adc8,
  overlay0 = 0xff6c7086,
  surface0 = 0xff313244,
  surface1 = 0xff45475a,
  lavender = 0xffb4befe,
  mauve = 0xffcba6f7,
  teal = 0xff94e2d5,
  green = 0xffa6e3a1,
  yellow = 0xfff9e2af,
  peach = 0xfffab387,
  red = 0xfff38ba8,
  transparent = 0x00000000,
  bar_bg = 0xcc1e1e2e,
}

function colors.with_alpha(color, alpha)
  if alpha < 0 or alpha > 1 then
    return color
  end
  return (color & 0x00ffffff) | (math.floor(alpha * 255) << 24)
end

return colors
