#!/bin/bash

function get_listen_sockets() {
  sudo ss -ntlp | grep -v grep
}

if [[ -n $(get_listen_sockets) ]]; then
  get_listen_sockets | awk '{print $4}' | awk -F':' '{print $2}' | jq -s '.'
fi
