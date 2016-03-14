# encoding: UTF-8
# Common OrientDB Repository methods.
module CommonODBRepository
  def build_conditions(filters, prefix = '', logical_op = 'and')
    return if filters.nil? || filters.empty?

    sql = []
    prefix += '.' if prefix.size > 0
    filters.each do |key, value|
      if value.is_a?(Hash)

        sql << build_conditions(value, prefix + key.to_s)
      else
        op = condition_operator(key)
        key = sanitize_key(key, op)
        value = sanitize_value(value, op)
        sql << "#{prefix}#{key} #{op} #{value}"
      end
    end

    sql.join(" #{logical_op} ")
  end

  private

  def condition_operator(property)
    return 'like' if property =~ /_like\z/
    return '>' if property =~ /_gt\z/
    return '>=' if property =~ /_gte\z/
    return '<' if property =~ /_lt\z/
    return '<=' if property =~ /_lte\z/
    return '<>' if property =~ /_dne\z/
    return 'in' if property =~ /_in\z/
    return 'not in' if property =~ /_nin\z/

    '='
  end

  def sanitize_key(key, op)
    key = key.to_s if key.is_a?(Symbol)
    return key if op == '='

    key = key.sub(/(_like\z)|(_gte?\z)|(_lte?\z)|(_dne\z)|(_n?in\z)/, '')
    key = "#{key}.toLowerCase()" if op == 'like'

    key
  end

  def sanitize_value(value, op)
    if value.is_a?(Array) && value.first && value.first.is_a?(String)
      return "[\'#{value.join("', '")}\']"
    elsif value.is_a?(Array)
      return "[#{value.join(", ")}]"
    end

    value = value.to_s if value.is_a?(Symbol)
    return "'%#{value.to_s.downcase}%'" if op == 'like'
    return "'#{value}'" if value.is_a?(String)

    value
  end
end
