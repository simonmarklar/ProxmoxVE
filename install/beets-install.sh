#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: [YourUserName]
# License: MIT
# Source: [SOURCE_URL]

# Import Functions und Setup
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Installing Dependencies with the 3 core dependencies (curl;sudo;mc)
msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  python3-venv \
  pipx
msg_ok "Installed Dependencies"

LOCAL_IP="$(hostname -I | awk '{print $1}')"
msg_info "Setting up dependencies"
sudo pipx ensurepath --global



# Create beets user
# msg_info "Creating beets user"
# $STD useradd -m beets
# $STD echo beets | passwd beets 
# msg_ok "Created beets user"

# Setup App
msg_info "Setup ${APPLICATION}"

RELEASE=$(curl -s https://api.github.com/repos/beetbox/beets/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
PIPX_GLOBAL_BIN_DIR="/opt/beets" pipx install --global beets
CONFIG_PATH=$(beet config -p)
msg_info "Creating beets config at $CONFIG_PATH"

cat <<EOF >"$CONFIG_PATH"
directory: /mnt/music/library
library: ./beets-library.db
import:
   quiet: no
   move: yes
   write: yes
   log: /var/log/beets.log
   autotag: yes
paths:
   # year/label or artist/album/track? - album? - artist - title.wav
   default: %if{\$year,\$year,unknown}/%if{\$label,%title{\$label},%title{%the{\$artist}}}/%if{\$album,\$album,unknown albums}/%if{\$track,- \$track} %if{\$album, - \$album -} %title{%the{\$artist}} - %title{\$title}
   singleton: %if{\$year,\$year,unknown}/%if{\$label,%title{\$label},%title{%the{\$artist}}}/%title{%the{\$artist}} - %title{\$title}
   comp: %if{\$year,\$year,unknown}/%if{\$label,%title{\$label},no label}/VA - %if{\$album,\$album,%aunique{}}/%if{\$track,- \$track} %if{\$album, - \$album -} %title{%the{\$artist}} - %title{\$title}
replace:
    '[\\/]': ''
    '^\.': ''
    '[\x00-\x1f]': ''
    '[<>:"\?\*\|]': ''
    '\.$': ''
    '\s+$': ''
    '^\s+': ''
    '^-': ''
ui:
   color: yes
plugins:
   - fish
   - badfiles
   - bandcamp
   - missing
   - info
   - fetchart
   - embedart
   - importadded
   - the
   - web
   - fromfilename
   - export
   - bareasc
   - fuzzy
   - duplicates

bandcamp:
   source_weight: 0.9
   include_digital_only_tracks: true
   search_max: 5
   art: yes
   comments_separator: "\n---\n"
   exclude_extra_fields:
      - genre
   genre:
      capitalize: no
      maximum: 0 # no maximum
      mode: classical

badfiles:
   check_on_import: no

fetchart: 
   sources:
      - filesystem
      - coverart

web:
   host: ${LOCAL_IP}
   cors: http://${LOCAL_IP}/
   include_paths: yes
   readonly: no

export:
    default_format: json
    json:
        formatting:
            ensure_ascii: no
            indent: 4
            separators: &id001 [',', ': ']
            sort_keys: yes
    csv:
        formatting:
            delimiter: ','
            dialect: excel
    xml:
        formatting: {}

EOF
msg_ok "Created beets config at $CONFIG_PATH"
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Setup ${APPLICATION}"

# Creating Service (if needed)
# msg_info "Creating Service"
# cat <<EOF >/etc/systemd/system/${APPLICATION}.service
# [Unit]
# Description=${APPLICATION} Service
# After=network.target

# [Service]
# ExecStart=[START_COMMAND]
# Restart=always

# [Install]
# WantedBy=multi-user.target
# EOF
# systemctl enable -q --now ${APPLICATION}.service
# msg_ok "Created Service"

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize
