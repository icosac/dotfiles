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
