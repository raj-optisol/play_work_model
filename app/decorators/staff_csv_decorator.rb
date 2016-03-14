class StaffCSVDecorator < Roar::Decorator
  delegate :kyck_id, to: :represented
  delegate :first_name, :last_name, :address1, :city, :state, :zipcode, :email, :phone_number, to: :user

  def initialize(current_user, model)
    @current_user = current_user
    super(model)
  end

  def title
    represented.title.capitalize
  end

  def competition
    KyckRegistrar::Actions::GetCompetitionEntries.new(
      @current_user,
      user.plays_for.first.team
    ).execute({}).first.try(:competition).try(:name) unless user.plays_for.empty?
  end

  private

  def user
    represented.user
  end
end