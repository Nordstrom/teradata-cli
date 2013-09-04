require 'yaml'

# Encapsulates configuration settings for tdsql
class Configuration
	def initialize(*args)
		@config_settings = {}
		# if config_files.nil?
		# 	config_files = [
		# 		"#{File.expand_path File.dirname(__FILE__)}/../tdsql.conf", 
		# 		"~/tdsql.conf", 
		# 		command_args[:conf]
		# 	]
		# end
		# raise config_files.inspect

		args.each do |arg|
			if arg.nil?
				continue
			elsif arg.class == Hash
				merge_hashes @config_settings, arg
			elsif arg.class == String and File.exist?(arg)
				file_settings = YAML.load_file(arg)
				merge_hashes @config_settings, file_settings
	  	end
	  end
	end

	def get_active_host()
		host = nil
		host_keys = ['hostname', 'username', 'password']
		if host_keys.all? {|k| @config_settings.key?(k)}
			host = {}
			host_keys.each {|k| host[k] = @config_settings[k]}
			return host
		end

		hosts = @config_settings['hosts']
		if hosts.nil? or hosts.length == 0
			raise ConfigError, 'No hosts specified in configuration'
		end

		hostname = @config_settings['host']
		if not hostname.nil? 
			raise(ConfigError, "No host #{hostname} specified in configuration") unless hosts.key? hostname
				
			host = hosts[hostname]
		else
			hostname, host = hosts.first
		end

		# Clone the hash so we aren't modifying the underlying config data. Then 
		# tack the hostname on.
		host = host.clone()
		host['hostname'] = hostname

		# Validate that the host has all the required keys
		if not host_keys.all? {|k| host.key?(k)}
			raise ConfigError, "Host #{hostname} must have username and password specified"
		end

		host
	end

	def get_sql_cmd()
  	if @config_settings.nil?('file') not blank?(opts[:file])
    	raise "File #{opts[:file]} does not exist" unless File.exist?(opts[:file])
    end

    File.open(opts[:file], 'rb') do
      return file.read
    end
  elsif not blank?(opts[:command])
    opts[:command].strip().delete('"')
  else
    return nil
  end
end

	end

	def [](key)
    @config_settings[key]
  end

  def inspect()
  	@config_settings.inspect
  end

  def keys()
  	@config_settings.keys()
  end

  private

	# Performs a recursive merge on nested Hashes
  def merge_hashes(hash1, hash2)
  	for key in hash2.keys()
  		if not hash1.has_key?(key)
  			hash1[key] = hash2[key]
  		elsif hash1[key].class == Hash and hash2[key].class == Hash
  			merge_hashes(hash1[key], hash2[key])
  		else
  			hash1[key] = hash2[key]
  		end
  	end
  end

  def blank?(value)
  	value.nil? || (value.class == String and value.empty?)
	end
end

class ConfigError < RuntimeError
end