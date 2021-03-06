# encoding: UTF8

require_relative 'platform'
require 'find'
require 'colored'

require 'win32console' if ContentTasks::PLATFORM_IS_WINDOWS

base_dir = ARGV[0]

puts "Finding png files in #{base_dir}"

if File.exists?(base_dir) && File.directory?(base_dir)

  kb_saved = 0

  Find.find(base_dir) do |path|
    if path =~ /\A([\-\.\:\w\s\b\/\\]+(\/|\\))([\.\-\w\b]+)\.png\z/
      relative_path = path.slice(base_dir.length..-1)
      print "Compressing #{relative_path.yellow}"
      original_size = FileTest.size(path)

      file_name = $3
      dir_path = $1
      new_path = "#{dir_path}#{file_name}.png-new"

      compressed = system("pngcrush -q -rem alla -brute -e .png-new \"#{path}\"")


      if compressed

        new_size = FileTest.size(new_path)
        compress_percentage = (1 - (new_size / original_size.to_f)) * 100.0
        print " ( original_size: #{original_size.to_s.red}, new_size: #{new_size.to_s.green}, %compressed: #{("%.2f" % compress_percentage).green.bold}%)"
        if original_size > new_size
          kb_saved += original_size - new_size

          deleted = File.delete(path) == 1
          if deleted
            File.rename(new_path, path)
            puts "\u2713".green
          end
        else
          puts "\u2715".red
        end
      else
        puts "#{$?}".red
      end

    end
  end

  kb_saved /= 1000.0
  puts "Saved %.2f KB" % kb_saved

else
  puts "Path not found or it isn't a directory"
end
