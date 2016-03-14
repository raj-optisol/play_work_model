module ConditionBuilder

  module SQL
    OPERATOR_MAP = {_like: ' LIKE ', _gt: ' > ', _gte: ' >= ', _lt: ' < ',_lte: ' <= ', _in: ' IN ', _dne: ' != ', _or: " OR "}
    # Builds a condition set based on passed in filterOptions
    #
    # filterOptions is a hash like:
    #   {last_name: 'Smith'}
    #   {last_name_like: 'Smith'}
    def self.build(filterOptions)
      condition = []
      conVal = []

      filterOptions.each do |key, val|
        next if val.is_a?(String) && val.empty?
        key = key.to_s if key.is_a? Symbol
        idx = nil
        oper = ' = '
        OPERATOR_MAP.each do |k, v|
          idx = key.index(k.to_s, -k.length);
          if idx
            oper = OPERATOR_MAP[k]
            val = (k== :_like ? "%#{val}%" : val)
            break;
          end
        end
        cond = (idx ? key[0, idx] : key)

        if oper == ' IN '
          val = "(\'#{val.join("', '")}\')" if val.is_a?(Array)
          condition << cond+oper+val
        elsif oper == ' OR '
          str = '('
          cnt = 0
          val.each do |v|
            str << " OR " if cnt > 0
            str << "#{cond} = '#{v}'" unless v.nil?
            str << "#{cond} IS NULL" if v.nil?
            cnt = cnt + 1
          end
          str << ")"
          condition << str
        elsif val == nil
          condition << "#{cond} is NULL"
        else
          condition << cond+oper+'?'
          conVal << val;
        end
      end
      conditions = [condition.join(' AND '), *conVal]
    end
  end

  module Graph
    OPERATOR_MAP =  {_like: ' =~ ', _gt: ' > ', _gte: ' >= ', _lt: ' < ', _in: ' IN ', _dne: ' <> '}

    def self.build(filterOptions)
      condition = []
      conVal = {}
      filterOptions.each do |key, val|
        next if val.is_a?(String) && val.empty?
        key = key.to_s if key.is_a? Symbol
        idx = nil
        oper = ' = '
        OPERATOR_MAP.each do |k, v|
          idx = key.index(k.to_s, -k.length);
          if idx
            oper = OPERATOR_MAP[k]
            val = (k== :_like ? "(?i).*#{Regexp.quote(val)}.*" : val)
            break;
          end
        end

        cond = (idx ? key[0, idx] : key)

        cc = cond.split('.')
        cov = cond
        if cc.count > 1
          cov = cc.last
        end

        if (mt = cov.match(/\(([^\)]+)\)/))
          cov = '_'+mt[1]+'_' if mt && mt.length > 1
        else
          cond = cond+"!"
          cond = "x."+cond  if cc.count <= 1
        end

        if key == "id"
          cond = "ID(x)"
          cov = "xid"
        end

        condition << cond+oper+'{'+cov+'}'
        conVal[cov] = val;

      end
      conditions = [condition.join(' AND '), conVal]
    end
  end

  module OrientGraph
    OPERATOR_MAP =  {_like: OrientDB::BLUEPRINTS::Contains::IN, _gt: OrientDB::BLUEPRINTS::Compare::GREATER_THAN, _gte: OrientDB::BLUEPRINTS::Compare::GREATER_THAN_EQUAL, _lt: OrientDB::BLUEPRINTS::Compare::LESS_THAN, _lte: OrientDB::BLUEPRINTS::Compare::LESS_THAN_EQUAL, _in: OrientDB::BLUEPRINTS::Contains::IN, _dne: OrientDB::BLUEPRINTS::Compare::NOT_EQUAL}

  SQL_OPERATOR_MAP = {_like: ' LIKE ', _gt: ' > ', _gte: ' >= ', _lt: ' < ',_lte: ' <= ', _in: ' IN ', _dne: ' <> ', _or: " OR "}
    def self.build(query, filterOptions)
      condition = []
      conVal = {}

      filterOptions.each do |key, val|
        next if val.is_a?(String) && val.empty?
        key = key.to_s if key.is_a? Symbol
        idx = nil
        like = false
        oper = OrientDB::BLUEPRINTS::Compare::EQUAL
        OPERATOR_MAP.each do |k, v|
          idx = key.index(k.to_s, -k.length);
          next if v.blank?
          if idx
            oper = OPERATOR_MAP[k]
            like = (k== :_like ? true : false)
            break;
          end
         end

         cond = (idx ? key[0, idx] : key)
         if query.kind_of?(Java::ComTinkerpopGremlinJava::GremlinPipeline) && (like || cond == "id")
           query.filter{|it| (/(?i).*#{Regexp.quote(val)}.*/  =~ it[cond])==0 } if like
           query.filter{|it| it.id.toString() == val} if cond=="id"
         else
           val = "%#{val}%" if like
           query.has(cond, oper, val)
         end

      end
      # conditions = [condition.join(' AND '), conVal]
      query
    end

    def self.build_sql(filterOptions)
      condition = []
      conVal = []

      filterOptions.each do |key, val|
        next if val.is_a?(String) && val.empty?
        key = key.to_s if key.is_a? Symbol
        idx = nil
        oper = ' = '
        SQL_OPERATOR_MAP.each do |k, v|
          idx = key.index(k.to_s, -k.length);
          if idx
            oper = SQL_OPERATOR_MAP[k]
            val = (k== :_like ? "%#{val}%" : val)
            break;
          end
        end
        cond = (idx ? key[0, idx] : key)

        if oper == ' IN '
          val = "[\'#{val.join("', '")}\']" if val.is_a?(Array)
          condition << cond+oper+val
        elsif oper == ' OR '
          str = '('
          cnt = 0
          val.each do |v|
            str << " OR " if cnt > 0
            str << "#{cond} = '#{v}'" unless v.nil?
            str << "#{cond} IS NULL" if v.nil?
            cnt = cnt + 1
          end
          str << ")"
          condition << str
        elsif val == nil
          condition << "#{cond} is NULL"
        else
          if cond == "birthdate"
            condition << cond+oper+"date('#{val}', 'yyyy-MM-dd')"
          else
            condition << cond+oper+'?'
            conVal << val.gsub(/'/) { %q(\') }
          end
        end
      end
      conditions = [condition.join(' AND '), *conVal]
    end

    def self.sql_build(filterOptions)
      str_and_tokens = build_sql(filterOptions)

      where = str_and_tokens.shift

      statement = where.gsub('?') {"'#{ str_and_tokens.shift }'"}
    end
  end
end
