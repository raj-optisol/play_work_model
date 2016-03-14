module CardProductRepository
  extend Edr::AR::Repository
  extend CommonFinders::ActiveRecord
  set_model_class CardProduct

  def self.get_card_product( conditions={}, org_id=nil)
    # Sometimes, filter is a string
    filters = (conditions.is_a?(Hash) ? conditions : JSON.parse(conditions) )
    conditions = ConditionBuilder::SQL.build(filters)

    if !org_id
      query = CardProductData.where(conditions).limit(1)
    else
      con = conditions.slice(1, conditions.length-1)
      sql = ["SELECT * FROM ((SELECT *, 0 ordinal FROM card_products  WHERE sanctioning_body_id='#{filters[:sanctioning_body_id]}' and  ("+conditions[0]+" AND organization_id = '"+org_id+"'  and deleted_at IS NULL) ORDER BY age, amount LIMIT 1) UNION (SELECT *, 1 FROM card_products  WHERE ("+conditions[0]+" and organization_id is null and deleted_at IS NULL) ORDER BY age, amount LIMIT 1)) a ORDER BY ordinal LIMIT 1"].concat(con).concat(con)
      puts sql
      query = data_class.klass.find_by_sql(sql)
    end

      (query.map { |data| wrap(data) } || []).first
  end

  def self.find_by_id(product_id)
    wrap CardProductData.find_by_id(product_id)
  end
end
