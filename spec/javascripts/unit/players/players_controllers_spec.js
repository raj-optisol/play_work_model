describe("Players Controllers", function() {

  describe("PlayersController", function() {
 
    var ctrl, scope, orgId, vUser;
    beforeEach(function() {
      angular.mock.module("player.controllers"); 
      angular.mock.module("player.services"); 
      angular.mock.module("gridColumn.services"); 
      angular.mock.module("user.services"); 

    }); 

    beforeEach(inject(function($controller, $rootScope, parentOrganization, RosterPlayer, User, columnService){
      scope = $rootScope.$new();
      orgId = parentOrganization; 
      vUser = User;
      orgId.update("seasons", 4);

      ctrl = $controller("PlayersCtrl",{
        $scope: scope,
        RosterPlayer: RosterPlayer,
        User: User,
        columnService: columnService
      } );

      var playerResponse = [ {first_name: 'Bob', last_name: 'Newhart', gender: 'M', birtdate:'01/01/2004'} ];
    }));

    it("have a url", function() {
      expect(scope.url).toEqual("");
    });
  });

  describe("PlayerCtrl", function() {
  
    var ctrl, scope, vUser;
    beforeEach(function() {
      angular.mock.module("player.controllers"); 
      angular.mock.module("player.services"); 
      angular.mock.module("gridColumn.services"); 
      angular.mock.module("user.services"); 

    }); 

    beforeEach(inject(function($controller, $rootScope, Player, User){
      scope = $rootScope.$new();
      vUser = User;
      ctrl = $controller("PlayerCtrl",{
        $scope: scope,
        Player: Player,
        User: User
      } );

    }));

    describe("searchUsers", function() {
   
      describe("when there is no email", function() {
        beforeEach(function() {
          scope.player = {user: {first_name: 'Fred', last_name: 'Flintstone'}};
        });

        it("doesn't search", function() {
          var spy = sinon.spy(vUser, "query")
          scope.searchUsers();
          expect(vUser.query.neverCalledWith()).toBe(true);
        });
      });

      describe("when there is an email", function() {
        beforeEach(function() {
          scope.player = {user: {first_name: 'Fred', last_name: 'Flintstone', email:'fred@fred.com'}};
        });

        it("does search", function() {
          var spy = sinon.spy(vUser, "query")
          scope.searchUsers();
          expect(vUser.query.calledOnce).toBe(true);
        });
      });
    });
  })

});
