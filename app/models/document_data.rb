class DocumentData < BaseModel::Data
  include Symbolize::ActiveRecord

  property :title
  property :file_name
  property :status, default: :not_reviewed
  property :kind, default: :other
  property :url
  property :last_reviewed_by
  property :last_reviewed_on, type: Fixnum

  validates :title, presence: true

  has_one(:owner).to(UserData)
  has_one(:organization).to(OrganizationData)
  has_n(:cards).to(CardData)


  symbolize :status, in: [:approved, :not_reviewed, :expired]
  symbolize :kind, in: [:waiver, :proof_of_birth, :background_check, :other]

  def last_reviewer
    UserRepository.find(kyck_id: last_reviewed_by) if last_reviewed_by
  end

  def remove_owner
    own = self.owner
    rt = self.class._rels[:owner]
    vi = self._create_or_get_vertex_instance_for_decl_rels(rt)
    vi.destroy_relationship
    own
  end

end
