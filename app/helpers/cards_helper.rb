module CardsHelper
  def overview
    respond_to do |format|
      format.html do
        return if @obj.is_a?(SanctioningBody)
        if @obj
          @reqobj = @org
          @reqobj = @obj  if (@obj.is_a?(Competition))

          @req = pending_or_denied_recently(@reqobj)
          @order = KyckRegistrar::Actions::GetOrCreateOrder.new(
            current_user
          ).execute(order_params).extend(OrderRepresenter)
        end
      end
    end
  end

  def handle_index_options
    options = view_context.default_query_options(params)
    if options[:conditions]
      unless user_conditions(options).empty?
        options[:user_conditions] = user_conditions(options)
      end
      options[:card_conditions] = card_conditions(options)
      unless team_conditions(options).empty?
        options[:team_conditions] = team_conditions(options)
      end
      unless organization_conditions(options).empty?
        options[:organization_conditions] = organization_conditions(options)
      end
      options[:sanction_conditions] = {
        kyck_id: options[:conditions][:sanction_id]
      } if options[:conditions][:sanction_id]
      options.delete(:conditions)
    else
      options[:card_conditions] = {}
    end
    if params[:card_request_id]
      options[:card_conditions][:order_id] = params[:card_request_id]
    end
    options
  end

  def organization_conditions(options)
    org_id = if (options && options[:conditions] &&
                 options[:conditions]['organization_id'])
               options[:conditions]['organization_id']
             elsif params['organization_id']
               params['organization_id']
             end
    return {} unless org_id

    @org ||= OrganizationRepository.find_by_kyck_id(org_id)

    @organization_conds ||= { kyck_id: org_id }
  end

  def team_conditions(options)
    @team_conds ||=
      begin
        team_id = options[:conditions][:team_id] || params[:team_id]
        return {} if team_id.blank?
        { kyck_id: team_id }
      end
  end

  def duplicate_card_attributes(card)
    {
      status_nin: ['released', 'expired'],
      kind: card.kind.to_s.downcase
    }
  end

  def set_approval_email_sent
    if params[:commit].to_s == 'Deactivate'
      params[:card][:approval_email_sent] = 'false'
    end
  end

  def order_params
    p = {}
    if @org
      p[:payer_id] = @org.kyck_id
      p[:payer_type] = 'Organization'
      p[:state] = @org.locations.first.state if @org.locations.first
    end
    p
  end

  def user_conditions(options)
    @user_conds ||= options[:conditions].slice(
      :last_name_like,
      :last_name,
      :first_name_like,
      :first_name,
      :birthdate
    )
    user_id = params[:user_id] ||
      (params[:filter] and params[:filter][:user_id])
    @user_conds[:kyck_id] = user_id if user_id
    @user_conds.delete(:last_name_like) if @user_conds[:last_name_like] &&
      @user_conds[:last_name_like].blank?
    @user_conds
  end

  def card_conditions(options)
    @card_conds ||= options[:conditions].slice(*card_fields)
    if @card_conds[:status] && @card_conds[:status].blank?
      @card_conds.delete(:status)
    elsif @card_conds[:status_in] && @card_conds[:status_in].try(:first).try(:blank?)
      @card_conds.delete(:status_in)
    end
    @card_conds
  end

  def card_fields
    [
      :kind,
      :status,
      :status_in,
      :message_status,
      :card_request_id,
      :kyck_id_dne,
      :kyck_id_in,
      :created_at_gte,
      :created_at_lte,
      :approved_on_gte,
      :approved_on_lte,
      :expires_on_gte,
      :expires_on_lte
    ]
  end

  def pending_or_denied_recently(obj)
    SanctioningRequestRepository.get_pending_request(obj) ||
      SanctioningRequestRepository.denied_within_time(obj).first
  end

  def can_manage_card?
    current_user.has_permission?(
      @order.payer,
      [PermissionSet::MANAGE_CARD, PermissionSet::REQUEST_CARD],
      false) ||
      current_user.can_manage?(
        @sanctioning_body,
        [PermissionSet::MANAGE_CARD]
      )
  end

  def order_has_more_cards?(order, cards)
    sql = "select kyck_id from card where order_id = #{order.id}" \
      ' and status = "new"'
    cmd = OrientDB::SQLCommand.new(sql)
    res = Oriented.graph.command(cmd).execute.to_a
    done_cards = cards.map(&:kyck_id)
    new_cards = res.map { |r| r['kyck_id'] }
    (new_cards - done_cards).any?
  end

  def approve_action
    action = KyckRegistrar::Actions::ApproveCards.new(current_user, @sanctioning_body, @competition)
    options = { card_ids: params[:card_ids] }

    action.on(:cards_approved) do |cards, requestor|

      OrderHandler.new.handle_multiple_card_orders(cards)

      order = OrderRepository.orders_for_card(cards.first, nil, true, 1)
      order_info = cards.map do |c|
        item = order.order_items.find { |i| i.item_id.to_s == c.kyck_id.to_s }
        next unless item

        {
          full_name: c.full_name,
          order_id: order.id,
          order_item_id: item.id,
          status: c.status
        }
      end

      order_info.select! { |oi| !oi.nil? }
      CardApprovalEmailHandler.new.add_to_queue(order_info)
    end
    action.execute(options)
  end

  def decline_action
    refund = params.fetch(:refund, false)
    action = KyckRegistrar::Actions::DeclineCards.new(current_user, @sanctioning_body, @competition)
    options = { card_ids: params[:card_ids], reason: params[:reason] }

    action.on(:cards_declined) do |cards|
      OrderHandler.new.handle_multiple_card_orders(cards)

      order = OrderRepository.orders_for_card(cards.first, nil, true, 1)
      return unless order

      if refund
        card_ids = cards.map(&:kyck_id).map(&:to_s)
        order_items = order.order_items.select { |i| card_ids.include?(i.item_id.to_s) }
        act = KyckRegistrar::Actions::RefundOrder.new(current_user, order)
        act.execute(order_items: order_items )
      end

      KyckMailer.cards_declined!(order, cards, current_user, params[:reason])
    end
    action.execute(options)
  end
end
