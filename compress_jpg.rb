require 'find'
require 'colored'
require 'win32console'

base_dir = ARGV[0]

puts "Finding jpg files in #{base_dir}"

if File.exists?(base_dir) && File.directory?(base_dir)

  kb_saved = 0

  Find.find(base_dir) do |path|
    if path =~ /\A([\-\.\:\w\s\b\/\\]+(\/|\\){1})([\w\b]+)\.jpg\z/

      relative_path = path.slice(base_dir.length..-1)
      print "Compressing #{relative_path.yellow}"
      original_size = FileTest.size(path)

      file_name = $3
      dir_path = $1
      new_path = "#{dir_path}#{file_name}.jpg"

      compressed = system("jpegtran -copy none -optimize -perfect -outfile #{new_path} #{path}")

      if compressed
        new_size = FileTest.size(new_path)
        compress_percentage = (1 - (new_size / original_size.to_f)) * 100.0
        puts " ( original_size: #{original_size.to_s.red}, new_size: #{new_size.to_s.green}, %compressed: #{("%.2f" % compress_percentage).green.bold}%)"
        kb_saved += original_size - new_size
      else
        puts "Error: #{$?}"
      end
    end
  end

  puts "Saved #{kb_saved / 1000.0} KB"

else
  puts "Path not found or it isn't a directory"
end