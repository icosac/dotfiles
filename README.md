# MAIN DISCLOSURE
Having this thing to properly work each time is a real pain. 

It should be used as a base to install the software needed and avoid the major difficulties in the installation. 

The problem is that I don't have time to install-remove-reinstall the software to test that the changes made don't break something else and at the moment I cannot come up with an idea to automate such a thing. We'll see in the future.

## BEFORE INSTALLING

Before installing make sure of knowing the following:

- When installing **git**:
  - The script autoconfigures git by reading the file git/config so make sure to correctly set the values within
  - It's possible to generate the ssh keys for GitHub, GitLab and Bitbucket. The script will give you 5 seconds to make a decision, otherwise it will continue without generating them. If you choose to generate them, the script will prompt for the passwords to be used.

- When installing **zsh**:
  - It's possible that you will be prompted for the user password when using `chsh` to change the default shell. For some reasons, oh-my-zsh is not able to change shell on its own.


## ROS2

To install ROS2 for Ubuntu, I rely on [this repo](https://github.com/Tiryoh/ros2_setup_scripts_ubuntu). Run the script from a normal user.
