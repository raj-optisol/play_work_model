# encoding: UTF-8
class CardQueryParameters
  attr_accessor :sanctioning_body_id
  USER_ATTRS = [:last_name,
                :last_name_like,
                :first_name,
                :first_name_like,
                :birthdate]
  def initialize(params)
    @params = params
    card_filters
    user_filters
    move_user_filters_to_card_filters
  end

  def sql
    sql = "select from #{selfrom} "
    unless card_filters.blank?
      sql = sql + ' where ' + ConditionBuilder::OrientGraph.sql_build(
        Hash[card_filters.sort])
    end
    sql
  end

  private

  def user_filters
    @user_filters ||= (@params[:user_conditions] || {}).with_indifferent_access
  end

  def team_filters
    @team_filters ||= (@params[:team_conditions] || {}).with_indifferent_access
  end

  def card_filters
    @card_filters ||= (@params[:card_conditions] || {}).with_indifferent_access
  end

  def organization_filters
    @org_filters ||= (@params[:organization_conditions] ||
                      {}).with_indifferent_access
  end

  def sanction_filters
    @sanction_filters ||= (@params[:sanction_conditions] ||
                           {}).with_indifferent_access
  end

  def selfrom
    if !team_filters[:kyck_id].blank?
      add_organization_id_to_card_filters
      team_select_from
    elsif !organization_filters[:kyck_id].blank?
      organization_select_from
    elsif !sanction_filters[:kyck_id].blank?
      sanction_select_from
    else
      'card'
    end
  end

  def add_organization_id_to_card_filters
    return if organization_filters[:organization_id].blank?
    card_filters['out_Card__carded_for.kyck_id'] =
      organization_filters[:organization_id]
  end

  def move_user_filters_to_card_filters
    USER_ATTRS.each do |attr|
      next unless @user_filters[attr]
      @card_filters[attr] = @user_filters.delete(attr).downcase
    end
  end

  def team_select_from
    "(select expand(in('Card__carded_user')) from (select " \
      'expand(distinct(out))  from (traverse out_Team__rosters, ' \
      'in_staff_for, in_plays_for from (select from Team where kyck_id = ' \
      "'#{team_filters[:kyck_id]}')) where @class IN ['staff_for', " \
      "'plays_for']))"
  end

  def organization_select_from
    "(select expand(in('Card__carded_for')) from Organization " \
      "where kyck_id = '#{organization_filters[:kyck_id]}')"
  end

  def sanction_select_from
    "(select expand(in('Card__carded_for')) from " \
      '(traverse in from (select from (traverse out_sanctions ' \
      "from #{sanctioning_body_id}) where " \
      "kyck_id = '#{sanction_filters[:kyck_id]}')))"
  end

  def sanctioning_body_id
    @sanctioning_body_id ||= '#13:0'
  end
end
