pfUI:RegisterModule("WeakIcons", "vanilla", function()
  local watcher = pfWeakIconsWatcherFrame

  function string.split(inputstr, sep)
    local t = {}
    local i = 1
    while true do
      local s, e = string.find(inputstr, sep)
      if not s then
        t[i] = inputstr
        break
      end
      t[i] = string.sub(inputstr, 1, s-1)
      inputstr = string.sub(inputstr, e+1)
      i = i + 1
    end
    return t
  end

  -- Color-coded time string function (using the existing pfUI function)
  local function GetColoredTimeString(remaining)
    return pfUI.api.GetColoredTimeString(remaining)
  end

  --{{
  -- Init gui config
  pfUI.gui.CreateGUIEntry(T["Thirdparty"], T["Weak Icons"], function()
    pfUI.gui.CreateConfig(nil, T["Own buffs to track"], C.weakicons.pbuff, "enabled", "list")
    pfUI.gui.CreateConfig(nil, T["Enemy debuffs to track"], C.weakicons.edebuff, "enabled", "list")
    pfUI.gui.CreateConfig(nil, T["Buff Font Size"], C.weakicons, "bufffontsize")
    pfUI.gui.CreateConfig(nil, T["Debuff Font Size"], C.weakicons, "debufffontsize")
    pfUI.gui.CreateConfig(nil, T["Stack font size"], C.weakicons, "stackfontsize")
    pfUI.gui.CreateConfig(nil, T["Buff icon size"], C.weakicons, "bufficonsize")
    pfUI.gui.CreateConfig(nil, T["Debuff icon size"], C.weakicons, "debufficonsize")
    pfUI.gui.CreateConfig(nil, T["Greyscale on inactive"], C.weakicons, "greyscale", "checkbox")
  end)

  pfUI:UpdateConfig("weakicons", "pbuff", "enabled", "")
  pfUI:UpdateConfig("weakicons", "edebuff", "enabled", "")
  pfUI:UpdateConfig("weakicons", nil, "bufffontsize", "20")  -- Buff font size
  pfUI:UpdateConfig("weakicons", nil, "debufffontsize", "20")  -- Debuff font size
  pfUI:UpdateConfig("weakicons", nil, "stackfontsize", "11")
  pfUI:UpdateConfig("weakicons", nil, "bufficonsize", "48")  -- Buff icon size
  pfUI:UpdateConfig("weakicons", nil, "debufficonsize", "48")  -- Debuff icon size
  pfUI:UpdateConfig("weakicons", nil, "greyscale", "1")
  --}}

  -- Function to create new aura icons
  local function Newicon(args)
    args = args or {}

    args.font       = pfUI.font_default or "Fonts\\FRITZQT__.TTF"
    args.bufffontsize = tonumber(C.weakicons.bufffontsize) or 20  -- Buff font size
    args.debufffontsize = tonumber(C.weakicons.debufffontsize) or 20  -- Debuff font size
    args.sfontsize  = 11
    args.stackfontsize = tonumber(C.weakicons.stackfontsize) or 11  -- Stack font size
    args.greyscale  = C.weakicons.greyscale
    args.name       = args.name or ""
    args.size       = args.unit == "player" and (C.weakicons.bufficonsize or 48) or (C.weakicons.debufficonsize or 48)  -- Buff or debuff icon size
    args.unit       = args.unit or "player"

    local br, bg, bb, ba = GetStringColor(pfUI_config.appearance.border.color)
    local backdrop_highlight = { edgeFile = pfUI.media["img:glow"], edgeSize = 8 }

    local texture
    if L["icons"][args.name] then
      texture = "Interface\\Icons\\" .. L["icons"][args.name]
    else
      texture = "Interface\\Icons\\Temp"
    end

    local framename = string.gsub("pfweakicons" .. args.name .. "Frame", "%s+", "")
    local f = CreateFrame("Frame", framename, UIParent)
    f.name = framename -- Just for good measure
    f:SetWidth(args.size)
    f:SetHeight(args.size)
    f:SetPoint("CENTER", UIParent)

    f.texture = f:CreateTexture()
    f.texture:SetTexCoord(.08, .92, .08, .92) -- Zooms the texture in to hide borders
    f.texture:SetAllPoints(f)
    f.texture:SetTexture(texture)

    f.text = f:CreateFontString()
    f.text:SetPoint("CENTER", f)
    f.text:SetFont(args.font, args.unit == "player" and args.bufffontsize or args.debufffontsize, "OUTLINE")  -- Buff or Debuff font size

    f.smalltext = f:CreateFontString()
    f.smalltext:SetPoint("BOTTOMRIGHT", f)
    f.smalltext:SetFont(args.font, args.stackfontsize, "OUTLINE")  -- Use the stack font size

    f.backdrop = CreateFrame("Frame", nil, f)
    f.backdrop:SetBackdrop(backdrop_highlight)
    f.backdrop:SetBackdropBorderColor(br, bg, bb, ba)
    f.backdrop:SetAllPoints()

f:SetScript("OnUpdate", function()
  if (this.tick or 1) > GetTime() then return end
  this.tick = GetTime() + 0.2  -- Faster update frequency (0.2 instead of 0.4)

  local auratable = watcher:fetch(args.name, args.unit)
  
  if not auratable then
    if args.greyscale == "1" then
      this.texture:SetDesaturated(true) -- Greyed out if inactive
      this.texture:Show()
      this.backdrop:Show()
    else
      this.texture:Hide()  -- Hide texture
      this.backdrop:Hide() -- Hide backdrop
    end
    this.text:SetText(nil)
    this.smalltext:SetText(nil)
  else
    local remainingTime = auratable[1]
    if remainingTime > 0 then
      local formattedTime = GetColoredTimeString(remainingTime)
      this.text:SetText(formattedTime)
    else
      this.text:SetText(nil)
    end

    if auratable[5] and auratable[5] > 1 then
      this.smalltext:SetText(auratable[5])
    else
      this.smalltext:SetText(nil)
    end

    this.texture:SetDesaturated(false) -- Make sure active buffs are in full color
    this.texture:Show()
    this.backdrop:Show()
  end
end)



    return f
  end

  -- Spawn icons for player buffs and target debuffs
local pbuffs = string.split(C.weakicons.pbuff.enabled, "#")
local edebuffs = string.split(C.weakicons.edebuff.enabled, "#")

for _, v in ipairs(pbuffs) do
  if v and v ~= "" then  -- Only create if a valid buff name exists
    local f = Newicon({ name = v, unit = "player" })
    pfUI.api.UpdateMovable(f)
  end
end

for _, v in ipairs(edebuffs) do
  if v and v ~= "" then  -- Only create if a valid debuff name exists
    local f = Newicon({ name = v, unit = "target" })
    pfUI.api.UpdateMovable(f)
  end
end
if not args.name or args.name == "" then return end  -- Prevent empty frames

end)
