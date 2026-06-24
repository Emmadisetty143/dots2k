from ranger.api.commands import Command

class paste_as_root(Command):
	def execute(self):
		if self.fm.do_cut:
			self.fm.execute_console('shell sudo mv %c .')
		else:
			self.fm.execute_console('shell sudo cp -r %c .')

class fzf_select(Command):
    """
    :fzf_select

    Find a file using fzf.
    With a prefix argument select only directories.
    Uses fd and bat if available for speed and rich preview.
    """
    def execute(self):
        import subprocess
        import os.path
        import shutil

        # Check for modern command-line tools
        has_fd = shutil.which('fd') is not None
        has_bat = shutil.which('bat') is not None

        # Build search command
        if has_fd:
            if self.quantifier:
                search_cmd = "fd --type d --follow --exclude .git"
            else:
                search_cmd = "fd --follow --exclude .git"
        else:
            if self.quantifier:
                # match only directories
                search_cmd = "find -L . \\( -path '*/\\.*' -o -fstype 'dev' -o -fstype 'proc' \\) -prune -o -type d -print 2> /dev/null | sed 1d | cut -b3-"
            else:
                # match files and directories
                search_cmd = "find -L . \\( -path '*/\\.*' -o -fstype 'dev' -o -fstype 'proc' \\) -prune -o -print 2> /dev/null | sed 1d | cut -b3-"

        # Build fzf options
        fzf_options = ["+m", "--reverse"]
        if self.quantifier:
            fzf_options.append("--header='Jump to directory'")
        else:
            fzf_options.append("--header='Jump to file'")

        if has_bat:
            # Interactive preview pane (bat for files, ls for directories)
            fzf_options.append("--preview='bat --color=always --line-range :500 {} 2>/dev/null || ls -la {}'")

        command = f"{search_cmd} | fzf {' '.join(fzf_options)}"

        fzf = self.fm.execute_command(command, universal_newlines=True, stdout=subprocess.PIPE)
        stdout, stderr = fzf.communicate()
        if fzf.returncode == 0:
            fzf_file = os.path.abspath(stdout.rstrip('\n'))
            if os.path.isdir(fzf_file):
                self.fm.cd(fzf_file)
            else:
                self.fm.select_file(fzf_file)


class z(Command):
    """
    :z <query>

    Jump to a directory using zoxide.
    """
    def execute(self):
        import subprocess
        import os
        
        query = self.rest(1)
        if not query:
            return
        
        try:
            path = subprocess.check_output(
                ['zoxide', 'query', query],
                text=True,
                stderr=subprocess.DEVNULL
            ).strip()
            if os.path.isdir(path):
                self.fm.cd(path)
        except subprocess.CalledProcessError:
            self.fm.notify(f"No match found for: {query}", bad=True)


class zi(Command):
    """
    :zi <query>

    Interactive jump to a directory using zoxide and fzf.
    """
    def execute(self):
        import subprocess
        import os
        
        query = self.rest(1)
        
        if query:
            zoxide_cmd = f"zoxide query -l {query}"
        else:
            zoxide_cmd = "zoxide query -l"
            
        command = f"{zoxide_cmd} | fzf +m --reverse --header='Jump to directory'"
        
        fzf = self.fm.execute_command(command, universal_newlines=True, stdout=subprocess.PIPE)
        stdout, stderr = fzf.communicate()
        if fzf.returncode == 0:
            path = os.path.abspath(stdout.rstrip('\n'))
            if os.path.isdir(path):
                self.fm.cd(path)


class fzf_grep(Command):
    """
    :fzf_grep <query>

    Fuzzy search inside files using ripgrep and fzf.
    """
    def execute(self):
        import subprocess
        import os
        
        query = self.rest(1)
        if not query:
            self.fm.open_console("fzf_grep ")
            return
            
        command = f"rg --line-number --no-heading --color=always --smart-case {subprocess.list2cmdline([query])} | fzf --ansi --reverse --delimiter : --preview 'bat --color=always --style=numbers --highlight-line {{2}} --line-range :500 {{1}} 2>/dev/null || cat {{1}}'"
        
        fzf = self.fm.execute_command(command, universal_newlines=True, stdout=subprocess.PIPE)
        stdout, stderr = fzf.communicate()
        if fzf.returncode == 0:
            parts = stdout.strip().split(':')
            if len(parts) >= 2:
                filepath = os.path.abspath(parts[0])
                linenumber = parts[1]
                self.fm.select_file(filepath)
                self.fm.execute_console(f"shell $EDITOR +{linenumber} {filepath}")