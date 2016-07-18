class Readfile

  def read_file(filename)
    puts "reading file #{filename}..."

    File.read(filename) do |content|
      puts content
    end
  end

end

readfile = Readfile.new
readfile.read_file "/home/dev/Dropbox/rubycode/variable.rb"
