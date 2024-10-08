module JsonApiFilterAdapter
  class InRangeOfOperator
    class << self
      def process(q)
        [template(q),
        [
          [transform_data_for_first(q[:values][0]),transform_data_for_last(q[:values][1])]
        ],
        :self_flatten] # :self_flatten indicates that should run flatten method at query_builder step
      end

      def template(q)
        ":attribute BETWEEN ? AND ?".gsub(":attribute", q[:attribute])
      end

      private

      def transform_data_for_first(first)
        case first
        when /^\d{4}-\d{2}-\d{2}$/ # somente com data
          Time.use_zone(JsonApiFilterAdapter.time_zone) { Time.zone.parse(first).beginning_of_day }
        when /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/ # com data e hora
          Time.use_zone(JsonApiFilterAdapter.time_zone) { Time.zone.parse(first) }
        when /^\d{4}-\d{2}-\d{2} \d{2}:\d{2} \S+$/ # com data, hora e fuso horário
          Time.use_zone(JsonApiFilterAdapter.time_zone) { Time.zone.parse(first) }
        else
          first
        end
      end

      def transform_data_for_last(last)
        case last
        when /^\d{4}-\d{2}-\d{2}$/ # somente com data
          Time.use_zone(JsonApiFilterAdapter.time_zone) { Time.zone.parse(last).end_of_day }
        when /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/ # com data e hora
          Time.use_zone(JsonApiFilterAdapter.time_zone) { Time.zone.parse(last) }
        when /^\d{4}-\d{2}-\d{2} \d{2}:\d{2} \S+$/ # com data, hora e fuso horário
          Time.use_zone(JsonApiFilterAdapter.time_zone) { Time.zone.parse(last) }
        else
          last
        end
      end

    end
  end
end