'use strict';

describe("OrganizationsCtrl", function() {

  var scope, mockParentOrg, mockOrg;

  beforeEach(module("App"));

  beforeEach(inject(function($controller, $rootScope) {
    scope = $rootScope.$new();
    scope.filterOptions = {};
    mockParentOrg = {hasValue: function(){},
      value: function() {return{name: 'Charlotte', id: 5};}};
  mockOrg = {};
  var ctrl = $controller("OrganizationsCtrl",
    {$scope: scope, 'Organization': mockOrg, 'parentOrganization': mockParentOrg});
  }));


  it('sets orgData to an Organization', function() {
    expect(scope.orgData).toBe(mockOrg);
  });

  it('sets statusTypes correctly', function() {
    expect(scope.statusTypes.length).toEqual(4);
  });	

  it('properly defines url', function() {
    expect(scope.url).toContain('/organizations.json');
  });


  it('has a filter', function() {
    expect(scope.filter).toBeDefined();
  });

  it('has properly defined columnDefs', function() {
    expect(scope.columnDefs).toBeDefined();
    expect(scope.columnDefs.length).toEqual(5);
  });

  it('filterRequest sets filterOptions', function () {
    scope.filter = {kind: 'Nachos', name: 'Fred', status: 'Available'};
    scope.filterRequest();
    expect(scope.filterOptions.name_like).toBe(scope.filter.name);
    expect(scope.filterOptions.kind).toBe(scope.filter.kind);
  });

  describe('parentOrg hasValue', function() {
    beforeEach(inject(function($controller, $rootScope) {
      scope = $rootScope.$new();
      mockParentOrg = {hasValue: function(){return true},
        value: function() {return{name: 'Charlotte', id: 5};}};
    mockOrg = {};
    var ctrl = $controller("OrganizationsCtrl",
      {$scope: scope, 'Organization': mockOrg, 'parentOrganization': mockParentOrg});
    }));

    it('propery defines url when parentOrg hasValue', function() {
      expect(scope.url).toContain('/Charlotte/5');
    });
  });
});

describe("OrganizationCtrl", function() {

  var scope, $controllerConstructor, mockOrg, mockStates;

  beforeEach(module("App", 'organization'));

  beforeEach(inject(function($controller, $rootScope, Organization) {
    scope = $rootScope.$new();
    mockStates = {};
    mockOrg = {};
    var ctrl = $controller("OrganizationCtrl",
      {$scope: scope, 'states': mockStates});
  }));

  it('has an org', function() {
    expect(scope.organization).toBeDefined();
  });

  it('has states', function() {
    expect(scope.states).toBeDefined();
  });

  it('has leagueTypes', function() {
    expect(scope.leagueTypes).toBeDefined();
    expect(scope.leagueTypes.length).toEqual(4);
  });

  it('has statusTypes', function() {
    expect(scope.statusTypes).toBeDefined();
    expect(scope.statusTypes.length).toEqual(4);
  });

  it('fills the years array', function() {
    var dt = new Date();
    var startYear = dt.getFullYear();
    expect(scope.years.length).toEqual(10);
    expect(scope.years[0].value).toBe(startYear);
    expect(scope.years[1].value).toBe(startYear+1);
  });

  it('has contact titles', function() {
    expect(scope.contactTitle).toBeDefined();
    expect(scope.contactTitle.length).toEqual(3);
  });

});
