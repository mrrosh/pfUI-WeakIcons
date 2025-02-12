pfUI:RegisterModule("WeakIcons", "vanilla", function()
  local watcher = pfWeakIconsWatcherFrame

  -- Utility: Split a string using a separator.
  function string.split(inputstr, sep)
    local t = {}
    for token in string.gfind(inputstr, "([^" .. sep .. "]+)") do
      table.insert(t, token)
    end
    return t
  end

  -- Returns a colored time string using pfUI's API.
  local function GetColoredTimeString(remaining)
    return pfUI.api.GetColoredTimeString(remaining)
  end

  -- Create the GUI configuration entries.
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

  -- Set default configuration values.
  pfUI:UpdateConfig("weakicons", "pbuff", "enabled", "")
  pfUI:UpdateConfig("weakicons", "edebuff", "enabled", "")
  pfUI:UpdateConfig("weakicons", nil, "bufffontsize", "20")
  pfUI:UpdateConfig("weakicons", nil, "debufffontsize", "20")
  pfUI:UpdateConfig("weakicons", nil, "stackfontsize", "11")
  pfUI:UpdateConfig("weakicons", nil, "bufficonsize", "48")
  pfUI:UpdateConfig("weakicons", nil, "debufficonsize", "48")
  pfUI:UpdateConfig("weakicons", nil, "greyscale", "1")

  -----------------------------------------------------------------------------
  -- NewIcon: Create an aura icon frame that updates dynamically.
  -----------------------------------------------------------------------------
  local function NewIcon(args)
    args = args or {}
    -- Use pfUI's default font or a fallback.
    args.font           = pfUI.font_default or "Fonts\\FRITZQT__.TTF"
    args.bufffontsize   = tonumber(C.weakicons.bufffontsize) or 20
    args.debufffontsize = tonumber(C.weakicons.debufffontsize) or 20
    args.stackfontsize  = tonumber(C.weakicons.stackfontsize) or 11
    args.greyscale      = C.weakicons.greyscale
    args.name           = args.name or ""
    args.unit           = args.unit or "player"
    args.size           = (args.unit == "player") and (tonumber(C.weakicons.bufficonsize) or 48) or (tonumber(C.weakicons.debufficonsize) or 48)

    local br, bg, bb, ba = GetStringColor(pfUI_config.appearance.border.color)
    local backdrop_highlight = { edgeFile = pfUI.media["img:glow"], edgeSize = 8 }

    local frameName = "pfWeakIcon_" .. args.name
    local f = CreateFrame("Frame", frameName, UIParent)
    f:SetWidth(args.size)
    f:SetHeight(args.size)
    f:SetPoint("CENTER", UIParent)

    -- Create a texture (initially blank) with trimmed texcoord.
    f.texture = f:CreateTexture()
    f.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.texture:SetAllPoints(f)
    f.texture:SetTexture("")

    -- Create font strings for the timer and stack count.
    f.text = f:CreateFontString()
    f.text:SetPoint("CENTER", f)
    f.text:SetFont(args.font, (args.unit == "player") and args.bufffontsize or args.debufffontsize, "OUTLINE")

    f.smalltext = f:CreateFontString()
    f.smalltext:SetPoint("BOTTOMRIGHT", f)
    f.smalltext:SetFont(args.font, args.stackfontsize, "OUTLINE")

    -- Create a backdrop frame.
    f.backdrop = CreateFrame("Frame", nil, f)
    f.backdrop:SetBackdrop(backdrop_highlight)
    f.backdrop:SetBackdropBorderColor(br, bg, bb, ba)
    f.backdrop:SetAllPoints()

    -----------------------------------------------------------------------------
    -- OnUpdate: Refresh the icon based on the current aura state.
    -----------------------------------------------------------------------------
    f:SetScript("OnUpdate", function()
      if (this.tick or 0) > GetTime() then return end
      this.tick = GetTime() + 0.2  -- update every 0.2 seconds

      -- Use the watcher to fetch aura data by name.
      local auraData = watcher:fetch(args.name, args.unit)
      if auraData then
        if auraData[4] and auraData[4] ~= "" then
          this.texture:SetTexture(auraData[4])
        end

        local remaining = auraData[1] or 0
        if remaining > 0 then
          this.text:SetText(GetColoredTimeString(remaining))
        else
          this.text:SetText("")
        end

        if auraData[5] and auraData[5] > 1 then
          this.smalltext:SetText(auraData[5])
        else
          this.smalltext:SetText("")
        end

        this.texture:SetDesaturated(false)
        this.texture:Show()
        this.backdrop:Show()
      else
        if args.greyscale == "1" then
          this.texture:SetDesaturated(true)
          this.texture:Show()
          this.backdrop:Show()
        else
          this.texture:Hide()
          this.backdrop:Hide()
        end
        this.text:SetText("")
        this.smalltext:SetText("")
      end
    end)

    return f
  end

  -----------------------------------------------------------------------------
  -- Spawn aura icons for tracked player buffs and target debuffs.
  -----------------------------------------------------------------------------
  local pbuffs = string.split(C.weakicons.pbuff.enabled, "#")
  local edebuffs = string.split(C.weakicons.edebuff.enabled, "#")

  for _, name in ipairs(pbuffs) do
    if name and name ~= "" then
      local iconFrame = NewIcon({ name = name, unit = "player" })
      pfUI.api.UpdateMovable(iconFrame)
    end
  end

  for _, name in ipairs(edebuffs) do
    if name and name ~= "" then
      local iconFrame = NewIcon({ name = name, unit = "target" })
      pfUI.api.UpdateMovable(iconFrame)
    end
  end

end)
