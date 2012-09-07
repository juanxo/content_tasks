require 'find'
require 'colored'
require 'win32console'

base_dir = ARGV[0]

puts "Finding png files in #{base_dir}"

def is_animated(path)

  file = File.open(path, 'rb')
  data = file.readlines.join

  count = 0
  str_loc = 0
  while count < 2
    graphic_control_block = data.index(/\x00\x21\xF9\x04/, str_loc)
    if graphic_control_block
      str_loc += 1
      #image block should be right after the graphic control block
      image_block = data.index(/\x00\x2C/, str_loc)
      if image_block && graphic_control_block + 8 == image_block
        count += 1
      else
        break
      end
    else
      break
    end
  end
  file.close

  count > 1
end

ordered = true

messages = []

compression_comparator = ->(a,b){


  b[:bytes_saved] <=> a[:bytes_saved]

}

if File.exists?(base_dir) && File.directory?(base_dir)

  Find.find(base_dir) do |path|
    if path =~ /\A([\-\.\:\w\s\b\/\\]+(\/|\\){1})([\w\b]+)\.gif\z/

      relative_path = path.slice(base_dir.length..-1)

      if is_animated(path)
        #puts "Can't convert #{relative_path}. Is animated".red
      else
        gif_size = FileTest.size(path)
        system("echo #{path} >> #{base_dir}/unanimated_gifs.txt")

        png_path = "#{$1}#{$3}.png"
        png_tmp_path = "#{$1}#{$3}.png-new"
        system("D:/Projects/JSTools/convert.exe \"#{path}\" \"#{png_path}\"")
        system("pngcrush -rem alla -reduce -brute -e .png-new \"#{png_path}\" >NUL")
        File.delete(png_path)
        File.rename(png_tmp_path, png_path)

        png_size = FileTest.size(png_path)


        if png_size < gif_size
          compression_percentage = (1 - (png_size / gif_size.to_f)) * 100.0
          compression_percentage_string = "%.2f".green % compression_percentage
          if ordered
            message = "Converting #{relative_path.yellow}. "
            message += "It should change to png ( png size: #{png_size.to_s.green}, gif size: #{gif_size.to_s.red}, %compression: #{compression_percentage_string}"
            messages.push({message: message, compression: compression_percentage, bytes_saved: (gif_size - png_size)})
          else
            print "Converting #{relative_path.yellow}. "
            puts "It should change to png ( png size: #{png_size.to_s.green}, gif size: #{gif_size.to_s.red}, %compression: #{compression_percentage_string}"
          end

        else
          #puts "Converting #{relative_path}. Deleting png because it's bigger".yellow
          File.delete(png_path)
        end

      end


    end
  end



  sorted_messages = messages.sort( & compression_comparator)
  sorted_messages.each { |message| puts message[:message]}

else
  puts "Path not found or it isn't a directory"
end