# QEMU virt has no usable gamma-control or GPU screen-recording path. Keep the
# remaining transient indicators, and stop loading the night-light service.
(.bar.layout.left[], .bar.layout.center[], .bar.layout.right[]
  | select(.id == "omarchy.indicators")
  | .items) = ["Dictation", "Reminder", "Dnd", "StayAwake"]
| .disabledPlugins = ((.disabledPlugins // []) + ["omarchy.nightlight"] | unique)
