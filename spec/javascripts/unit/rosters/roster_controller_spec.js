'use strict';

describe("Rosters Controllers", function (){

  var ctrl, scope, currUser, rosterFactory, httpBackend, teamId, orgId;
  beforeEach(function(){ 
    angular.mock.module('roster.controllers');
    angular.mock.module('roster.services');
    angular.mock.module('player.services');
    angular.mock.module('app.services');
    angular.mock.module('team.services');      
    angular.module('services.authentication.currentUser');      

  });

  describe('RostersIndexCtrl', function(){

    describe("when teamId has a value", function(){
      beforeEach(inject(function($rootScope, $controller, $httpBackend, Roster, currentUser, teamId, $compile) {
        scope = $rootScope.$new();
        currUser = currentUser;
        teamId = teamId ;
        teamId.update(4); 
        httpBackend = $httpBackend;
        currUser.update({id:123, firstName: 'Fred', lastName:'Flinstone'});
        ctrl = $controller('RostersIndexCtrl', {
          $scope: scope
        });

      }));

      it("should set the url", function(){
        expect(scope.url).toBe("/teams/4/rosters.json"); 
      }); 
    });

    describe("when the teamId is not set",function(){

      beforeEach(inject(function($rootScope, $controller, $httpBackend, Roster, currentUser, teamId, $compile) {
        scope = $rootScope.$new();
        currUser = currentUser;
        teamId = teamId ;
        httpBackend = $httpBackend;
        currUser.update({id:123, firstName: 'Fred', lastName:'Flinstone'});
        ctrl = $controller('RostersIndexCtrl', {
          $scope: scope
        });

      }));

      it("should set the url", function() {
        expect(scope.url).toBe('/rosters.json'); 
      } );

      it("should set the currentUser", function() {
        expect(scope.currentUser.info()).toBe(currUser.info());
      });

      describe("filterRequest", function() {
        var teamResponse;
        beforeEach(function() {
          scope.searchText = "test";
        }); 


        it("should set the filterOptions" , function() {
          scope.filterRequest();
          expect(scope.filterOptions.name_like).toBe("test");
        });

        describe("when no search text is entered", function() {
          it("should not populate search text filter option", function() {
            scope.searchText=null;
            scope.filterRequest();
            expect(scope.filterOptions.name_like).toBeNull();
          });
        });

      });

    });

  });

  describe("RosterCtrl", function() {
    var playerResponse, rosterResponse;
    beforeEach(inject(function($rootScope, $controller, Roster, currentUser, teamId, rosterId, $httpBackend, $compile) {
      scope = $rootScope.$new();
      currUser = currentUser;
      rosterFactory = Roster;
      httpBackend = $httpBackend;
      currUser.update({id:123, firstName: 'Fred', lastName:'Flinstone'});

      teamId = teamId;
      teamId = teamId.update(4);

      rosterId = rosterId;
      rosterId.update(1);
      playerResponse = [{id:123, first_name: 'Pebbles', last_name: 'Flintstone', gender: 'F', birthdate:'01/06/2000'}, {id:456, first_name: 'BamBam', last_name: 'Rubble', gender: 'M', birthdate:'01/06/2001'}];
      
      rosterResponse = {id: 1, name: 'The Roster', players: playerResponse};
      httpBackend.when('GET', '/teams/4/rosters/1').respond(rosterResponse);
      httpBackend.when('GET', '/teams/4/players').respond(playerResponse);

      ctrl = $controller('RosterCtrl', {
        $scope: scope
      });

    }));

    it("should create an empty roster", function(){
      expect(scope.roster).toBeDefined();
    });

    it("should get the team players", function(){
      httpBackend.flush();
      expect(scope.availablePlayers.length).toEqual(2);
    });

    describe("Searching for players", function(){
      beforeEach(function(){
        httpBackend.expect('GET', '/teams/4/players?filter%5Blast_name_like%5D=Smith').respond([{id: 333, first_name: 'Bob', last_name: 'Smith', gender: 'M', birthdate: '01.07/2004'}]);
      }); 

      it("searches the open roster", function(){
        scope.searchText="Smith";
        scope.filterPlayers();
        httpBackend.flush();
      });

      it("sets the available players", function() {
        scope.searchText="Smith";
        scope.filterPlayers();
        httpBackend.flush();
        expect(scope.availablePlayers.length).toEqual(1);
      });
    });

  });
});
