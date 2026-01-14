if status is-interactive
    # Commands to run in interactive sessions can go here
end
set -gx EDITOR nvim 
set -gx VIRTUAL_ENV_DISABLE_PROMPT 1
set -gx GOPATH /home/mejxe/go/bin
set -gx JAVA_HOME /usr/lib/jvm/default
set -gx BROWSER /usr/bin/zen-browser

# Created by `pipx` on 2024-12-28 21:14:09
set PATH $PATH /home/mejxe/.local/bin
set PATH $PATH $HOME/.config/emacs/bin

function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end
