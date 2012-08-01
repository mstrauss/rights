#!/usr/bin/env ruby
module Rights
  
  # this class provides the command-line interface
  class CLI
    
    def initialize( stdout, stderr )
      @stdout = stdout
      @stderr = stderr
      
      # both our output streams need to be a TTY to enable colorization
      @colorize = stderr.tty? && stdout.tty?
    end
    
    def colorize(text, color_code)
      if @colorize
        "\e[#{color_code}m#{text}\e[0m"
      else
        text
      end
    end
    
    def red(text); colorize(text, 31); end
    
    def banner
      red( "RIGHTS VERSION #{Rights::VERSION}. THIS PROGRAM COMES WITH NO WARRANTY WHATSOEVER. MAKE BACKUPS!") + $/ +
      "Usage: #{Pathname($0).basename} <path> [options]"
    end
    
    def show_usage
      @stdout.puts(@option_parser.help)
      exit
    end
    
    def execute( arguments=[] )
      
      # parse command line
      options = {}
      @option_parser = OptionParser.new do |opts|
        opts.on('-o', '--owner OWNER', 'sets the file owner') do |owner|
          options[:owner] = owner
        end
        opts.on('-g', '--group GROUP', 'sets the file group') do |group|
          options[:group] = group
        end
        opts.on('-m', '--mode MODE', 'sets the directory mode; file mode is calculated by applying mask') do |mode|
          options[:mode] = mode
        end
        opts.on(nil, '--mask MASK', 'sets the file mask, defaults to 666') do |mask|
          options[:mask] = mode
        end
        opts.on('-n', '--dry', 'run dry, just report what would happen') do
          options[:dry] = true
        end
        opts.on(nil, '--mindepth MIN', 'minimum depth level for find, defaults to 0') do |mindepth|
          options[:mindepth] = mindepth
        end
        opts.on(nil, '--maxdepth MAX', 'maximum depth level for find, defaults to infinity') do |maxdepth|
          options[:maxdepth] = maxdepth
        end
      end
      @option_parser.banner = self.banner
      
      begin
        @option_parser.parse!( arguments )
      rescue OptionParser::InvalidOption, OptionParser::MissingArgument => error
        @stderr.puts red error.message
        exit 3
      end
      
      show_usage if arguments.size != 1
      
      path = arguments.first
      
      begin
        status = Rights::Doer.new( path, options ).execute
        @stdout.puts status.message if status.message
        exit status.code
      rescue Rights::Error => error
        @stderr.puts red error.user_info
        exit 2
      end
    end
  end
end
