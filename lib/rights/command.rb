module Rights
  
  class Command
    
    # @return[Array] of messages from last method call or nil
    attr_reader :messages
    
    # @return[Boolean] would we execute?
    def has_things_to_do?
      false
    end
    
    def execute
    end
    
    def self.option_parser( options = {} )
      parser = OptionParser.new do |opts|
        # global options existing here too
        opts.on('-n', '--dry', 'run dry, just report what would happen') do
          options[:dry] = true
        end
        # own options
        opts.on('-o', '--owner OWNER', 'sets the file owner') do |owner|
          options[:owner] = owner
        end
        opts.on('-g', '--group GROUP', 'sets the file group') do |group|
          options[:group] = group
        end
        opts.on('-m', '--mode MODE', 'sets the directory mode; file mode is calculated by applying mask') do |mode|
          options[:mode] = mode
        end
        opts.on('--mask MASK', 'sets the file mask, defaults to 666') do |mask|
          options[:mask] = mask
        end
        opts.on('--mindepth MIN', 'minimum depth level for find, defaults to 0') do |mindepth|
          options[:mindepth] = mindepth
        end
        opts.on('--maxdepth MAX', 'maximum depth level for find, defaults to infinity') do |maxdepth|
          options[:maxdepth] = maxdepth
        end
      end
      parser.banner = "Command syntax: <path> [options]
  At least one of owner, group or mode must be provided"
      parser
    end
    
    def self.help
      self.option_parser.help
    end
    
    # Parses commands in the form
    #   <path> <command for path> <parameters>
    # @return[Array[command, messages]]
    #   command: the command if parsing succeeded;  nil otherwise
    #   messages: array of messages
    def self.parse( cmd, options = {} )
      # we need to clone options in order not to modify callers' data
      options = options.clone
      
      cmd = cmd.split
      
      # parse command
      messages = []
      option_parser = self.option_parser( options )
      path = cmd.shift
      begin
        option_parser.parse!( cmd )
      rescue OptionParser::InvalidOption, OptionParser::MissingArgument => error
        messages << error.message
        return [nil, messages]
      end
      
      # validation
      if path.nil?
        messages << "Please specify a directory path."
      else
        messages << "Path '#{path}' does not exist or is not a directory." unless Pathname(path).directory?
      end
      messages << "Please specify at least one of owner, group and/or mode." unless options[:owner] || options[:group] || options[:mode]
      messages << "Mode must be octal." unless options[:mode].nil? or options[:mode].is_oct?
      messages << "Mask must be octal." unless options[:mask].nil? or options[:mask].is_oct?
      
      command = nil
      if messages.count == 0
        command = Rights::DoerCommand.new( path, options )
      end
      
      return [command, messages]
    end
    
  end
  
  
  class FindCommand < Command
    
    attr_reader :paths
    
    # where to find 'find'
    # FIXME: this needs to be dynamically resolved
    FIND = '/usr/bin/find'
    
    def initialize( path, mindepth = nil, maxdepth = nil)
      fail Error.new "Path must be a valid directory" unless Pathname(path).directory?
      @path = path
      mindepth ||= 0
      mindepth = "-mindepth #{mindepth}"
      maxdepth ||= ''
      maxdepth = "-maxdepth #{maxdepth}" unless maxdepth.empty?
      @mindepth = mindepth
      @maxdepth = maxdepth
      
      @find_cmd = "#{FIND} #{@path} #{@mindepth} #{@maxdepth}"
    end
    
    def has_things_to_do?
      execute.count > 0
    end
    
    # @return[Array] of paths
    def execute
      @cmd ||= @find_cmd
      pid, stdin, stdout, stderr = Open4::popen4(@cmd)
      _, status = Process::waitpid2(pid)
      fail Error.new(stderr) if status.exitstatus > 0
      @paths = stdout.readlines
    end
    
    def prepare_execute_with( text )
      @cmd = "#{@find_cmd} #{text}"
      self
    end
    
    def to_s
      @cmd.to_s
    end
    
  end
  
  
  class ChangeModeCommand < Command
    
    CHMOD = 'ruby -e \'File.chmod(ARGV[0].oct, ARGV[1])\''
    
    def initialize( findCommand, mode, type = nil )
      fail Error.new "Mode must be octal" unless mode.is_oct?
      fail Error.new "Type must be 'f' or 'd' or nil" unless type.nil? or type == 'd' or type == 'f'
      @findCommand = findCommand
      @mode = mode
      @type = type
    end
    
    def has_things_to_do?
      status = @findCommand.prepare_execute_with( "-type #{@type} ! -perm #{@mode}" ).has_things_to_do?
      @messages = ["#{@findCommand}: #{@findCommand.paths.count} paths have wrong mode."] if status
      status
    end
    
    def execute
      @findCommand.prepare_execute_with( "-type #{@type} -exec #{CHMOD} #{@mode} '{}' \\;" ).execute
    end
  end
  
  
  class ChangeOwnerCommand < Command
    
    CHOWN = "#{`which chown`.strip}"
    # CHOWN = '/bin/chown -c'
    
    def initialize( findCommand, owner )
      @findCommand = findCommand
      @owner = owner
    end
    
    def has_things_to_do?
      status = @findCommand.prepare_execute_with( "! -user #{@owner}" ).has_things_to_do?
      @messages = ["#{@findCommand}: #{@findCommand.paths.count} paths have wrong owner."] if status
      status
    end
    
    def execute
      @findCommand.prepare_execute_with( "-exec #{CHOWN} #{@owner} '{}' \\;" ).execute
    end
  end
  
  
  class ChangeGroupCommand < Command
    
    CHOWN = "#{`which chown`.strip}"
    
    def initialize( findCommand, group )
      @findCommand = findCommand
      @group = group
    end
    
    def has_things_to_do?
      status = @findCommand.prepare_execute_with( "! -group #{@group}" ).has_things_to_do?
      @messages = ["#{@findCommand}: #{@findCommand.paths.count} paths have wrong group."] if status
      status
    end
    
    def execute
      @findCommand.prepare_execute_with( "-exec #{CHOWN} :#{@group} '{}' \\;" ).execute
    end
  end
  
end
