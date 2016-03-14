class PlayerCSVDecorator < Roar::Decorator
  extend Forwardable
  delegate :kyck_id => :represented
  delegate [:first_name, :middle_name, :last_name, :birthdate, :email, :phone_number, :address1, :city, :state, :zipcode] => :user

  def_delegator :team, :name, :team_name
  def_delegator :team, :kyck_id, :team_id
  def_delegator :team, :age_group, :team_age_group
  def_delegator 'team.organization', :kyck_id, :club_id

  def initialize(current_user, model)
    @current_user = current_user
    super(model)
  end

  def gender
    user.gender.capitalize
  end

  def parent_email
    user.owners.first.email if user.owners.any?
  end

  def competition
    KyckRegistrar::Actions::GetCompetitionEntries.new(@current_user, team).execute({}).first.try(:competition).try(:name)
  end

  private

  def user
    represented.user
  end

  def roster
    represented.playable
  end

  def team
    roster.team
  end
end