module MassInsert
  class Builder
    attr_reader :options, :associations

    def initialize(options)
      @options      = options
      @associations = {}
    end

    def build(values)
      adapter.tap { |a| a.values = values }
    end

    def to_sql
      adapter.to_sql
    end

    def assign_foreign_key_to_associations(result)
      adapter.associations.each do |association, attrs|
        values                      = []
        id                          = result['last_id'].to_i
        associations[association] ||= { class_name: attrs[:class_name], values: [] }

        attrs[:associations_hash].each do |index, records|
          values += records.each do |record|
            record[attrs[:foreign_key]] = (id + index)

            record[:association_foreign_keys] ||= {}
            record[:association_foreign_keys][attrs[:foreign_key]] = record[attrs[:foreign_key]]
          end
        end

        associations[association][:values] += values
      end

      associations
    end

  private

    def adapter
      @adapter ||= Utilities.adapter_class.new(options)
    end
  end
end
