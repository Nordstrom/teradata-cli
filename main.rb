require "#{File.expand_path File.dirname(__FILE__)}/terajdbc4.jar"
require 'jdbc/teradata'
require 'trollop'
java_import java.sql.Types

Jdbc::Teradata::load_driver

@opts = Trollop::options do
  opt :host, "Teradata host name", :type => String
  opt :username, "Teradata username", :type => String
  opt :password, "Teradata password", :type => String
  opt :command, "Teradata SQL command", :type => String
  opt :delimiter, "Column delimiter", :type => String, :default => "\t"
  opt :quotechar, "The quote character", :type => String, :default => '"'
  opt :file, "Teradata sql file"
  opt :output, "File to write the output to", :type => String
  opt :timeout, "Command timeout in seconds", :type => Integer, :default => 30
  opt :header, "Print column headers in output", :default => false
end

def main()
  args_error = validate_args @opts
  if args_error
    puts args_error
    return
  end

  teradata_connection = java.sql.DriverManager.get_connection(
    "jdbc:teradata://#{@opts[:host]}/",
    @opts[:username],
    @opts[:password]
  )

  sql_statement = teradata_connection.create_statement
  sql_statement.setQueryTimeout(@opts[:timeout])

  sql_cmd = get_sql_command(@opts)
  
  # Execute the Teradata command
  begin
    recordset = sql_statement.execute_query(sql_cmd)
    
    if @opts[:output] 
      File.open(@opts[:output], 'w') do |file|
        stream_query_results(recordset, file)
      end
    else
      stream_query_results(recordset, $stdout)
    end
  rescue Exception => e
    raise e
  ensure
    # Ensure the connection gets closed
    teradata_connection.close
  end
end

def validate_args(opts)
  return "Must provide a --command arg" unless opts[:command]
  nil
end

def get_sql_command(opts)
  return opts[:command] if opts[:command]
  if opts[:file]
    # TODO: Read contents of specified file and return as string
  end
end

def stream_query_results(recordset, writer)
  recordset_metadata = recordset.getMetaData()
  num_columns = recordset_metadata.getColumnCount()

  # Determine each column type. Values can be found at:
  # http://docs.oracle.com/javase/6/docs/api/constant-values.html#java.sql.Types
  column_types = []
  (1..num_columns).each do |i|
    column_types[i] = recordset_metadata.getColumnType(i)
  end

  while (recordset.next) do
    row_values = []
    (1..num_columns).each do |i|
      if [1, -9, 12, -15, 91].include? column_types[i]
        # Only quote the output if the value internally contains the delimiting character or quotes
        col_value = recordset.getString(i)
        if col_value.include?(@opts[:delimiter]) or col_value.include?(@opts[:quotechar])
          col_value = "\"#{col_value}\""
        end

        row_values.push(col_value)
      else
        row_values.push(recordset.getObject(i))
      end
      # puts row_values.length 
    end
    writer.puts row_values.join(@opts[:delimiter])
  end
end

if __FILE__ == $PROGRAM_NAME
  main()
end
