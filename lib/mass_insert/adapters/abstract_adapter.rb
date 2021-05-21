module MassInsert
  module Adapters
    class AbstractAdapter < SimpleDelegator
      attr_accessor :values
      attr_reader   :options

      ASSOCIATION_TYPES = %i[has_one has_many].freeze

      def initialize(options)
        @options = options
        super options[:class_name]
      end

      def to_sql
        "#{insert_sql} #{values_sql};"
      end

      def associations
        associations_hash.select { |_, attrs| attrs[:associations_hash].present? }
      end

    private

      def columns
        @columns ||= begin
          columns = column_names.dup
          columns.delete(primary_key) unless options[:primary_key]
          columns.map(&:to_sym)
        end
      end

      def quoted_columns
        columns.map do |name|
          connection.quote_column_name(name)
        end
      end

      def insert_sql
        "INSERT INTO #{quoted_table_name} #{columns_sql} VALUES"
      end

      def columns_sql
        @columns_sql ||= "(#{quoted_columns.join(',')})"
      end

      def values_sql
        "(#{array_of_attributes_sql.join('),(')})"
      end

      def array_of_attributes_sql
        values.map do |attrs|
          columns.map { |c| connection.quote column_value(attrs, c) }.join(',')
        end
      end

      def association_objects
        @association_objects ||= reflect_on_all_associations.select do |a|
          a.macro.in?(ASSOCIATION_TYPES)
        end
      end

      def associations_hash
        association_objects.each_with_object({}) do |association, hash|
          associations_hash = {}

          values.each_with_index do |attrs, index|
            records = column_value(attrs, association.name)

            associations_hash[index] = Array(records).each do |record|
              record.merge!(association_foreign_keys: attrs[:association_foreign_keys])
            end if records.present?
          end

          hash[association.name.to_sym] = {
            class_name: association.class_name,
            foreign_key: association.foreign_key.to_sym,
            associations_hash: associations_hash
          }
        end
      end

      def column_value(attrs, column)
        value = attrs.fetch(column.to_sym) { attrs.fetch(column.to_s, nil) }

        case value
        when ::Proc then value.call(attrs[:association_foreign_keys])
        else
          value
        end
      end
    end
  end
end
