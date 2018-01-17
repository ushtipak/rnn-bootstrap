#!/bin/bash

# ensure script is running with max powaaaah
[[ "$EUID" -ne 0 ]] && exit 1

# required packages
packages=(gcc-c++ readline-devel libreadline-dev cmake git curl)

# enlist package dependencies
required() { echo "> required packages"; for package in ${packages[@]}; do echo "  $package"; done }

# add option to skip dependency installation
if [ "$1" == '--ommit-dependency-installation' ]; then required
else
  # check if distro uses apt, yum, zypper
  [[ -f /usr/bin/yum ]] && installer="yum -y"
  [[ -f /usr/bin/apt-get ]] && installer="apt-get update; apt-get -y"
  [[ -f /usr/bin/zypper ]] && installer="zypper -n"

  # if neither - inform user to manually install dependencies
  [[ -z ${installer+x} ]] && echo "> install manually and re-run with '--ommit-dependency-installation'" && required && exit 1
  installer="for package in ${packages[@]}; do ${installer} install \${package}; done"
fi

# execute installation command if one is generated
if [ "$installer" != "" ]; then eval "$installer"; fi

# setup torch framework (http://torch.ch/)
curl -s https://raw.githubusercontent.com/torch/ezinstall/master/install-deps | bash 2>&1
git clone https://github.com/torch/distro.git /opt/torch --recursive

# update install script to promptless and exeute
cd /opt/torch
mv install.sh{,-rollback}
sed '/WRITE_PATH_TO_PROFILE/q' install.sh-rollback > install.sh
chmod +x install.sh
./install.sh
ln -s /opt/torch/install/bin/th /bin

# install lua dependencies
for package in nngraph optim nn; do /opt/torch/install/bin/luarocks install $package; done

# retrieve rnn implementation from mr karpathy
git clone https://github.com/karpathy/char-rnn.git /opt/rnn-karpathy

echo "> all done!"
