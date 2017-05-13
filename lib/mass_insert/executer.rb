module MassInsert
  class Executer
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def execute(query)
      options[:class_name].connection.execute(query)
    end
  end
end
