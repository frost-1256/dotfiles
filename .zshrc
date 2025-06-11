# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/spring/.zshrc'
zstyle :prompt:pure:git:stash show yes

ZSH_AUTOSUGGEST_MANUAL_REBIND=1

function source {
  ensure_zcompiled $1
  builtin source $1
}
function ensure_zcompiled {
  local compiled="$1.zwc"
  if [[ ! -r "$compiled" || "$1" -nt "$compiled" ]]; then
    echo "Compiling $1"
    zcompile $1
  fi
}
ensure_zcompiled ~/.zshrc

export PATH=$PATH:/usr/local/bin
# End of lines added by compinstall
local now=$(date +"%s")
local updated=$(date -r ~/.zcompdump +"%s")
local threshold=$((60 * 60 * 24))
if [ $((${now} - ${updated})) -gt ${threshold} ]; then
  compinit
else
  # if there are new functions can be omitted by giving the option -C.
  compinit -C
fi
cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}
sheldon_cache="$cache_dir/sheldon.zsh"
sheldon_toml="$HOME/.config/sheldon/plugins.toml"
# キャッシュがない、またはキャッシュが古い場合にキャッシュを作成
if [[ ! -r "$sheldon_cache" || "$sheldon_toml" -nt "$sheldon_cache" ]]; then
  mkdir -p $cache_dir
  sheldon source > $sheldon_cache
fi
source "$sheldon_cache"
# 使い終わった変数を削除
unset cache_dir sheldon_cache sheldon_toml

#eval "$(starship init zsh)"
autoload -U promptinit; promptinit
prompt pure


#if (which zprof > /dev/null 2>&1) ;then
#  zprof
#fi
unfunction source
