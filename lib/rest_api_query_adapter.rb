module RestApiQueryAdapter
	require 'json_api_filter_adapter/eq_operator'
  require 'json_api_filter_adapter/gt_operator'
  require 'json_api_filter_adapter/gte_operator'
  require 'json_api_filter_adapter/lt_operator'
  require 'json_api_filter_adapter/lte_operator'
  require 'json_api_filter_adapter/in_operator'
  require 'json_api_filter_adapter/not_in_operator'
  require 'json_api_filter_adapter/in_range_of_operator'

  TEMPLATE_OPERATORS = {
    "=" => JsonApiFilterAdapter::EqOperator,
    ">" => JsonApiFilterAdapter::GtOperator,
    ">=" => JsonApiFilterAdapter::GteOperator,
    "<" => JsonApiFilterAdapter::LtOperator,
    "<=" => JsonApiFilterAdapter::LteOperator,
    "in" => JsonApiFilterAdapter::InOperator,
    "not_in" => JsonApiFilterAdapter::NotInOperator,
    ".." => JsonApiFilterAdapter::InRangeOfOperator,
  }
  # Recevi object query and return array with
  # string query and value.
  # Ex: query object: {attribute: "a", operator:"=", values: [1]}
  # >> ["a = ?", [1]]
  def build_pair_query_string_and_values(q)
    TEMPLATE_OPERATORS[q[:operator].to_s].process(q)
  end

  # Recevi array of pairs string queries and values and join
  # with conector
  # Ex: join_query_string_and_values([["a = ?", [1]],["b = ?", [1]]], :or)
  # >> ["a = ? or b = ?", [1], [1]]
  def join_query_string_and_values(queries_strings, conector)
    query_array = [queries_strings.map{|q| q[0]}.join(" "+conector.to_s.upcase+" ")]
    queries_strings.each do |q|
      count_of_values_ocurrence = q[0].scan(/\?/).size
      q[1..count_of_values_ocurrence].each do |value|
        query_array << value if !value.blank?
      end
    end
    query_array
  end

  def query_builder(q)
    conector = q.keys[0]
    pair_query_string_and_values = q[conector].map do |query_obj|
      if query_obj.keys.map(&:to_sym).any?{|key| [:or,:and].include?(key)}
        template = "(:query)"
        nested_query = query_builder(query_obj) # Recursive
        string = nested_query.shift
        builded = [template.gsub(":query", string)] + nested_query
      else
        builded = build_pair_query_string_and_values(query_obj)
      end

      if builded.last == :self_flatten
        builded.pop
        builded.flatten!
      end

      builded
    end
    
    return join_query_string_and_values(pair_query_string_and_values, conector)

  end

  def parse_filter_adapter_v2(query)
    query_builder(query)
  end
    
end