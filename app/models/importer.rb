require 'importer/document'

class Importer
  def initialize(params, org, teams, requestor)
    @meta = params["meta"] || params[:meta] || {}
    @data = params["data"] || params[:data]
    @items = @data.reduce([]) do |items, item_data|
      items << Item.new(item_data, org, teams, requestor)
      items
    end
    @requestor = requestor
  end

  def import!
    @failures = @items.reject { |i| i.save }
    self
  end

  def results
    meta = @meta.merge({ count: count_hash })
    {
      meta: meta,
      data: failures
    }
  end

  private

  def total_count
    @items.count
  end

  def failed_count
    @failures.count
  end

  def saved_count
    total_count - failed_count
  end

  def count_hash
    {
      total: total_count,
      saved: saved_count,
      failed: failed_count
    }
  end

  def failures
    @failures.map &:to_h
  end
end
