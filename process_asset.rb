require 'platform'
require 'find'
require 'colored'
require 'optparse'
require 'yuicompressor'
require 'uglifier'

require 'win32console' if PLATFORM_IS_WINDOWS


options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: process_asset.rb [options] file1 file2..."
  options[:root_dir] = '.'
  opts.on('-d', '--dir DIR', 'Specify root dir. Defaults to current dir') do |dir|
    puts dir
    options[:root_dir] = (dir =~ /(\\|\/)$/) ? dir : dir << "/"
  end
  options[:out] = ''
  opts.on('-o', '--out OUT', 'Specify output file or directory. Also you can specify a transformation with "regex::dest"') do |out|
    options[:out] = out
  end


  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end

end

optparse.parse!


def compress_from_file(filepath, output_file)
  file_content = File.read(filepath)


  if output_file.path =~ /\.css$/
    compressed_css = YUICompressor.compress_css(file_content, line_break: 32 * 1024)
    output_file.puts(compressed_css)
  elsif output_file.path =~ /\.js$/
    compressed_js = YUICompressor.compress_js(file_content)
    output_file.puts(compressed_js)
  end

end

ARGV.each do |filePath|
  print "Processing #{filePath}. "

  matches = /(?<parent_dir>.+(\\|\/))(?<filename>[\w\.]+)/.match("#{options[:root_dir]}#{filePath}")
  parent_dir = matches[:parent_dir]

  dest = filePath

  if options[:out] =~ /.+\:\:.+/
    transformation = options[:out].split('::')
    regex = transformation[0]

    dest = transformation[1]

    matches = /#{regex}/.match(filePath)

    index = 1
    while dest["$#{index}"]
      dest["$#{index}"] = matches[index]
      index +=  1
    end
  end

  output_file = File.open("#{options[:root_dir]}#{dest}", "w")

  file = File.open("#{options[:root_dir]}#{filePath}", "r")
  if (content = file.gets(nil)) =~ /\/\/\=\s*/ #needs processing
    puts "This file NEEDS processing"

    lines = content.split(/\r?\n/)
    lines.each do |line|
      puts line
      tokens = line["//=".length..-1].split(' ')
      command = tokens[0]
      params = tokens[1..-1]
      case command
        when 'require'
          source_path = params[0]
          puts "#{parent_dir}#{source_path}"

          output_file.puts("/****** Start of file #{parent_dir}#{source_path} ********/")
          compress_from_file("#{parent_dir}#{source_path}", output_file)
          output_file.puts("/****** End of file #{parent_dir}#{source_path} ********/")

        else
          puts "Command #{command} not recognized"
          exit()
      end

    end
  else
    puts "This file DOESN'T NEED processing. Minifying"
    compress_from_file("#{options[:root_dir]}#{filePath}", output_file)
  end

  output_file.close()

end


