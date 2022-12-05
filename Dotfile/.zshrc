# https://shuxiao.wang/posts/zsh-refresh/


# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source ~/.zinit/bin/zi.zsh
zinit ice depth=1; zinit light romkatv/powerlevel10k

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

zinit light mafredri/zsh-async
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-completions
# zsh-fzf-history-search
zinit ice lucid wait'0'
zinit light joshskidmore/zsh-fzf-history-search
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting

# https://medium.com/@dannysmith/little-thing-2-speeding-up-zsh-f1860390f92
autoload -Uz compinit
for dump in ~/.zcompdump(N.mh+24); do
  compinit
done
compinit -C

# ZSH_AUTOSUGGEST
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_HIGHLIGHT_STYLES[comment]=fg=245

# put these 2 lines at the end of plugins settings
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

alias pycharm="nohup sh /home/cc/devtools/pycharm-2022.3/bin/pycharm.sh >/dev/null 2>&1 &"