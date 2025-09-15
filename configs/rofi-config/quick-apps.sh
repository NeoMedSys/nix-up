#!/usr/bin/env zsh

# Quick Apps menu for waybar dropdown

if [ -z "$1" ]; then
    # Show the menu options
    echo " LibreWolf"
    echo " Slack" 
    echo " File Manager"
    echo " Steam"
    echo " Stremio"
    echo " Spotify"
    echo " Terminal"
    echo " VS Codium"
    echo " Signal"
else
    # Execute the selected option
    case "$1" in
        " LibreWolf")
            librewolf &
            ;;
        " Slack")
            slack &
            ;;
        " File Manager")
            nemo &
            ;;
        " Steam")
            steam &
            ;;
        " Stremio")
            stremio &
            ;;
        " Spotify")
            spotify &
            ;;
        " Terminal")
            alacritty &
            ;;
        " VS Codium")
            vscodium &
            ;;
        " Signal")
            signal-desktop &
            ;;
    esac
fi
