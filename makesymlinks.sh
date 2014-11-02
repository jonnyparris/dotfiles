#!/bin/bash
############################
# .make.sh
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
# Make this file executable by running this command (without the carrots) >>> chmod +x makesymlinks.sh
############################

########## Variables

dir=~/dotfiles/jonnyparris/dotfiles   # dotfiles directory - REPLACE WITH YOUR DESIRED FOLDER FOR THESE NEW DOTFILES
olddir=~/dotfiles_backup                 # old dotfiles backup directory
files="bashrc bash_aliases bash_profile gitignore_global"    # list of files/folders to symlink in homedir TODO: Populate this list automatically

##########

# create dotfiles_backup in homedir
echo -n "Creating $olddir for backup of any existing dotfiles in ~ ..."
mkdir -p $olddir
echo "done"

# change to the dotfiles directory
echo -n "Changing to the $dir directory ..."
cd $dir
echo "done"

# move any existing dotfiles in homedir to dotfiles_backup directory, then create symlinks from the homedir to any files in the ~/dotfiles directory specified in $files
for file in $files; do
    echo "Moving any existing dotfiles from ~ to $olddir"
    mv ~/.$file ~/dotfiles_backup/
    echo "Creating symlink to $file in home directory."
    ln -s $dir/$file ~/.$file
done

echo "Applying new bash profile settings, without restarting..."
source ~/.bash_profile;
source ~/.bashrc;
