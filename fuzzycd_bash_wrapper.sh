# This displaces the normal bash "cd" builtin command. cd needs to be redefined this way because it's not
# a normal binary, but rather a Bash builtin.
cd() {
  # This assumes that fuzzycd.rb is available somewhere in your PATH.
  fuzzycd.rb $*
  # fuzzycd.rb communicates to this bash wrapper through a temp file, because it uses STDOUT for other purposes.
  output=`cat /tmp/fuzzycd.rb.out`
  `rm /tmp/fuzzycd.rb.out`
  if [ "$output" = "@nomatches" ]; then
    echo "No files match \"$*\""
  elif [ "$output" = "@passthrough" ]; then
    builtin cd "$*"
  elif [ "$output" != "@exit" ]; then
    builtin cd "$output"
  fi
}
