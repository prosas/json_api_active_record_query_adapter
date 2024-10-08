module JsonApiFilterAdapter
  class NotInOperator
    class << self
      def process(q)
        [template(q), q[:values]]
      end

      def template(q)
        if q[:values].include?("=null=")
          "(:attribute IS NOT NULL OR :attribute not in (?))".gsub(":attribute", q[:attribute])
        else
          ":attribute not in (?)".gsub(":attribute", q[:attribute])
        end
      end
    end
  end
end