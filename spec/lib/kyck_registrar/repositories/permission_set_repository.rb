module Test
  module PermissionSetRepository
    # extend Edr::AR::Repository
    # set_model_class PermissionSet

    @permissions = [{:name => 'ManageMoney', :description => 'Can Manage Fees and commission', :kind => 'uscs'},
      {:name => 'ManageRequest', :description => 'Can Manage all organization requests', :kind => 'uscs'},
      {:name => 'RunFinancialReport', :description => 'Can run reports dealing with money', :kind => 'uscs'},            
      {:name => 'RunReport', :description => 'Can run all other reports', :kind => 'uscs'},      
      {:name => 'ManageOrganization', :description => 'Can manage organizationa the user is associated with', :kind => 'all'},
      {:name => 'ManageStaff', :description => 'Can Manage staff for organizations that user is accociated with', :kind => 'all'},                  
      {:name => 'ManageTeam', :description => 'Can Manage teams for organizations that user is accociated with', :kind => 'all'},
      {:name => 'ManagePlayer', :description => 'Can Manage players on teams that user is accociated with', :kind => 'all'},
      {:name => 'ManageRoster', :description => 'Can Manage roster for teams that user is accociated with', :kind => 'all'},                  
      {:name => 'RequestPlayerCard', :description => 'Can request player cards', :kind => 'all'},      
      {:name => 'PrintPlayerCard', :description => 'Can print player cards', :kind => 'all'}
    ]
    def self.find_by_name(name)

    end
  
    def self.find_by_kind(name)
    
    end
  
  end
end