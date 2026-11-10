# colcon's end-of-build desktop notification: skip its python-notify2 backend so it falls
# back to `notify-send`. Regolith's notification daemon (rofication) declares the hints
# argument as strings only (a{ss}, the spec says a{sv}), so notify2's byte hint
# "transient" fails with "Expected a string or unicode object"; notify-send works.
export COLCON_EXTENSION_BLOCKLIST=colcon_notification.desktop_notification.notify2

# ROS 2 is not sourced automatically. Run `ros_source`.
ros_source() {
  local setup
  for setup in /opt/ros/*/setup.zsh(N); do
    source "$setup"
    [[ -r /usr/share/colcon_argcomplete/hook/colcon-argcomplete.zsh ]] &&
      source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.zsh
    print "sourced $setup"
    return 0
  done
  print -u2 "no ROS 2 install found in /opt/ros (./install.sh ros2)"
  return 1
}
