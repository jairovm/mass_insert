module MassInsert
  class Process
    attr_reader :values, :options

    def initialize(values, options)
      @values  = values
      @options = options
    end

    def start
      options[:class_name].transaction do
        values.each_slice(per_batch).each do |batch|
          result = executer.execute(builder.build(batch).to_sql)
          builder.assign_foreign_key_to_associations(result) if options[:associations]
        end

        builder.associations.each do |_, attrs|
          process_association(attrs)
        end if options[:associations]
      end

      true
    end

  private

    def process_association(attrs)
      association_values  = attrs.delete(:values)
      attrs               = options.merge(attrs)
      attrs[:class_name]  = attrs[:class_name].constantize
      attrs[:primary_key] = false

      self.class.new(association_values, attrs).start
    end

    def builder
      @builder ||= Builder.new(options)
    end

    def executer
      @executer ||= Executer.new(options)
    end

    def per_batch
      options.fetch(:per_batch) { Utilities.per_batch }
    end
  end
end
