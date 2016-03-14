'use strict';

describe("Staff Controllers", function (){

  var ctrl, scope, currUser, staffFactory, httpBackend, parentService;
  beforeEach(function(){ 
    angular.mock.module('staff.controllers');
    angular.mock.module('staff.services');
    angular.mock.module('app.services');
    angular.mock.module('organization.directives');      
    angular.mock.module('organization.services');      
    angular.module('services.authentication.currentUser');      

  });

  describe('StaffIndexCtrl', function(){

    describe("when parent has a value", function(){
      beforeEach(inject(function($rootScope, $controller, $httpBackend, Staff, currentUser, parentOrganization, $compile) {
        scope = $rootScope.$new();
        currUser = currentUser;
        parentService = parentOrganization ;
        parentService.update("organizations", 4); 
        httpBackend = $httpBackend;
        currUser.update({id:123, firstName: 'Fred', lastName:'Flinstone'});
        ctrl = $controller('StaffIndexCtrl', {
          $scope: scope
        });

      }));

      it("should set the url", function(){
        expect(scope.url).toBe(document.location.pathname + ".json"); 
      }); 
    });

    describe("when the parent organization is not set",function(){

      beforeEach(inject(function($rootScope, $controller, $httpBackend, Staff, currentUser, parentOrganization, $compile) {
        scope = $rootScope.$new();
        currUser = currentUser;
        httpBackend = $httpBackend;
        parentService = parentOrganization;
        parentService.update(null,null);
        currUser.update({id:123, firstName: 'Fred', lastName:'Flinstone'});
        ctrl = $controller('StaffIndexCtrl', {
          $scope: scope
        });

      }));

      it("should set the url", function() {
        expect(scope.url).toBe(document.location.pathname + '.json'); 
      } );

      it("should set the currentUser", function() {
        expect(scope.currentUser.info()).toBe(currUser.info());
      });

      it("set team value to undef", function() {
        expect(scope.teamValue).toBeUndefined; 
      });

      it("set org value to null", function() {
        expect(scope.orgValue.value().name).toBeNull();
        expect(scope.orgValue.value().id).toBeNull(); 
      });

      it("default search text to null", function() {
        expect(scope.searchText).toBeNull(); 
      });

      describe("selectOrg", function(){
        it("should set the orgValue", function(){
          var selOrg = {item: {id: 22, name:'Cloob'}};
          scope.selectOrg(null, selOrg ) ;
          expect(scope.orgValue).toBe(22);
        }); 
      });

      describe("filterRequest", function() {
        var staffResponse;
        beforeEach(function() {
          staffResponse = [
        {id: 123, email: 'fred@flintstone.com', first_name: 'Fred', last_name: 'Flintstone', kind: 'registrar', permission_sets:["ManageUSCSStaff"]},
          {id: 456, email: 'wilma@flintstone.com', first_name: 'Wilma', last_name: 'Flintstone', kind: 'user', permission_sets:[]}
        ];
        scope.orgValue = {hasValue: function(){return true;}, value: function() {return {name: 'organizations', id: 1 }}};
        scope.filter = {last_name: 'Smith'}
        }); 

        it("should set the filterOptions" , function() {
          scope.filterRequest();
          expect(scope.filterOptions.last_name_like).toBe("Smith");
        });

        describe("when no search text is entered", function() {
          it("should not populate search text filter option", function() {
            scope.filter = {};
            scope.filterRequest();
            expect(scope.filterOptions.last_name_like).toBeUndefined();
          });
        });


      });

    });

  });

  describe("StaffCtrl", function() {
    beforeEach(inject(function($rootScope, $controller, Staff, currentUser, $compile) {
      scope = $rootScope.$new();
      currUser = currentUser;
      staffFactory = Staff;
      currUser.update({id:123, firstName: 'Fred', lastName:'Flinstone'});
      ctrl = $controller('StaffCtrl', {
        $scope: scope
      });
    }));

//    it("should create an empty user", function(){
//      expect(scope.staff).toBeDefined();
//    });

  });


});
