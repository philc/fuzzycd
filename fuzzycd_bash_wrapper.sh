# This displaces the normal bash "cd" builtin command. cd needs to be redefined this way because it's not
# a normal binary, but rather a Bash builtin.

# The "cd" command may have already been redefined by another script (RVM does this, for example):
if [ x`type -t cd` == "xfunction" ]; then
  # In this case, we define a new "original_cd" function with the same body as the previously defined "cd"
  # function.
  eval $(type cd | grep -v 'cd is a function' | sed 's/^cd/original_cd/' | sed 's/^}/;}/' )
else
  # Otherwise, we just define "__cd" to directly call the builtin.
  eval "original_cd() { builtin cd \$*; }"
fi

cd() {
  # This assumes that fuzzycd.rb is available somewhere in your PATH.
  fuzzycd.rb $*
  # fuzzycd.rb communicates to this bash wrapper through a temp file, because it uses STDOUT for other purposes.
  output=`cat /tmp/fuzzycd.rb.out`
  `rm /tmp/fuzzycd.rb.out`
  if [ "$output" = "@nomatches" ]; then
    echo "No files match \"$*\""
  elif [ "$output" = "@passthrough" ]; then
    original_cd "$*"
  elif [ "$output" != "@exit" ]; then
    original_cd "$output"
  fi
}
