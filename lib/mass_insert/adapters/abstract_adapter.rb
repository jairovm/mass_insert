module MassInsert
  module Adapters
    class AbstractAdapter < SimpleDelegator
      attr_accessor :values
      attr_reader   :options

      ASSOCIATION_TYPES = [:has_one, :has_many].freeze

      def initialize(options)
        @options = options
        super options[:class_name]
      end

      def to_sql
        "#{insert_sql} #{values_sql};"
      end

      def associations
        associations_hash.reject{|a, attrs| attrs[:all_records].empty? }
      end

    private

      def columns
        @columns ||= begin
          columns = column_names
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
          columns.map { |c| connection.quote get_value(attrs, c) }.join(',')
        end
      end

      def get_value(attrs, name)
        value = attrs[name.to_sym]
        value = attrs[name.to_s] if value.nil?

        case value
        when ::Proc then value.(attrs[:_foreign_keys])
        else
          value
        end
      end

      def association_objects
        @association_objects ||= reflect_on_all_associations.select{|a|
          a.macro.in? ASSOCIATION_TYPES
        }
      end

      def associations_hash
        association_objects.inject({}) do |hash, association|
          all_records = {}

          values.each_with_index do |attrs, index|
            records = get_value(attrs, association.name)

            if records.present?
              records = [records] unless records.is_a?(Array)

              all_records[index] = records.each{ |r|
                r.merge!(_foreign_keys: attrs[:_foreign_keys])
              }
            end
          end

          hash[association.name.to_sym] = {
            class_name: association.class_name,
            foreign_key: association.foreign_key.to_sym,
            all_records: all_records
          }

          hash
        end
      end
    end
  end
end
