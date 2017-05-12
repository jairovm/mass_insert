module MassInsert
  class Builder
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def build(values)
      adapter.tap{ |a| a.values = values }.to_sql
    end

  private

    def adapter
      @adapter ||= Utilities.adapter_class.new(options)
    end
  end
end
