class CardProcessor
  class << self
    def process(event)
      Rails.logger.debug "** Handling Card"
      cp = new
      cp.send(event['name'], event['content']) if cp.respond_to?(event['name'])
    end
  end

  def order_paid(content)
    order = OrderRepository.find(content["order_id"])
    requestor = UserRepository.find(kyck_id: content["user_id"])

    org = case order.payer_type
          when 'Organization'
            OrganizationRepository.find(kyck_id: order.payer_id)
          end
    cards_action = KyckRegistrar::Actions::RequestCards.new(requestor, org)
    res = cards_action.execute({items: order.order_items, order_id: order.id})
    Oriented.graph.commit
    res
  end

end
