module Labs
  module_function

  HTML_DIR = 'git_tutorial/html'
  WORK_DIR = 'git_tutorial/work'

  class Lab
    attr_reader :name, :number, :lines
    attr_accessor :next, :prev

    def initialize(name, number)
      @name = name
      @number = number
      @lines = ""
    end

    def empty?
      @lines.empty?
    end

    def <<(line)
      @lines << line
    end

    def filename
      "lab_%02d.html" % number
    end

    def to_html
      new_html = RedCloth.new(lines).to_html
      new_lines = new_html.gsub('<p class="sample">', '<pre class="sample">')
    end
  end

  def make_sample_name(lab_number, word)
    SAMPLES_DIR + ("/%03d_%s.txt" % [lab_number, word])
  end

  def generate_labs(io)
    lab_index = -1
    step_index = 0
    labs = []
    mode = :direct
    gathered_line = ''
    io.each do |line|
      next if line =~ /^\s*-+\s*$/ # omit dividers
      next if line =~ /^[+][a-z]/  # omit hidden commands
      line.sub!(/^[-!]/,'')        # remove force and execute ignore chars
      case mode
      when :direct
        if line =~ /^h1.\s+(.+)$/
          step_index = 0
          lab_index += 1
          lab = Lab.new($1, lab_index+1)
          lab.prev = labs.last
          labs.last.next = lab if labs.last
          line.sub!(/h1\./, "h1(lab_title). _lab #{lab_index+1}_ ") # add lab number
          line.sub!(/:/, ":<br>")                                   # break long titles at the colon
          line.sub!(/\((?!lab_title)/, "<br>(")                     # break long titles at the last open paren
          lab.lines << line
          labs << lab
        elsif line =~ /^h2\./
          step_index += 1
          labs[lab_index] << line.sub(/h2\.\s+(.+)/, "h2. \\1")
        elsif line =~ /^pre*\(.*\)\.\s*$/
          mode = :gather1
          gathered_line = line.strip
        elsif line =~ /^p(\([(a-z){}]*)?\.\s+/
          mode = :gather
          gathered_line = line.strip
        elsif line =~ /^Execute:$/i
          mode = :gather1
          labs[lab_index] << "h3. **Execute:**\n\n"
          gathered_line = "pre(instructions)."
        elsif line =~ /^File:\s+(\S+)$/i
          file_name = $1
          labs[lab_index] << "h3(file-heading). _#{file_name}_\n\n"
          gathered_line = "<pre class=\"file\">"
          mode = :file
        elsif line =~ /^Code:$/i
          mode = :gather1
          labs[lab_index] << "h3. **Execute:**\n\n"
          gathered_line = "pre(instructions)."
        elsif line =~ /^Output:\s*$/
          labs[lab_index] << "h3. **Output:**\n\n"
          gathered_line = "<p class=\"sample\">\n"
          mode = :file
        elsif line =~ /^Set: +\w+=.*$/
          # Skip set lines
        elsif line =~ /^Freeze\s*$/
          # Skip freeze lines
        elsif line =~ /^=\w+/
          # Skip include lines
        else
          labs[lab_index] << line unless lab_index < 0
        end
      when :gather1
        labs[lab_index] << gathered_line << " " << line
        mode = :direct
      when :gather
        if line =~ /^\s*$/
          labs[lab_index] << gathered_line << "\n\n"
          mode = :direct
        else
          gathered_line << " " << line.strip
        end
      when :file
        if line =~ /^EOF$/
          labs[lab_index] << "</pre>\n"
          mode = :direct
        elsif line =~ /^=(\w+)/
          sample_name = make_sample_name(lab_index+1, $1)
          open(sample_name) do |ins|
            ins.each do |sample_line|
              puts sample_line
              if sample_line.start_with?('$')
                command_line = "<div class=\"sample_command\">"
                sample_line.chop!
                close = "</div>\n"
                labs[lab_index] << "#{gathered_line}#{command_line}#{sample_line}#{close}"
                gathered_line = ''
              else
                labs[lab_index] << "#{gathered_line}#{sample_line}"
                gathered_line = ''
              end
            end
          end
        else
          labs[lab_index] << "#{gathered_line}#{line}"
          gathered_line = ''
        end
      end
    end
    write_index_html(labs)
    labs.each do |lab|
      write_lab_html(lab, labs)
    end
  end

  def nav_links(f, lab)
    partial("nav", binding)
  end

  def lab_index(f, labs)
    partial("lab_index", binding)
  end

  def partial(template, bnd)
    result = open("templates/#{template}.html.erb") do |tpl|
      template_string = tpl.read
      template_string.gsub!(/-%>/, "%>@NONEWLINE@")
      ERB.new(template_string).result(bnd)
    end
    result.gsub(/@NONEWLINE@\n/, '')
  end

  def write_index_html(labs)
    File.open("#{HTML_DIR}/index.html", "w") do |f|
      f.puts partial('index', binding)
    end
  end

  def write_lab_html(lab, labs)
    lab_html = lab.to_html
    File.open("#{HTML_DIR}/#{lab.filename}", "w") { |f|
      f.puts partial('lab', binding)
    }
  end
end

require 'rubygems'
require 'redcloth'
require 'rake/clean'

CLOBBER.include(Labs::HTML_DIR)
CLOBBER.include(Labs::WORK_DIR)

directory Labs::HTML_DIR
directory Labs::WORK_DIR

TO_HTML = "#{Labs::HTML_DIR}/%f"
EXTRA_SRCS = FileList['src/*.css', 'src/*.js', 'src/*.gif', 'src/*.jpg', 'src/*.png', 'src/*.eot', 'src/*.ttf', 'src/*.woff', 'diagrams/*.png', 'src/manifest.json', 'src/*.mp4']
EXTRA_OUT = EXTRA_SRCS.pathmap(TO_HTML)
INDEX_HTML = File.join(Labs::HTML_DIR, "index.html")

TEMPLATE_FILES = FileList['templates/*.erb']

task :extra => EXTRA_OUT

EXTRA_SRCS.each do |extra|
  file extra.pathmap(TO_HTML) => [Labs::HTML_DIR, extra] do |t|
    cp extra, t.name
  end
end

file INDEX_HTML => [Labs::HTML_DIR, Labs::WORK_DIR, "src/labs.txt", "rakelib/labs.rake", SAMPLE_TAG] + EXTRA_OUT + TEMPLATE_FILES do |t|
  puts "Generating HTML"
  File.open("src/labs.txt") { |f| Labs.generate_labs(f) }
end

desc "Create the Lab HTML"
task :labs => [INDEX_HTML]

desc "View the Labs"
task :view do
  sh "open #{Labs::HTML_DIR}/index.html"
end
