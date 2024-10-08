module JsonApiFilterAdapter
  class InOperator
    class << self
      def process(q)
        values = q[:values].dup
        values.delete("=null=")
        [template(q), values]
      end

      def template(q)
        return ":attribute IS NULL".gsub(":attribute", q[:attribute]) if q[:values].size == 1 && q[:values].include?("=null=")

        return "(:attribute IS NULL OR :attribute IN (?))".gsub(":attribute", q[:attribute]) if q[:values].include?("=null=")

        ":attribute IN (?)".gsub(":attribute", q[:attribute])
      end
    end
  end
end