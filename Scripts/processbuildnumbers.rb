#!/usr/bin/ruby

if (!File.exists?(".git"))
    print "This project is not versioned"
    exit
end

inputCount = ENV["SCRIPT_INPUT_FILE_COUNT"].to_i
outputCount = ENV["SCRIPT_OUTPUT_FILE_COUNT"].to_i

if (inputCount != outputCount) 
    print "Need the same number of input and output files"
end

files = []
for i in 0..(inputCount-1)
    files << {"input" => ENV["SCRIPT_INPUT_FILE_#{i}"], "output" => ENV["SCRIPT_OUTPUT_FILE_#{i}"]}
end

gitlocation = %x[which git].strip

#get the revision count
revno = %x[\"#{gitlocation}\" rev-list HEAD | wc -l]
revno = revno.strip

#Get the 
commit = %x[\"#{gitlocation}\" show --abbrev-commit | grep "^commit"]
commitString = /commit (.*)/.match(commit)[1]

files.each do |path|
    output = ""
    File.open(path["input"], "r") do |file|
        file.each_line do |line|
            if line =~ /__BUNDLE_VERSION__/
                output += line.gsub(/__BUNDLE_VERSION__/, "#{revno}")
				elsif line =~ /__COMMIT_HASH__/
                output += line.gsub(/__COMMIT_HASH__/, "#{commitString}")
				else
                output += line
            end
        end
    end
	
    if (output.length)
        File.open(path["output"], "w") do |file|
            file.puts(output)
        end
    end
end