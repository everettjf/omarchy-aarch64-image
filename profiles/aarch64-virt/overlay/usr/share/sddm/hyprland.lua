-- Minimal Hyprland config for the SDDM Wayland greeter.
-- SDDM starts the greeter itself after the compositor is ready.
hl.config({
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    force_default_wallpaper = 0,
  },

  animations = {
    enabled = false,
  },
})

-- The login screen is a separate Hyprland session owned by the `sddm` user,
-- before Omarchy's desktop watcher exists. Give it the same virtio-gpu mode
-- reconciliation so window and full-screen resizing also work while locked.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
hl.on("hyprland.start", function()
  hl.exec_cmd("/usr/local/libexec/omarchy-ezvm-display-watch")
end)
