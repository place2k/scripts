# Personal Scripts Repository
Shell scripts that I made and use on my PC for my day-to-day tasks and needs.  
You may take any (or all) of these scripts for your own personal use, if you want; tweak them as (and if) needed, to suit your needs or those of your local system.

## Repomap
```
main                                    The principal and default toolkit of scripts, which reside at /usr/local/scripts/ (a.k.a. `$SCRIPTS_DIR`).
├── adb                                 Android Debug Bridge helper tools to use with my phone.
│   ├── adb_is_phone_connected.sh       Check whether an Android phone is connected to the computer via ADB (either USB or Wi-Fi).
│   ├── adb_restore_settings.sh         Restore my phone's developer-mode settings that were tweaked with `adb shell settings`.
│   └── adb_sync_mtimes.sh              A complex (100+ lines) script that synchronizes the modification times of a local directory tree with a corresponding tree on the phone.
├── core                                The most important and most frequently used scripts.
│   ├── appdata-bkup                    Back up my Bitwarden vault and Todoist tasks.
│   ├── autostart.sh                    Startup apps script, run by Plasma at login. It is intended for those apps which do not close to tray automatically at startup.
│   ├── help                            Show the help text of any program, piped with less(1).
│   ├── help.sh -> help                 Symbolic link created to avoid conflict with Bash's `help` builtin.
│   ├── root-bkup                       System script that backs up the root directory entries (except for my $HOME, which is backed up by Vorta, among other excluded dirs).
│   ├── shalias.zsh                     Zsh aliases management script.
│   └── spt                             Scripts manager.
├── helpers                             Scripts used by other scripts to perform specific tasks for them.
│   ├── chkroot.sh                      Check whether the parent script (i.e. the caller) is running as root or as a regular user.
│   ├── die.sh                          Print an error message and exit with status 1 (failure). This helper is supposed to be called as `exec die.sh "MESSAGE"`.
│   ├── gui_running                     Check whether SDDM and Plasma are up yet.
│   ├── notify.sh                       Print a properly/prettily formatted GUI notification using notify-send.
│   ├── t2dbar                          "Talk to D-Bus as Root" (T2DBaR). Run a dbus application (such as kwallet-query, among others) from a privileged parent script.
│   ├── wait4conn.sh                    Check whether we have Internet access before running a command line; if we don't, wait and recheck until we do, then execute a command.
│   ├── with-xhd-run                    Mount the external HDD (using xhd.sh below) before running a command line which is expected to operate on it.
│   └── xhd.sh                          Privileged script that atomically mounts and unmounts the external HDD, as well as checks whether it is already mounted.
├── system                              Scripts that perform (often privileged) system-level operations; some of these are set in the SUDOERS file to require no password when run.
│   ├── efiboot-create.sh               (Re)create my EFI boot partitions.
│   ├── etcbkp                          Save a just-edited file from /etc to /qb/etc (the Quick Backups directory for /etc content).
│   ├── sddm-logout                     Wrapper around the systemctl command to restart SDDM.
│   ├── sysctl-defaults                 Manager for my sysctl custom settings in the files under /etc/sysctl.d (as well as for the default settings under /etc/sysctl-defaults.d).
│   └── update                          System scripts for updating parts of the system or it as a whole.
│       ├── sysupgrade                  Convenience script that upgrades the system, providing many features of a complete system-upgrade tool, as well as cooperation with root-bkup.
│       ├── update-package-list         Update if needed the two lists (standard + AUR) of packages currently installed in the system, which can be used for system restoration.
│       └── update-ventoy.sh            Upgrade the Ventoy installation (and custom-installed EFI files) in my USB drive, following a system upgrade of Ventoy.
├── tools                               Specialized scripts that do one specific thing very well.
│   ├── arcdirs                         "Archive Directories" (referring to .local, .config, and browser profiles). A complete system for backing specific directories up elsewhere.
│   ├── clear-aur-build                 Clear the makepkg build directory and (optionally) the pacman cache.
│   ├── find-dupl.sh                    Find and print duplicate files in the current-directory tree, by computing their hashes and displaying only unique values.
│   ├── jargonfile.sh                   A small webserver that serves pages from my local copy of the Jargon File.
│   ├── jfserv                          A Python rewrite of the above.
│   ├── pendrive-backup.sh              Back up one of my mother's pendrives to the cloud-autosynced pendrives backup directory in the secondary SSD.
│   ├── pendrive-toggle.sh              "Enable" (append `.mp3`), "disable" (remove `.mp3`), or "toggle" the song files in an artist directory within one of Mother's pendrives.
│   ├── plasma-applets-bkup             Back up ~/.config/plasma-org.kde.plasma.desktop-appletsrc to the Quick Backups subpath `configuration/plasma`.
│   ├── prune-vim-view.sh               Remove ~/.vim/view files that do not correspond to existing files anymore (their sources have been deleted since last edit).
│   ├── termcolors                      Print all 256 colors available in the current terminal, to see how they look like in the color scheme in use.
│   └── view_output.sh                  Run a command with the default terminal emulator to see the command's output while in GUI mode; intended to be run from KRunner or suchlike.
└── wrappers                            Scripts that run system applications in a specific way or in an easier/more convenient way.
    ├── borg.sh                         Run the commonest operations of the Borg Backup tool, with special features (like archive search) plus one-letter commands for faster typing.
    ├── lsd.sh                          Run lsd(1) with the same preset flags as the ones I use in my aliases.
    ├── mangui                          View a manual page in the terminal emulator; intended to be run from KRunner or suchlike.
    ├── rsync.sh                        Run rsync(1) with the same preset flags as the ones I use in my aliases.
    ├── spotify.sh                      Start Spotify with the initial page set to a specific playlist (Liked Songs by default).
    ├── svim                            Run vim(1) as root to edit a system file, with the vimrc file set to the one under /root/ to avoid conflicts with any vimrc files in the CWD.
    ├── ttyvim                          Run vim(1) with the vimrc file set to ~/.vimrc.tty, for use in TTYs rather than graphical sessions.
    └── yt-dlp.sh                       Use yt-dlp to download into a given directory (CWD by default) a YouTube video as either MP3 or M4A.

misc                                    Miscellaneous scripts used for secondary or trivial purposes.
├── dezenas-mais-sorteadas.py           "Oftenest-drawn lottery numbers": something I hacked up for my father, who is an avid lottery player. Retrieves data from a lottery API.
├── loterias                            Data directory for the above Python script.
│   ├── atualizar                       "Update": a Bash script that retrieves up-to-data lottery numbers and saves them to each respective file.
│   ├── lotofacil                       Datafile for the Lotofácil Brazilian lottery.
│   ├── lotomania                       Datafile for Lotomania.
│   └── megasena                        Datafile for Mega Sena.
├── makepdf.sh                          Create OCR-enabled PDF(s) from the screenshots of a given recent AI roleplaying chat(s) that I had on Emochi.
├── me.sh                               Name and properly organize recently taken kinky photographs of me, preparing them to be saved to the privately encrypted archive me.7z.
├── wiktpos                             Home of the wiktpos.py script and its data files (which were excluded from this Git repository for privacy and security purposes).
│   └── wiktpos.py                      "Wiktionary Part of Speech": use the Wikimedia API to retrieve and fix my improper uses of the pos= parameter, replacing them with ng=.
├── youtube-brave-groups.bookmarks      Datafile for ytdurations.py, containing YouTube video IDs per browser group/bookmark-folder that contained the video tabs.
└── ytdurations.py                      Calculate the individual and the total durations for the bookmarked videos above, so that I know how long it will take to watch each and all.

12 directories, 59 files
```