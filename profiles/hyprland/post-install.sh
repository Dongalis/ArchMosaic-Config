systemctl --user enable --now hyprpolkitagent.service
elephant service enable
systemctl --user enable --now waybar.service
sed "s/#\(HandlePowerKey=\)poweroff/\1ignore/g" /etc/systemd/logind.conf | sudo tee /etc/systemd/logind.conf >/dev/null
