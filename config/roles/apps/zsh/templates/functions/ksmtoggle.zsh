ksmtoggle() {
  # Check status
  if [ "$(cat /sys/kernel/mm/ksm/run)" = "0" ]; then
    echo "1" | sudo tee /sys/kernel/mm/ksm/run > /dev/null
    printf 'KSM enabled\n'
  else
    echo "0" | sudo tee /sys/kernel/mm/ksm/run > /dev/null
    printf 'KSM disabled\n'
  fi
}
