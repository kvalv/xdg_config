#! env bash

XDG_HOME=$HOME/.config

function setup-zsh() {
    ln --synbolic $XDG_HOME/zshrc $HOME/.zhsrc
}


