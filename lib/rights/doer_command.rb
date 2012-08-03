module Rights
  
  # this one represents a command-line command
  class DoerCommand < Command
    
    ### need to use ruby for chmod because unix-command does not remove sticky bits numerically ###
    ###chmod = '/bin/chmod -c' <- does not work always
    CHOWN = '/bin/chown -c'
    
    
    def initialize( path, options )
      fail Error.new "Please specify a valid directory path." unless Pathname(path).directory?
      fail Error.new "Please specify at least one of owner, group and/or mode." unless options[:owner] || options[:group] || options[:mode]
      fail Error.new "Mode must be octal." unless options[:mode].nil? or options[:mode].is_oct?
      
      @path = path
      
      # we provide some default options
      @options = {}
      @options[:mask]     = "666"      # this mask is NOT from hell
      @options.merge!( options )
      
      # parameter mangling
      @options[:fmode] = "%o" % [@options[:mode].oct & @options[:mask].oct] if @options[:mode]
    end
    
    # @return [OpenStruct] with :code and :message
    def execute
      
      findCommand = FindCommand.new( @path, @options[:mindepth], @options[:maxdepth] )
      
      commands = []
      if @options[:mode]
        commands << ChangeModeCommand.new( findCommand, @options[:mode], 'd' )
        commands << ChangeModeCommand.new( findCommand, @options[:fmode], 'f' )
      end
      commands << ChangeOwnerCommand.new( findCommand, @options[:owner] ) if @options[:owner]
      commands << ChangeGroupCommand.new( findCommand, @options[:group] ) if @options[:group]
      
      if @options[:dry] then
        messages = []
        if commands.any? { |cmd| status = cmd.has_things_to_do?; messages << cmd.messages if status; status }
          code = 0
        else
          messages << "Nothing to do."
          code = 1
        end
        return OpenStruct.new( :code => code, :messages => messages )
      else
        commands.each { |cmd| cmd.execute }
        return OpenStruct.new( :code => 0 )
      end
    end
    
  end
  
end
