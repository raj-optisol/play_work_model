# encoding: UTF-8
# Controlls incoming requests for Cards data.
class CardsController < ApplicationController
  include Roar::Rails::ControllerAdditions
  include CardsHelper
  respond_to :html, :json
  before_filter :obj
  before_filter :set_approval_email_sent, :only => [:update]
  layout :set_layout

  def index
    respond_to do |format|

      format.html do
        if @org
          @order = KyckRegistrar::Actions::GetOrCreateOrder.new(
            current_user
          ).execute(order_params).extend(OrderRepresenter)
        end
        @context = if params[:sanctioning_body_id]
                     'sanctioning_body'
                   elsif params[:competition_id]
                     'competition'
                   elsif params[:team_id]
                     'team'
                   else
                     'organization'
                   end
      end
      format.json do
        options = handle_index_options

        action = KyckRegistrar::Actions::GetCards.new(
          current_user,
          @sanctioning_body,
          @competition || @org,
          @user
        )

        @cards = action.execute(options)
        respond_with @cards, represent_items_with: CardRepresenter, with_teams: !(@org.nil?)
      end

      format.pdf do
        options = handle_index_options

        # DO NOT put special conditions here UNLESS they are in the
        # json block too...they have to MATCH
        options[:card_conditions] ||= {}

        action = KyckRegistrar::Actions::GetCards.new(
          current_user,
          @sanctioning_body,
          @competition || @org,
          @user
        )

        options.merge!({kyck_ids: params[:kyck_ids].split(",")}) if params[:kyck_ids]
        @cards = action.execute(options)
        @cards = @cards.select do |c|
          c.status == :approved
        end
        prodarr =  @cards.map{|s|
          s.carded_user; s.documents;
          s.carded_for.state if s.carded_for
          s.extend(CardRepresenter)
        }

        pdf = CardPdf.new(prodarr, view_context, @comp)

        send_data pdf.render, filename: 'passcards.pdf',
          type: 'application/pdf',
          disposition: 'inline'
      end
    end
  end

  def duplicates
    card_action = KyckRegistrar::Actions::GetCards.new(current_user, @sanctioning_body, @competition || @org, @user)
    @card = card_action.execute(card_conditions: {kyck_id: params[:id]}).first

    return not_found unless @card
    render :json => [] and return unless @card && !@card.duplicate_lookup_hash.blank?

    action = KyckRegistrar::Actions::FindPotentialDuplicateCards.new(current_user, @card, @competition)
    @duplicate_cards = action.execute(duplicate_card_attributes(@card))

    respond_with @duplicate_cards, represent_items_with: CardRepresenter

  end

  def show
    action = KyckRegistrar::Actions::GetCards.new(current_user, @sanctioning_body, @competition || @org, @user)
    @card = action.execute(card_conditions: {kyck_id: params[:id]}).first
    return not_found unless @card
    @card.extend(CardRepresenter)
    respond_to do |format|
      format.pdf {
        return not_found unless @card.status == :approved && @card.carded_for.sanctioned?
        pdf = CardPdf.new([@card], view_context, nil, 'org')

        send_data pdf.render, filename: 'passcard.pdf',
          type: 'application/pdf',
          disposition: 'inline'
      }
    end
  end

  def edit
    if current_user.can_manage?(@sanctioning_body, [PermissionSet::MANAGE_CARD, PermissionSet::MANAGE_REQUEST, PermissionSet::PRINT_CARD], false)
      @card = CardRepository.find_by_kyck_id params[:id]
    end
    return not_found unless @card

    @card.extend(CardRepresenter)
    respond_with(@card)
  end

  def update
    card = CardRepository.find(kyck_id: params[:id])
    action = KyckRegistrar::Actions::UpdateCard.new(current_user, card)
    action.execute(params[:card])

    respond_to do |format|
      format.html do
        if params[:save_and_return]
          if card.order_id
            redirect_to sanctioning_body_card_request_path(@sanctioning_body, card.order_id)
          else
            redirect_to sanctioning_body_card_requests_path(@sanctioning_body)
          end

        else
          redirect_to edit_card_path(card)
        end
      end

      format.json{
        respond_with card.extend(CardRepresenter), status: 200
      }
    end
  end

  def approve
    @cards = approve_action

    respond_to do |format|
      format.html {
        if params[:card_request_id]
          redirect_to sanctioning_body_card_request_path(@sanctioning_body, params[:card_request_id])
        else
          if more_cards?
            redirect_to sanctioning_body_card_request_path(
              @sanctioning_body,
              @order.id)
          else
            redirect_to sanctioning_body_card_requests_path(@sanctioning_body)
          end
        end

      }
      format.json  { respond_with @cards }
    end
  end

  def more_cards?
    if @cards && @cards.first && @cards.first.order_id
      @order = OrderRepository.find @cards.first.order_id
    end
  end

    def decline
      @cards = decline_action
      respond_to do |format|
        format.html do
          redirect_to sanctioning_body_cards_path(@sanctioning_body)
        end
        format.json  { respond_with @cards }
      end
    end

    private

    def team
      @team = OrganizationRepository::TeamRepository.find(
        kyck_id: params[:team_id])
      @org = @team.organization.extend(OrganizationRepresenter)
      @team
    end

    def competition
      @competition = CompetitionRepository.find(
        kyck_id: params[:competition_id])
      @competition
    end

    def card_request
      @order = OrderRepository.find(params[:card_request_id])
      @sanctioning_body = @order.payee
      unless can_manage_card?
        params[:filter] ||= {}
        params[:filter][:status] = 'approved'
      end
      @org = @order.payer
    end

    def user
      @user = UserRepository.find(kyck_id: params[:user_id])
    end

    def obj
      @sanctioning_body = SanctioningBodyRepository.all.first
      @sanctioning_body.extend(SanctioningBodyRepresenter)
      @obj = if params[:team_id]
               team
             elsif params[:competition_id]
               competition
             elsif params[:card_request_id]
               card_request
             elsif params[:user_id]
               user
               nil
             else
               @sanctioning_body
             end

      unless params[:order_id].blank?
        @order = OrderRepository.find(params[:order_id])
      end
      
      unless params[:competition_id]
        team = OrganizationRepository::TeamRepository.find(kyck_id: params[:team_id])
        if team && !@competition
          team.competition_entries.each do |ce|
            @comp = ce.competition if ce.competition
          end
        end
      end

      return unless @org
      @org.extend(OrganizationRepresenter)
      permobjs = current_user.has_permission_for(
        @org,
        [
          PermissionSet::REQUEST_CARD,
          PermissionSet::MANAGE_CARD,
          PermissionSet::REQUEST_PLAYER_CARD
        ],
        false)
      if permobjs.first
        @backobj = permobjs.first.staffed_item
      else
        @backobj = @org
      end

      @obj
    end

    def set_layout
      if @org
        'org_tabs'
      else
        'sanctioning_body'
      end
    end
  end
