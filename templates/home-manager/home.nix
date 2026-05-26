{ config, pkgs, lib, username, homeDirectory, nixDevshellsPath, gitName, gitEmail, ... }:

{
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    zsh-powerlevel10k
  ];

  home.sessionVariables = {
    EDITOR = "vim";
    PAGER = "less";
  };

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    settings.user = {
      name = gitName;
      email = gitEmail;
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      nix-personal-default = "nix develop --profile ~/nix-workspace/personal-default ${nixDevshellsPath}/flakes/default -c zsh -i";
      nix-personal-latest = "nix develop --profile ~/nix-workspace/personal-latest ${nixDevshellsPath}/flakes/latest -c zsh -i";
      nix-personal-devops = "nix develop --profile ~/nix-workspace/personal-devops ${nixDevshellsPath}/flakes/devops -c zsh -i";
    };
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
      }
    ];
    initContent = ''
      if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
        source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      fi
      if [ -f "$HOME/.nix-profile/share/zsh-powerlevel10k/powerlevel10k.zsh-theme" ]; then
        source "$HOME/.nix-profile/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
      fi
      if [[ -n "$IN_NIX_SHELL" && -f "$HOME/.zshrc" && -z "$__HM_ZSHRC_SOURCED" ]]; then
        export __HM_ZSHRC_SOURCED=1
        source "$HOME/.zshrc"
      fi
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

      export CLICOLOR=1
      export LSCOLORS=GxFxCxDxBxegedabagaced

      if command ls --color=auto -d . >/dev/null 2>&1; then
        alias ls='ls --color=auto'
        alias ll='ls -lh --color=auto'
        alias la='ls -lah --color=auto'
      else
        alias ls='ls -G'
        alias ll='ls -lG'
        alias la='ls -laG'
      fi
    '';
  };
}
