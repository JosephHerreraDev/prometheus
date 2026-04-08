#!/bin/bash

ansi_art=$(cat <<'EOF'
                                        __    __                    
                                       /\ \__/\ \                               
 _____   _ __   ___     ___ ___      __\ \ ,_\ \ \___      __   __  __    ____  
/\ '__`\/\`'__\/ __`\ /' __` __`\  /'__`\ \ \/\ \  _ `\  /'__`\/\ \/\ \  /',__\ 
\ \ \L\ \ \ \//\ \L\ \/\ \/\ \/\ \/\  __/\ \ \_\ \ \ \ \/\  __/\ \ \_\ \/\__, `\
 \ \ ,__/\ \_\\ \____/\ \_\ \_\ \_\ \____\\ \__\\ \_\ \_\ \____\\ \____/\/\____/
  \ \ \/  \/_/ \/___/  \/_/\/_/\/_/\/____/ \/__/ \/_/\/_/\/____/ \/___/  \/___/ 
   \ \_\                                                                        
    \/_/                                                                        
EOF
)

clear
echo -e "\n$ansi_art\n"

#rm -rf ~/.local/share/prometheus/
#git clone "https://github.com/${OMARCHY_REPO}.git" ~/.local/share/prometheus >/dev/null

cd ~/.local/share/prometheus
git fetch
cd -

echo -e "\nInstallation starting..."
source ~/.local/share/prometheus/install.sh