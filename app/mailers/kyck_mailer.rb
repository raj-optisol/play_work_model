# encoding: UTF-8
# Includes all of the emails in the platform.
class KyckMailer < ActionMailer::Base
  include Apostle::Mailer
  default from: 'info@kyck.com'

  #
  #
  # Sends a staff added email
  # Params:
  #   org_name (String): name of organization
  #   to: (Hash) {email: email, name: name}
  #   from: (Hash) {email: email, name: name}
  #
  def staff_added!(org_name, to, from)
    return unless should_mail?(to[:email])
    mail(
      "staff-member-added",
      email: to[:email],
      name: to[:name],
      registrar: {
        name: from[:name],
        club: org_name
      }
    ).deliver!
  end

  def cards_declined!(order, cards, from, reason)
    @to = UserRepository.find(kyck_id: order.initiator_id)
    return unless should_mail?(@to.email)
    names = cards.map { |card| { name: card.carded_user.full_name } }
    mail(
      "card-request-declined",
      name: @to.full_name,
      email: @to.email,
      cards: names,
      error: reason
    ).deliver!
  end

  def staff_card_created!(org_name, to, from)
    return unless should_mail?(to[:email])
    mail(
      "staff-card-requested",
      name: to[:name],
      email: to[:email]
    ).deliver!
  end

  def organization_name_changed!(values)
    @to = 'admin@usclubsoccer.org'
    mail(
      "organization-name-changed",
      name: "US Club Soccer",
      email: @to,
      organization: {
        id: values[:id],
        state: values[:state],
        name: {
          old: values[:old_name],
          new: values[:new_name]
        }
      }
    ).deliver!
  end

  def organization_help_request!(user, values)
    @to = 'help@kyck.com'
    mail(
      "organization-help-request",
      name: values[:org_name],
      email: @to,
      user: {
        current_email: user.email,
        previous_email: values[:email],
        name: user.full_name,
        role: values[:role],
        state: values[:state],
        organization: {
          id: values[:org_id],
          name: values[:org_name]
        }
      },
    ).deliver!
  end

  def notification_settings_changed!(user)
    return unless should_mail?(user.email)
    mail(
      "account-information-updated",
      name: user.full_name,
      to: user.email
    ).deliver!
  end

  def purchase_completed!(purchaser, transaction, obj)
    return unless should_mail?(purchaser.email)
    mail(
      "payment-receipt",
      name: purchaser.full_name,
      email: purchaser.email,
      receipt: {
        id: transaction.transaction_id,
        type: transaction.reason,
        amount: transaction.amount,
        account: transaction.last4
      }
    ).deliver!
  end

  def card_request_approved!(requester, registrars, users)
    return unless requester && requester[0] && should_mail?(requester[0])
    names= users.map { |user| { name: user } }
    mail(
      "card-request-approved",
      name: requester[1],
      email: requester[0],
      cards: names
    ).deliver!
  end

  def sanctioning_request_approved!(request, opts = {})
    @to = request.issuer
    return unless @to
    return unless should_mail?(@to.email)
    @admin, @rep = opts[:admin], opts[:rep]
    @admincc = @admin ? @admin.email : ''
    @org = request.on_behalf_of
    @state = @org.locations.any? ? "(#{@org.locations.first.state})" : ''
    mail(
      "sanctioning-request-approved",
      name: @to.full_name,
      email: @to.email,
      user: {
        name: @to.full_name,
        id: @to.email
      },
      contacts: {
        "non-administrative" => {
          name: @rep.full_name,
          email: @rep.email,
          phone: @rep.phone_number
        },
        administrative: {
          name: @admin.full_name,
          email: @admin.email,
          phone: @admin.phone_number
        }
      }
    ).deliver!
  end

  def sanctioning_request_declined!(registrar, requester = nil, admin = nil)
    @to = requester || registrar
    return unless should_mail?(@to.email)
    @cc = requester ? registrar : ''
    @admin = admin

    mail(
      "sanctioning-request-declined",
      name: @to.full_name,
      email: @to.email,
      message: "Your sanctioning request has been rejected",
      contact: {
        name: @admin.full_name,
        email: @admin.email,
        phone: @admin.phone_number
      }
    ).deliver!
  end

  def card_approvals_for_order(order, cards)
    @to = order.initiator
    return unless @to.present?
    @cards = cards

    mail(
      to: @to.email,
      subject: 'KYCK Play: Card Approvals',
      template_name: :ordered_card_approvals
    ).deliver
  end

  def transaction_survey!(purchaser)
    return unless should_mail?(purchaser.email)
    mail(
      "transaction-survey",
      name: purchaser.full_name,
      email: purchaser.email,
    ).deliver!
  end

  private

  def should_mail?(to_email)
    !(to_email =~ /kyckfake/)
  end
end
