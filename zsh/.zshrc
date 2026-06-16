# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.


[[ $- != *i* ]] && return

# --- Aliases ---
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias nv='NVIM_APPNAME="nvchad" nvim'
alias vim='nvim'
alias ssh='TERM=xterm-256color ssh'
alias hb='systemctl hibernate'
bindkey -e




# --- Environment Variables & Path ---
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# --- Zsh Specifics (Recommended) ---
export EDITOR="nvim"
export VIRTUAL_ENV_DISABLE_PROMPT=1
export GOPATH="/home/mejxe/go/bin"
export JAVA_HOME="/usr/lib/jvm/default"
export BROWSER="/usr/bin/zen-browser"

# --- Path Updates ---
export PATH="$PATH:/home/mejxe/.local/bin"
export PATH="$PATH:$HOME/.config/emacs/bin"


bindkey "^?" backward-delete-char
bindkey "^H" backward-delete-char
HISTSIZE=9999
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups
setopt hist_ignore_dups
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit's installer chunk
zinit ice depth=1; zinit light romkatv/powerlevel10k
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-history-substring-search
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

zinit snippet OMZP::git

autoload -Uz compinit && compinit
zstyle ':completion:*' menu no 
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # Case insensitive
zstyle ':completion:*' list-colors  "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
eval "$(fzf --zsh)"
esp() { 
  git config --global --get-all safe.directory \
    | grep -q '^/opt/esp-idf$' \
    || git config --global --add safe.directory /opt/esp-idf
  source /opt/esp-idf/export.sh
  alias idf=idf.py
  eval "$(env LANG=en \
              _IDF.PY_COMPLETE=bash_source \
              idf.py \
    | sed -e 's,$1,$1.py,' \
          -e 's,idf\.py$,idf,' \
          -e 's,_idfpy_completion,_idfpy_completion2,')"
}
### Input method setup
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
