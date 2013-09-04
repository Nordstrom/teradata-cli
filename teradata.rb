require "#{File.expand_path File.dirname(__FILE__)}/terajdbc4.jar"
require 'jdbc/teradata'
java_import java.sql.Types

Jdbc::Teradata::load_driver

class Teradata
	# http://docs.oracle.com/javase/6/docs/api/constant-values.html#java.sql.Types
	STRING_SQL_TYPES = [1, -9, 12, -15, 91]

	# https://www.ruby-forum.com/topic/202574
	def self.open(*args)
    yield new(*args)
  ensure
    self._connection.close
  end

	def initialize(host, username, password)
		self._connection = java.sql.DriverManager.get_connection(
	    "jdbc:teradata://#{host}/", username, password)
	end

	def select(sql, timeout=120)
		sql_statement = self._connection.create_statement
    sql_statement.setQueryTimeout(timeout)
    
    # Execute the Teradata command
    begin
      recordset = sql_statement.execute_query(sql_cmd)
    rescue com.teradata.jdbc.jdbc_4.util.JDBCException => e
    	raise "Database exception: #{e.message}"
    end

    columns = self.load_metadata(recordset)

   	while (recordset.next) do
   		yield self.build_row(recordset, columns)
   	end
	end

	def build_row(recordset, columns)
		row = {}
    (1..columns.length).each do |i|
      if STRING_SQL_TYPES.include? columns[i][:type]
      	value = recordset.getString(i)
      else
      	value = recordset.getObject(i)
      end
      row[columns[i][:name]] = value
    end
    return row
	end

	def load_metadata(recordset)
		recordset_metadata = recordset.getMetaData()
  	num_columns = recordset_metadata.getColumnCount()

	  columns = []
	  (1..num_columns).each do |i|
	  	columns.push({
	  		name: recordset_metadata.getColumnName(i), 
	  		type: recordset_metadata.getColumnType(i)
	  	})
	  end
	  columns
	end
end