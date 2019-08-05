ksmstatus() {
  # Check status
  if [ "$(cat /sys/kernel/mm/ksm/run)" = "0" ]; then
    printf 'KSM off\n'
    return
  fi
  # Display stats
  for stat in /sys/kernel/mm/ksm/*
  do
    printf '%s: %s\n' "$(basename $stat)" "$(cat $stat)"
  done
  # Display savings
  PAGESIZE="$(getconf PAGESIZE)"
  printf 'Sharing %s MB\n' "$(( ($(cat /sys/kernel/mm/ksm/pages_sharing) * PAGESIZE) / 1024 / 1024 ))"
}
