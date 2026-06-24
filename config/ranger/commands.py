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