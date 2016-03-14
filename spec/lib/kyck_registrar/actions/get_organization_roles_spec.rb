require 'spec_helper'
require_relative '../repositories/role_repository'
require_relative '../../../../lib/kyck_registrar/actions/get_organization_roles'

describe KyckRegistrar::Actions::GetOrganizationRoles, broken: true do

  context 'user has permission' do
    it 'should retrieve all roles for USCS SuperAdmin when within USCS organization' do
    
      u = User.build(email: 'uscsstaff@test.com', first_name: 'First', last_name: 'Last')  
      u.permission_sets = ['ManageRequest', 'ManageUSCSStaff', 'RunReport', 'ManageOrganization', 'ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster', "PrintPlayerCard", "RequestPlayerCard"]

      action = KyckRegistrar::Actions::GetOrganizationRoles.new u, nil
      action.role_repository = Test::RoleRepository
      result = action.execute 
      result.should eq [
        { :name => 'USCSAdmin', :kind => 'uscs', :permission_sets => ['ManageRequest', 'ManageUSCSStaff', 'RunReport', 'ManageOrganization', 'ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster'] },      
        { :name => 'USCSRepresentative', :kind => 'uscs', :permission_sets => ['ManageOrganization', 'ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster'] },      
        { :name => 'Registrar', :kind => 'all', :permission_sets => ['ManageOrganization', 'ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster'] },
        { :name => 'OrganizationAdmin', :kind => 'all', :permission_sets => ['ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster'] },
        { :name => 'TeamAdmin', :kind => 'all', :permission_sets => ['ManagePlayer', 'ManageRoster'] },      
        { :name => 'ManageCards', :kind => 'all', :permission_sets => ['PrintPlayerCard', 'RequestPlayerCard'] }
      ]
  
    end
  
    it 'should retrieve all roles for USCS admin when within Test Organization' do
      u = User.build(email: 'uscsstaff@test.com', first_name: 'First', last_name: 'Last')  
      u.permission_sets = ['ManageRequest', 'ManageUSCSStaff', 'RunReport', 'ManageOrganization', 'ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster', "PrintPlayerCard", "RequestPlayerCard"]
      o = Organization.build(kind: 'Club', name: 'Test Club')
      # o.add_staff(u, "Registrar", ['ManageStaff'])
      # OrganizationRepository.persist o
    
      action = KyckRegistrar::Actions::GetOrganizationRoles.new u, o
      action.role_repository = Test::RoleRepository
      result = action.execute
      result.should eq [
        { :name => 'Registrar', :kind => 'all', :permission_sets => ['ManageOrganization', 'ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster'] },
        { :name => 'OrganizationAdmin', :kind => 'all', :permission_sets => ['ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster'] },
        { :name => 'TeamAdmin', :kind => 'all', :permission_sets => ['ManagePlayer', 'ManageRoster'] },      
        { :name => 'ManageCards', :kind => 'all', :permission_sets => ['PrintPlayerCard', 'RequestPlayerCard'] }
      ]
  
    end
  
    it 'should retrieve all roles for registrar with ManageCard abilities' do
      u = User.build(email: 'registrar@test.com', first_name: 'First', last_name: 'Last')  
      u.permission_sets = ['ManageOrganization', 'ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster', "PrintPlayerCard", "RequestPlayerCard"]
      o = Organization.build(kind: 'Club', name: 'Test Club')
    
      action = KyckRegistrar::Actions::GetOrganizationRoles.new u, o
      action.role_repository = Test::RoleRepository
      result = action.execute
    
      result.should eq [
        { :name => 'Registrar', :kind => 'all', :permission_sets => ['ManageOrganization', 'ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster'] },
        { :name => 'OrganizationAdmin', :kind => 'all', :permission_sets => ['ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster'] },
        { :name => 'TeamAdmin', :kind => 'all', :permission_sets => ['ManagePlayer', 'ManageRoster'] },      
        { :name => 'ManageCards', :kind => 'all', :permission_sets => ['PrintPlayerCard', 'RequestPlayerCard'] }
      ]
    end
  
    it 'should retrieve all roles for Organization Admin with no' do
      u = User.build(email: 'registrar@test.com', first_name: 'First', last_name: 'Last')  
      u.permission_sets = ['ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster']
      o = Organization.build(kind: 'Club', name: 'Test Club')
    
      action = KyckRegistrar::Actions::GetOrganizationRoles.new u, o
      action.role_repository = Test::RoleRepository
      result = action.execute
    
      result.should eq [
        { :name => 'OrganizationAdmin', :kind => 'all', :permission_sets => ['ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster'] },
        { :name => 'TeamAdmin', :kind => 'all', :permission_sets => ['ManagePlayer', 'ManageRoster'] }
      ]
    end
  end
  
  context 'user does not have permission' do
    it 'should not retrieve any roles' do
      u = User.build(email: 'registrar@test.com', first_name: 'First', last_name: 'Last')  
      u.permission_sets = ['ManageTeam', 'ManagePlayer', 'ManageRoster']
      o = Organization.build(kind: 'Club', name: 'Test Club')
    
      action = KyckRegistrar::Actions::GetOrganizationRoles.new u, o
      action.role_repository = Test::RoleRepository
      result = action.execute
    
      result.should eq []
    end
    
  end

end
