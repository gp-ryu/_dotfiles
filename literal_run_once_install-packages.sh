#!/usr/bin/env bash

set -o xtrace

if [ ! -f $HOME/.pixi/bin/pixi ]; then
  curl -fsSL https://pixi.sh/install.sh | bash
  if [ ! -f $HOME/.bashrc ]; then
    echo 'PATH="${HOME}/.pixi/bin:${PATH}"' >>.bashrc
  fi
fi
export PATH="${HOME}/.pixi/bin:${PATH}"
if [ -d ${HOME}/.pixi/envs ]; then
  ls ${HOME}/.pixi/envs >/tmp/installed_packages
else
  touch /tmp/installed_packages
fi

comm -13 <(sort -u /tmp/installed_packages) <(sort -u $HOME/.local/share/chezmoi/dot_config/chezmoi/package_list) | xargs -P2 -I % pixi global install -c dnachun -c conda-forge -c bioconda %

{{ if eq .chezmoi.os "linux" -}}
comm -13 <(sort -u /tmp/installed_packages) <(sort -u $HOME/.local/share/chezmoi/dot_config/chezmoi/linux_packages) | xargs -P2 -I % pixi global install -c dnachun -c conda-forge -c bioconda %
{{ end }}

{{ if eq .chezmoi.os "darwin" -}}
comm -13 <(sort -u /tmp/installed_packages) <(sort -u $HOME/.local/share/chezmoi/dot_config/chezmoi/macos_packages) | xargs -P2 -I % pixi global install -c dnachun -c conda-forge -c bioconda %
brew bundle install --file=$HOME/.local/share/chezmoi/dot_config/chezmoi/Brewfile_casks
export FULL_INSTALL=1
{{ end }}

if [ ! -z ${FULL_INSTALL} ]; then
  comm -13 <(sort -u /tmp/installed_packages) <(sort -u $HOME/.local/share/chezmoi/dot_config/chezmoi/large_packages) | xargs -P2 -I % pixi global install -c dnachun -c conda-forge -c bioconda %
  comm -13 <(sort -u /tmp/installed_packages) <(sort -u $HOME/.local/share/chezmoi/dot_config/chezmoi/huge_packages) | xargs -P2 -I % pixi global install -c dnachun -c conda-forge -c bioconda %
fi

{{ if eq .chezmoi.arch "amd64" -}}
comm -13 <(sort -u /tmp/installed_packages) <(sort -u $HOME/.local/share/chezmoi/dot_config/chezmoi/intel_packages) | xargs -P2 -I % pixi global install -c dnachun -c conda-forge -c bioconda %
{{ end }}

micromamba shell init --shell=bash $HOME/micromamba
micromamba shell init --shell zsh
micromamba config prepend channels nodefaults
micromamba config prepend channels bioconda
micromamba config prepend channels conda-forge
micromamba config prepend channels dnachun

if [ -z $(micromamba env list | grep micromamba | cut -f 3 -d ' ' | grep '^r$') ]; then
  micromamba create -n r
fi

micromamba install -n r r-languageserver r-colorout conda-tree

{{ if eq .chezmoi.os "linux" -}}
ln -sf ${HOME}/.pixi/bin/r ${HOME}/.pixi/bin/R
ln -sf ${HOME}/.pixi/bin/rscript ${HOME}/.pixi/bin/Rscript
{{ end }}

cp ${HOME}/.local/share/chezmoi/dot_config/chezmoi/Rprofile ${HOME}/.pixi/envs/r-base/lib/R/etc/Rprofile.site

# Install
if [ ! -d $HOME/.local/share/zinit ]; then
  export NO_INPUT=1
  export NO_ANNEXES=1
  bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
  zsh -c "source $HOME/.zshrc"
fi

if [ ! -d $HOME/.config/base16-shell ]; then
  git clone https://github.com/chriskempson/base16-shell.git $HOME/.config/base16-shell
fi

if [ ! -d $HOME/.tmux/plugins/tpm ]; then
  git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
  $HOME/.tmux/plugins/tpm/bin/install_plugins
fi

if [ ! -d $HOME/.config/ranger/plugins/ranger_devicons ]; then
  git clone https://github.com/alexanderjeurissen/ranger_devicons $HOME/.config/ranger/plugins/ranger_devicons
fi