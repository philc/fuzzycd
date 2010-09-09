#!/usr/bin/env ruby
# This takes a path argument and generates a list of possible completions using fuzzy matching. For example:
#   "p" matches "places/" and "suspects/"
#   "p/h" matches "places/home/" and "suspects/harry/"
# If there is more than one match, an interactive menu will be shown via STDOUT to select the intended match.
# This script is intended to be invoked from fuzzycd_bash_wrapper.sh, which collects the output of this script
# and forwards the chosen path to the original cd command.
# This script communicates with its parent fuzzycd_bash_wrapper.sh through the file "/tmp/fuzzycd.rb.out";
# this is required because this script uses STDOUT to show the interactive menu when necessary.

# Returns a string representing a color-coded menu which presents a series of options.
# This uses flexible width columns, because fixed-width columns turned out to not look good.
# Example output: 1.notes.git 2.projects.git
def menu_with_options(options)
  columns = `tput cols`.to_i
  output = []
  current_line = ""
  options.each_with_index do |option, i|
    option = option.sub(ENV["HOME"], "~")
    option_text = "#{i + 1}.#{colorize_blue(option)}"
    if current_line.size + (option.size + i.to_s.size) >= columns - 1
      output.push(current_line)
      current_line = option_text
    else
      current_line += (current_line.empty? ? "#{option_text}" : "   #{option_text}")
    end
  end
  output.push(current_line)
  output.join("\n") + " "
end

# Inserts bash color escape codes to render the given text in blue.
def colorize_blue(text)
  "\e[34m" + text + "\e[0m"
end

# Presents all of the given options in a menu and collects input over STDIN. Returns the chosen option,
# or nil if the user's input was invalid or they hit CTRL+C.
def present_menu_with_options(options)
  begin
    original_terminal_state = `stty -g`
    print menu_with_options(options)
    # Put the terminal in raw mode so we can capture one keypress at a time instead of waiting for enter.
    `stty raw -echo`
    input = STDIN.getc.chr

    ctrl_c = "\003"
    return nil if input == ctrl_c

    # We may require two characters with more than 10 choices. If the second character is "enter" (10),
    # ignore it.
    if options.length > 9
      char = STDIN.getc.chr
      input += char unless (char == 10)
    end

    # Require numeric input.
    return nil unless /^\d+$/ =~ input

    choice = input.to_i
    return nil unless (choice >= 1 && choice <= options.length)

    return options[choice - 1]
  ensure
    system `stty #{original_terminal_state}`
    print "\n"
  end
end

# Returns an array of all matches for a given path. Each part of the path is a globed (fuzzy) match.
# For example:
#   "p" matches "places/" and "suspects/"
#   "p/h" matches "places/home" and "suspects/harry"
def matches_for_path(path)
  # Build up a glob string for each component of the path to form something like: "*p*/*h*".
  # Avoid adding asterisks around each piece of HOME if the path starts with ~, like: /home/philc/*p*/*h*
  root = ""
  if (path.index(ENV["HOME"]) == 0)
    root = ENV["HOME"] + "/"
    path.sub!(root, "")
  else
    # Ignore the initial ../ if the path is rooted with ../, as well as a few other special cases that we
    # do not wish to include in the glob expression.
    special_roots = ["./", "../", "/"]
    special_roots.each do |special_root|
      next unless path.index(special_root) == 0
      root = special_root
      path.sub!(root, "")
      break
    end
  end

  glob_expression = "*" + path.gsub("/", "*/*") + "*"
  Dir.glob(root + glob_expression, File::FNM_CASEFOLD).select { |file| File.directory?(file) }
end


# Communicate with the shell wrapper using a temp file instead of STDOUT, since we want to be able to
# show our own interactive menu over STDOUT without confusing the shell wrapper with that output.
@out = File.open("/tmp/fuzzycd.rb.out", "w")
cd_path = ARGV.join(" ")

# Just invoke cd directly in certain special cases (e.g. when the path is empty, ends in "/" or exactly
# matches a directory).
if cd_path.nil? || [".", "/", "-", ENV["HOME"]].include?(cd_path) || cd_path =~ /^\.\.(\/\.\.)*$/ ||
    cd_path.rindex("/") == cd_path.size - 1 || File.directory?(cd_path)
  @out.puts "@passthrough"
  exit
end

matches = matches_for_path(cd_path)

if matches.size == 1
  @out.puts matches.first
elsif matches.size == 0
  @out.puts "@nomatches"
elsif matches.size >= 100
  puts "There are more than 100 matches; be more specific."
  @out.puts "@exit"
else
  choice = present_menu_with_options(matches)
  @out.puts(choice.nil? ? "@exit" : choice)
end