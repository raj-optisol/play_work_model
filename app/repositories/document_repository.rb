module DocumentRepository
  extend Edr::AR::Repository
  extend CommonFinders::OrientGraph
  set_model_class Document

  # This is called to get a waiver for the user and org
  # Probably will do more stuff later
  def self.get_documents_for_user_and_organziation(user, org)
    gp = start_query_with(user)

    gp.out(UserData.relationship_label_for(:documents)).filter {|it| it.in(OrganizationData.relationshp_label_for(:documents)).count > 0}

    gp.to_a.map {|d| wrap d.wrapper}
  end


end
