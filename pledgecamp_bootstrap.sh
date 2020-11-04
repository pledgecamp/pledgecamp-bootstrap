#!/usr/bin/env bash

NODE_LTS_NAME=erbium
PYTHON_VERSION=3.8.6

exists()
{
  if command -v $1 &>/dev/null
  then
    return 0
  else
    return 1
    fi
}

echo 'Pledgecamp frontend services bootstrap'
echo 'This script will open up a bunch of new terminal tabs and then start all appropriate services in order to run'
echo 'all frontend services in a development environment'

[ -d ~/.ssh ] || mkdir -p ~/.ssh
[ -d ~/.nvm ] || mkdir ~/.nvm
[ -d ~/pledgecamp ] || mkdir ~/pledgecamp

echo ''
echo 'Setting up SSH key'
if [ -f ~/.ssh/pledgecamp_github ]; then
    echo 'SSH key already exists'
else
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/pledgecamp_github -N ""
    if grep -Fxq "pledgecamp_github" ~/.ssh/config
    then
        echo 'Githb SSH rule already set'
    else
        cat >>~/.ssh/config << END
Host github.com
	IdentityFile ~/.ssh/pledgecamp_github
END
    fi
fi
echo 'Public key contents to be used on Github'
echo ''
cat ~/.ssh/pledgecamp_github.pub
echo ''
echo 'Make sure the above SSH key is present on your Github profile'
read -p "Press enter to continue"

echo ''
echo 'Installing xcode'
xcode-select --install

echo ''
echo 'Setting terminal profile'
if grep -Fxq "# START PLEDGECAMP" ~/.zshrc
    then
        echo 'Rules already set'
    else
        echo 'Rules not yet set'
        cat >>~/.zshrc << END
#
# START PLEDGECAMP
#
# Set an acceptable locale for some of the CLI programs
export LC_ALL="en_US.UTF-8"
# Node version manager
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"
# GoLang settings
export GOPATH="$HOME/go"
# PostgreSQL Tools
export PATH="/usr/local/opt/libpq/bin:$PATH"
# Python management
if command -v pyenv 1>/dev/null 2>&1; then
 eval "$(pyenv init -)"
fi
#
# END PLEDGECAMP
#
END
fi
source ~/.zshrc

echo ''
echo 'Setting up Homebrew'
if exists brew
then
    echo 'Already installed'
    brew upgrade
else
    echo 'Installing homebrew'
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo ''
echo 'Setting up services from brew'
brew install \
    golang \
    hugo \
    libpq \
    nvm \
    pyenv

echo ''
echo "Python setup (${PYTHON_VERSION}) through pyenv."
pyenv install $PYTHON_VERSION
pyenv global $PYTHON_VERSION

echo ''
echo 'Setting up Node'
WRITE_DEFAULT_PACKAGES=true
if [ -f ~/.nvm/default-packages ]; then
    if grep -Fxq "ganache-cli" ~/.nvm/default-packages
    then
        WRITE_DEFAULT_PACKAGES=false
    fi
else
    touch ~/.nvm/default-packages
fi

if $WRITE_DEFAULT_PACKAGES; then
    cat >~/.nvm/default-packages << END
ganache-cli
truffle
ttab
@vue/cli
END
fi

if exists npm
then
    echo 'Node already setup'
else
    echo "Installing Node $NODE_LTS_NAME"
    nvm install --lts=$NODE_LTS_NAME
    nvm alias default lts/$NODE_LTS_NAME
fi

echo ''
echo 'Checking out all projects'
cd ~/pledgecamp
git config --global url."git@github.com:".insteadOf "https://github.com/"
[ -d $GOPATH/src/github.com/pledgecamp/pledgecamp-mail-tester ] || go get -d github.com/pledgecamp/pledgecamp-mail-tester
[ -d $GOPATH/src/github.com/pledgecamp/pledgecamp-oracle ] || go get -d github.com/pledgecamp/pledgecamp-oracle
[ -d $GOPATH/src/github.com/pledgecamp/pledgecamp-techdocs ] || go get -d github.com/pledgecamp/pledgecamp-techdocs
[ -d ~/pledgecamp/pledgecamp-admin ] || git clone git@github.com:pledgecamp/pledgecamp-admin.git
[ -d ~/pledgecamp/pledgecamp-backend ] || git clone git@github.com:pledgecamp/pledgecamp-backend.git
[ -d ~/pledgecamp/pledgecamp-contracts ] || git clone git@github.com:pledgecamp/pledgecamp-contracts.git
[ -d ~/pledgecamp/pledgecamp-frontend ] || git clone git@github.com:pledgecamp/pledgecamp-frontend.git
[ -d ~/pledgecamp/pledgecamp-frontend-toolkit ] || git clone git@github.com:pledgecamp/pledgecamp-frontend-toolkit.git
[ -d ~/pledgecamp/pledgecamp-ico ] || git clone git@github.com:pledgecamp/pledgecamp-ico.git
[ -d ~/pledgecamp/pledgecamp-infrastructure ] || git clone git@github.com:pledgecamp/pledgecamp-infrastructure.git
[ -d ~/pledgecamp/pledgecamp-nodeserver ] || git clone git@github.com:pledgecamp/pledgecamp-nodeserver.git
[ -d ~/pledgecamp/pledgecamp-tokenbridge ] || git clone git@github.com:pledgecamp/pledgecamp-tokenbridge.git
[ -d ~/pledgecamp/pledgecamp-url-shortener ] || git clone git@github.com:pledgecamp/pledgecamp-url-shortener.git

echo ''
echo 'Setting up host aliases'
if grep -Fxq "# START PLEDGECAMP" /etc/hosts
    then
        echo 'Rules already set'
    else
        sudo cat>>/etc/hosts << END
#
# START PLEDGECAMP
#
# Local Development
127.0.0.1 localdev.com
127.0.0.1 admin.localdev.com
127.0.0.1 backend.localdev.com
127.0.0.1 frontend.localdev.com
127.0.0.1 mail.localdev.com
127.0.0.1 nodeserver.localdev.com
127.0.0.1 oracle.localdev.com
127.0.0.1 shortener.localdev.com
# Virtual Machines
192.168.55.5 automation.vmdev.com
# Node1
192.168.55.10 db.vmdev.com
192.168.55.10 frontend.vmdev.com
192.168.55.10 tokenbridge.vmdev.com
192.168.55.10 kibana.vmdev.com
192.168.55.10 tokenbridge-backend.vmdev.com
# Node2
192.168.55.11 backend.vmdev.com
192.168.55.11 auth.vmdev.com
192.168.55.11 shortener.vmdev.com
#
# END PLEDGECAMP
#
END
fi

echo ''
echo 'Starting Services'
echo 'They will open in background tabs'
echo 'opening URL shortener'
ttab -G -t 'pledgecamp-url-shortener ' -d ~/pledgecamp/pledgecamp-url-shortener './dev.sh -s'
echo 'opening mail tester'
ttab -G -t 'pledgecamp-mail-tester' -d ~/go/src/github.com/pledgecamp/pledgecamp-mail-tester './dev.sh -s'
echo 'opening frontend'
ttab -G -t 'pledgecamp-frontend' -d ~/pledgecamp/pledgecamp-frontend './dev.sh -s'
echo 'opening backend'
ttab -G -t 'pledgecamp-backend' -d ~/pledgecamp/pledgecamp-backend './dev.sh -s'
