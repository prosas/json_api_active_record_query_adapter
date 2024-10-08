# Biblioteca nativa do Ruby para lidar com parsing e formatação de datas e horas, como Time.parse

# Adpta objeto json para hash de consulta compativél com o active_record
## Como usar
# Inclua o module include JsonApiFilterAdapterV2 na controller.
# chame o método parse_filter_adapter_v2(params)
# ```
# class Controller < ApplicationControllers
#  Model.where(parse_filter_adapter(params))
#  ...
# end
# ```
module JsonApiFilterAdapter
  require 'rest_api_query_adapter'
  #Module temporário para transição entre versões
  module V2
    class << self
      attr_accessor :time_zone
    end
    include RestApiQueryAdapter
  end


  class << self
    attr_accessor :time_zone
  end

  VALUE = 1
  KEY = 0
  # Adpta objeto jsonvpara hash de consulta compativél com o active_record
  # Ex:
  # >> object_json_api = "{id: 1, data: 01/01/2022..31/01/2022}"
  # >> adpter_from_json_api_to_active_record(object_json_api)
  # >> {"id": 1, "data": Range(Date.parse("01/01/2022"), Date.parse("31/01/2022"))}
  def parse_filter_adapter(data)
    data_parsed = {}
    data.each do |parameter|
      next unless parameter[VALUE].to_s.include?('..')

      first, last = parameter[VALUE].split('..')

      case parameter[VALUE]
      when /^\d{4}-\d{2}-\d{2}$/ # somente com data
        data_parsed[parameter[KEY]] = Range.new(
          Time.use_zone(JsonApiFilterAdapter.time_zone) { Time.zone.parse(first).beginning_of_day },
          Time.use_zone(JsonApiFilterAdapter.time_zone) { Time.zone.parse(last).end_of_day }
        )
      when /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}..\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/ # com data e hora
        data_parsed[parameter[KEY]] = Range.new(
          Time.use_zone(JsonApiFilterAdapter.time_zone) { Time.zone.parse(first) },
          Time.use_zone(JsonApiFilterAdapter.time_zone) { Time.zone.parse(last) }
        )
      when /^\d{4}-\d{2}-\d{2} \d{2}:\d{2} \S+$/ # com data, hora e fuso horário
        data_parsed[parameter[KEY]] = Range.new(
          Time.use_zone(JsonApiFilterAdapter.time_zone) { Time.zone.parse(first) },
          Time.use_zone(JsonApiFilterAdapter.time_zone) { Time.zone.parse(last) }
        )
      end
    end

    data.merge!(data_parsed)
    operator_parser_hash_to_array(data)
  end

  private

  def direct_logic_operator(query)
    operators_array = ['<=', '>=', '<', '>']
    operators_array.detect { |op| query.to_s.include? op }
  end

  def operator_parser_hash_to_array(data)
    data_converted_value = []
    data_converted_header = ''
    cont = 1

    # interar o data para analisar isoladamente cada chave vs valor
    data.each do |parameter|
      # tratar operador de comparação
      value_downcase = parameter[VALUE].to_s.downcase
      if value_downcase.include?('=like=')
        conditional_operator = ':value LIKE ?'
        parameter[VALUE] = "%#{parameter[VALUE]}%"
      elsif parameter[VALUE].is_a?(Range)
        conditional_operator = ':value BETWEEN ? AND ?'
      elsif parameter[VALUE].is_a?(Array) & !value_downcase.include?('=null=')
        conditional_operator = ':value IN (?)'
      elsif parameter[VALUE].is_a?(Array) && value_downcase.include?('=null=')
        parameter[VALUE] = parameter[VALUE].filter { |v| v != '=null=' }
        conditional_operator = '(:value IS NULL OR :value IN (?))'
      elsif !parameter[VALUE].is_a?(Array) && value_downcase.include?('=null=')
        parameter[VALUE] = nil
        conditional_operator = ':value IS NULL'
      elsif operator = direct_logic_operator(parameter[VALUE])
        parameter[VALUE].gsub!(operator, '').strip!
        conditional_operator = ":value #{operator} ?"
      else
        conditional_operator = ':value = ?'
      end

      # tratar operador de pesquisa
      query_conditional_operator = value_downcase.include?('=or=') ? 'OR' : 'AND'
      # criar a 1º string do vetor que carrega o corpo da pesquisa
      # saber se esta no final da lista de parametros
      if cont < data.to_hash.size
        # se não tiver no final da lista
        data_converted_header = "#{data_converted_header} #{conditional_operator} #{query_conditional_operator}".gsub(':value', parameter[KEY])
        cont += 1
      else
        # se tiver no final da lista
        data_converted_header = "#{data_converted_header} #{conditional_operator}".gsub(':value', parameter[KEY])
        cont += 1
      end
    end

    data_converted_header.strip!

    # criar os demais elementos do vetor que faram referencia em ordem a cada um dos pontos de interrogação
    data.to_hash.each_value do |value|
      # tratando entradas que não são arrays
      unless value.is_a?(Array)
        value_modificad = value.to_s.downcase
        # tratar like e or
        if value_modificad.include?('=like=')
          value_modificad.slice! '=like='
          value_modificad = "%#{value_modificad}%"
        end
        value_modificad.slice! '=or=' if value_modificad.include?('=or=')
        if value_modificad.include?('true') || value_modificad.include?('false')
          data_converted_value << value_modificad.to_bool
        elsif !value_modificad.include?('=null=')
          # tratar between
          if value.is_a?(Range)
            data_converted_value << value.first
            data_converted_value << value.last
          else
            data_converted_value << value_modificad
          end
        end
      end
      # tratando entradas que são array
      data_converted_value << value.filter { |v| v != '=null=' } if value.is_a?(Array)
    end

    # montar array de busca , primeira posição string query , segunda posição ate N serão parametros
    data_converted_value.unshift(data_converted_header)
    data_converted_value


  end
end
