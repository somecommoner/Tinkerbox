-- Tinkerbox section, Graphics: HDR output and brightness, which the options menu
-- doesn't show. Since a patch, HDR depends on a brightness (nits) value
-- being set, and without one the picture, fog and light look washed out.
-- From the "fix for all your HDR and color grading problems" forum post:
-- HDR on, then either peak brightness (matched to the monitor) with
-- intensity, or a plain brightness value. Intensity does nothing while the
-- plain brightness is in use.

local _, ns = ...

ns.CVarSection({
    module = "graphics",
    key = "gameHDR",
    title = "HDR",
    desc = "HDR output and brightness. Turn on HDR, then set Peak brightness to what your monitor can do and adjust Intensity. Intensity doesn't work while \"Use brightness\" is on, so use one or the other.",
    settings = {
        { cvar = "HDROutput", toggle = true, label = "HDR output",
          desc = "Send an HDR picture to the screen. Needs HDR on in the system too." },
        { cvar = "useHDRPeakBrightness", toggle = true, label = "Use peak brightness",
          desc = "Use the Peak brightness value below. Also brings Intensity back into play." },
        { cvar = "HDRPeakBrightness", label = "Peak brightness",
          desc = "In nits. Match your monitor and system HDR calibration (the post used 400).",
          min = 100, max = 2000, step = 25, decimals = 0 },
        { cvar = "HDRFactor", label = "Intensity",
          desc = "Colour intensity (the post used 1.3). Ignored while \"Use brightness\" is on.",
          min = 0, max = 2, step = 0.05, decimals = 2 },
        { cvar = "useHDRBrightness", toggle = true, label = "Use brightness",
          desc = "Use the Brightness value below instead. Intensity stops working while this is on." },
        { cvar = "HDRBrightness", label = "Brightness",
          desc = "Overall HDR brightness, 0 to 1000.",
          min = 0, max = 1000, step = 10, decimals = 0 },
    },
})
