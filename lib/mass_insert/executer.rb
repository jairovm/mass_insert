module MassInsert
  class Executer
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def execute(query)
      result = options[:class_name].connection.execute(query)

      result = options[:class_name].connection.exec_query(
        "SELECT LAST_INSERT_ID() AS last_id, ROW_COUNT() AS row_count;"
      ).first if options[:associations]

      result
    end
  end
end
