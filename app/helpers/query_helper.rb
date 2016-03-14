# encoding: UTF-8
module QueryHelper
  DEFAULT_PAGE_SIZE = 25

  def default_query_options(params = {})
    options = paging_options(params)

    params[:filter] = JSON.parse(params[:filter]) if (params[:filter] && params[:filter].instance_of?(String))
    options = options.merge({conditions: (params[:filter] || {})})

    if params[:startrid]
      options[:conditions][:@rid_gt] = params[:startrid]
      limit = 0
    end

    return options
  end

  def paging_options(params = {})
    limit = per_page = params.fetch(:per_page, DEFAULT_PAGE_SIZE).to_i
    page = [params.fetch(:page, 1).to_i, 1].max
    options = {}
    if params[:orderby] && !params[:orderby].blank?
      options[:order] = params[:orderby]
      options[:order_dir] = params.fetch(:dir, 'desc')
    end
    options = options.merge({ :limit => per_page })
    options = options.merge({ :offset => (page-1)*limit })
    options
  end

  def parse_filters
    params[:filter] = JSON.parse(
      params[:filter]
    ) if params[:filter] && params[:filter].instance_of?(String)
  end

  def team_filters(filters, search_params = {})
    search_params[:team_conditions] = {}
    if filters[:team_id]
      search_params[:team_conditions][:kyck_id] = filters[:team_id]
    elsif filters[:team_name_like]
      search_params[:team_conditions][:name_like] = filters[:team_name_like]
    else
      search_params.delete(:team_conditions)
      search_params[:is_open_roster] = true if filters[:is_open_roster]
    end
    search_params
  end

  def user_filters(filters, search_params)
    search_params[:user_conditions] = {
      last_name_like: filters[:last_name_like]
    } if filters[:last_name_like] && !filters[:last_name_like].empty?
    search_params
  end
end
