module Test
  module RoleRepository
    # extend Edr::AR::Repository
    # set_model_class Role
    
    @roles = [
      { :name => 'USCSSuperAdmin', :kind => 'uscs', :permission_sets => ['ManageMoney', 'RunFinancialReport', 'ManageRequest', 'ManageUSCSStaff', 'RunReport', 'ManageOrganization', 'ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster'] },
      { :name => 'USCSAdmin', :kind => 'uscs', :permission_sets => ['ManageRequest', 'ManageUSCSStaff', 'RunReport', 'ManageOrganization', 'ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster'] },      
      { :name => 'USCSRepresentative', :kind => 'uscs', :permission_sets => ['ManageOrganization', 'ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster'] },      
      { :name => 'Registrar', :kind => 'all', :permission_sets => ['ManageOrganization', 'ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster'] },
      { :name => 'OrganizationAdmin', :kind => 'all', :permission_sets => ['ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster'] },
      { :name => 'TeamAdmin', :kind => 'all', :permission_sets => ['ManagePlayer', 'ManageRoster'] },      
      { :name => 'ManageCards', :kind => 'all', :permission_sets => ['PrintPlayerCard', 'RequestPlayerCard'] }      
    ]

    def self.find_by_name(name)
      
    end
    
    def self.all()
      @roles
    end
  
    def self.find_by_kind(kind)
      @roles.select {|item| item[:kind]==kind }
    end
    
  end
end
