'use strict';

describe("Teams Controllers", function (){

  var ctrl, scope, currUser, teamFactory, httpBackend, orgId;
  beforeEach(function(){ 
    angular.mock.module('team.controllers');
    angular.mock.module('team.services');
    angular.mock.module('app.services');
    angular.mock.module('organization.directives');      
    angular.mock.module('organization.services');      
    angular.mock.module('season.services');      
    angular.module('services.authentication.currentUser');      

  });

  describe('TeamsIndexCtrl', function(){

    describe("when organizationId has a value", function(){
      beforeEach(inject(function($rootScope, $controller, $httpBackend, Team, currentUser, organizationId, seasonId, $compile) {
        scope = $rootScope.$new();
        currUser = currentUser;
        orgId = organizationId ;
        orgId.update(4); 
        seasonId = organizationId ;
        seasonId.update(4); 
        httpBackend = $httpBackend;
        currUser.update({id:123, firstName: 'Fred', lastName:'Flinstone'});
        ctrl = $controller('TeamsIndexCtrl', {
          $scope: scope
        });

      }));

      it("should set the url", function(){
        expect(scope.url).toBe(document.location.pathname+".json"); 
      }); 
    });

    describe("when the organziationId is not set",function(){

      beforeEach(inject(function($rootScope, $controller, $httpBackend, Team, currentUser, organizationId, $compile) {
        scope = $rootScope.$new();
        currUser = currentUser;
        orgId = organizationId ;
        httpBackend = $httpBackend;
        currUser.update({id:123, firstName: 'Fred', lastName:'Flinstone'});
        ctrl = $controller('TeamsIndexCtrl', {
          $scope: scope
        });

      }));

      it("should set the url", function() {
        expect(scope.url).toBe(document.location.pathname + '.json'); 
      } );

      it("should set the currentUser", function() {
        expect(scope.currentUser.info()).toBe(currUser.info());
      });

      it("default filter to empty", function() {
        expect(scope.filter).toEqual({}); 
      });

      describe("filterRequest", function() {
        var teamResponse;
        beforeEach(function() {
          scope.filter={};
        }); 


        it("should set the filterOptions" , function() {
          scope.filter.name='Fred';
          scope.filterRequest();
          expect(scope.filterOptions.name_like).toBe("Fred");
        });

        describe("when no search text is entered", function() {
          it("should not populate search text filter option", function() {
            scope.filter.name = null;
            scope.filterRequest();
            expect(scope.filterOptions.name_like).toBeNull();
          });
        });

      });

    });

  });

  describe("TeamCtrl", function() {
    beforeEach(inject(function($rootScope, $controller, Team, currentUser, $compile) {
      scope = $rootScope.$new();
      currUser = currentUser;
      teamFactory = Team;
      currUser.update({id:123, firstName: 'Fred', lastName:'Flinstone'});
      ctrl = $controller('TeamCtrl', {
        $scope: scope,
        cloudinary_factory: {getUploadAttrs: function() {}}
      });
    }));

    it("should create an empty user", function(){
      expect(scope.team).toBeDefined();
    });

  });


});
