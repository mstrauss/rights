module Chownr
  
  class Command
    
    # @return[Boolean] would we execute?
    def has_things_to_do?
      false
    end
    
    def execute
    end
    
  end
  
  
  class FindCommand < Command
    
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
    
    def execute
      @cmd ||= @find_cmd
      pid, stdin, stdout, stderr = Open4::popen4(@cmd)
      _, status = Process::waitpid2(pid)
      fail Error.new(stderr) if status.exitstatus > 0
      return stdout.readlines
    end
    
    def prepare_execute_with( text )
      @cmd = "#{@find_cmd} #{text}"
      self
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
      @findCommand.prepare_execute_with( "-type #{@type} ! -perm #{@mode}" ).has_things_to_do?
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
      @findCommand.prepare_execute_with( "! -user #{@owner}" ).has_things_to_do?
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
      @findCommand.prepare_execute_with( "! -group #{@group}" ).has_things_to_do?
    end
    
    def execute
      @findCommand.prepare_execute_with( "-exec #{CHOWN} :#{@group} '{}' \\;" ).execute
    end
  end
  
end
