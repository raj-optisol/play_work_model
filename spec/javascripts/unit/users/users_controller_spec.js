'use strict';

describe("Users Controllers", function (){

  var ctrl, scope, currUser, userFactory, httpBackend;
  beforeEach(function(){ 
    angular.mock.module('user.controllers');
    angular.module('user.services');
    angular.mock.module('app.services');
    angular.mock.module('organization.directives');      
    angular.module('services.authentication.currentUser');      
    angular.module('cloudinary.services');      
  });

  describe('UsersCtrl', function(){

    beforeEach(inject(function($rootScope, $controller, $httpBackend, currentUser, $compile) {
      scope = $rootScope.$new();
      currUser = currentUser;
      httpBackend = $httpBackend;
      currUser.update({id:123, firstName: 'Fred', lastName:'Flinstone'});
      ctrl = $controller('UsersCtrl', {
        $scope: scope
      });

    }));

    it("should set the url", function() {
      expect(scope.url).toBe('/users.json'); 
    } );

    it("should set the currentUser", function() {
      expect(scope.currentUser.info()).toBe(currUser.info());
    });

    it("default status value to All", function() {
        expect(scope.statusValue).toBe("all"); 
    });

    it("default search text to null", function() {
        expect(scope.filter).toEqual({}); 
    });

    describe("filterOptions", function() {
      var userResponse;
      beforeEach(function() {
        userResponse = [
          {id: 123, email: 'fred@flintstone.com', first_name: 'Fred', last_name: 'Flintstone', kind: 'registrar', kyck_id: '345', permission_sets:["ManageUSCSStaff"]},
          {id: 456, email: 'wilma@flintstone.com', first_name: 'Wilma', last_name: 'Flintstone', kind: 'user', kyck_id: '4555', permission_sets:[]}
        ];
        scope.filter = {};
        scope.statusValue = "test";
        scope.filter.last_name='smith';
      }); 

      it("should set the filterOptions" , function() {
        scope.filterRequest();
        expect(scope.filterOptions.last_name_like).toBe("smith");
        expect(scope.filterOptions.kind).toBe("test");
      });

      describe("when no search text is entered", function() {
        it("should not populate search text filter option", function() {
          scope.filter.last_name=null;
          scope.filterRequest();
          expect(scope.filterOptions.last_name_like).toBeNull();
        });
      });

      describe("when status is changed", function() {
        it("should use that value", function() {
          scope.filter.last_name=null;
          scope.statusValue="registrar";
          scope.filterRequest();
          expect(scope.filterOptions.kind).toBe("registrar");
        });
      });
    });


  });

  describe("UserCtrl", function() {
    beforeEach(inject(function($rootScope, $controller, User, currentUser,  $compile) {
      scope = $rootScope.$new();
      currUser = currentUser;
      userFactory = User;
      currUser.update({id:123, firstName: 'Fred', lastName:'Flinstone'});
      ctrl = $controller('UserCtrl', {
        $scope: scope,
        cloudinary_factory: {getUploadAttrs: function() {}}

      });
    }));

    it("should create an empty user", function(){
      expect(scope.user).toBeDefined();
    });

    describe("setUser", function() {

      it("should set the user with the passed in object properties", function() {
        var props = {email: 'test@test.com', first_name: 'Test', last_name: 'Test'};
        scope.setUser(props);
        expect(scope.user.first_name).toBe('Test');
      });
    });

    describe("submitForm", function() {
      var ev, mockForm;
      beforeEach(function() {
        mockForm = {$invalid: function(){}};
        scope.userForm = mockForm;
        ev = {preventDefault: function(){}};
      });

      it("should set hasSubmitted to true", function(){
        sinon.stub(mockForm, "$invalid").returns(false);
        scope.submitForm(ev);
        expect(scope.hasSubmitted).toBe(true);
      });

      describe("when the form is invalid", function() {
        beforeEach(function() {
          sinon.stub(mockForm, "$invalid").returns(false);
        });

        it("should not submit the form", function(){
          var spy = sinon.spy(ev, "preventDefault");
          scope.submitForm(ev);
          expect(spy.calledOnce).toBe(true);
        });
      }); 

      describe("when the form is valid", function() {
        beforeEach(function() {
          sinon.stub(mockForm, "$invalid").returns(false);
        });

      });
    });

  });
});
