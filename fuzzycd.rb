#!/usr/bin/env ruby
# Returns a string representing a color-coded menu which presents each match as a choice.
# This uses flexible width columns, because fixed-width columns turn out to not look so good.
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

    # We may require two characters for lists with many choices. If the second character is "enter" (10),
    # ignore it.
    if options.length > 9
      char = STDIN.getc.chr
      input += char unless (char == 10)
    end

    # we require numeric input.
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
  # Build up a glob string for each component of the path to make something like: "*p*/*h*".
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
path = ARGV.join(" ")

# When no path is provided, just invoke 'cd' directly without arguments, which usually navigates to ~.
if path.nil?
  @out.puts "@passthrough"
  exit
end

# When the path ends in "/" and for other special-case paths, just let cd handle it directly.
if path == "." || path == ".." || path == "/" || path.rindex("/") == path.size - 1 || path == ENV["HOME"]
  @out.puts "@passthrough"
  exit
end

matches = matches_for_path(path)

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