require "#{File.expand_path File.dirname(__FILE__)}/terajdbc4.jar"
require 'jdbc/teradata'
require 'trollop'
require 'yaml'
java_import java.sql.Types

Jdbc::Teradata::load_driver

@opts = Trollop::options do
  opt :host, "Teradata host name", :type => String
  opt :username, "Teradata username", :type => String
  opt :password, "Teradata password", :type => String
  opt :command, "Teradata SQL command", :type => String
  opt :delimiter, "Column delimiter", :type => String, :default => "\t"
  opt :quotechar, "The quote character", :type => String, :default => '"'
  opt :file, "Teradata sql file", :type => String
  opt :output, "File to write the output to", :type => String
  opt :timeout, "Command timeout in seconds", :type => Integer, :default => 30
  opt :header, "Print column headers in output", :default => false
  opt :creds, "Credentials file file path", :type => String
end

def main()
  # print @opts.inspect
  teradata_connection = create_connection(@opts)  
  sql_statement = teradata_connection.create_statement
  sql_statement.setQueryTimeout(@opts[:timeout])
  sql_cmd = get_sql_command(@opts)
  
  # Execute the Teradata command
  begin
    recordset = sql_statement.execute_query(sql_cmd)
    
    if @opts[:output] 
      File.open(@opts[:output], 'w') do |file|
        stream_query_results(recordset, file, @opts)
      end
    else
      stream_query_results(recordset, $stdout, @opts)
    end
  rescue Exception => e
    raise e
  ensure
    # Ensure the connection gets closed
    teradata_connection.close
  end
end

def create_connection(opts)
  if opts[:creds] 
    raise "Credentials file #{opts[:creds]} does not exist" unless File.exist?(opts[:creds])

    creds_hash = YAML.load_file(opts[:creds])
    host, username, password = creds_hash["host"], creds_hash["username"], creds_hash["password"]
  else
    host, username, password = opts[:host], opts[:username], opts[:password]   
  end

  if blank?(host) or blank?(username) or blank?(password)
    raise "Missing DB host, username, or password"
  end

  java.sql.DriverManager.get_connection(
    "jdbc:teradata://#{host}/", username, password)
end

def format_inline_sql_cmd(cmd)
  lines = cmd.split("\n")
  # Strip off leading and trailing whitespace on each line then join back up with spaces
  lines.map! {|l| l.strip().delete('"') }
  lines.join(' ')
end 

def get_sql_command(opts)
  if not blank?(opts[:file])
    raise "File #{opts[:file]} does not exist" unless File.exist?(opts[:file])

    file = File.open(opts[:file], 'rb')
    file.read
  elsif blank?(opts[:command])
    raise "Either the --file or --command argument must be provided"
  else
    format_inline_sql_cmd(opts[:command])
  end
end

def stream_query_results(recordset, writer, opts)
  recordset_metadata = recordset.getMetaData()
  num_columns = recordset_metadata.getColumnCount()

  # Determine each column type. Values can be found at:
  # http://docs.oracle.com/javase/6/docs/api/constant-values.html#java.sql.Types
  column_types = []
  column_names = []
  (1..num_columns).each do |i|
    column_names.push recordset_metadata.getColumnName(i)
    column_types[i] = recordset_metadata.getColumnType(i)
  end

  writer.puts column_names.join(opts[:delimiter]) if opts[:header]

  while (recordset.next) do
    row_values = []
    (1..num_columns).each do |i|
      if [1, -9, 12, -15, 91].include? column_types[i]
        # Only quote the output if the value internally contains the delimiting character or quotes
        col_value = recordset.getString(i)
        if not col_value.nil? 
          if col_value.include?(opts[:delimiter]) or col_value.include?(opts[:quotechar])
            col_value = "\"#{col_value}\""
          end
        end

        row_values.push(col_value)
      else
        row_values.push(recordset.getObject(i))
      end
      # puts row_values.length 
    end
    writer.puts row_values.join(opts[:delimiter])
  end
end

def blank?(value)
  value.nil? || (value.class == String and value.empty?)
end

if __FILE__ == $PROGRAM_NAME
  main()
end
