'use strict';

describe("Cards Controllers", function (){

  var ctrl, scope, currUser, teamFactory, httpBackend, orgId;
  beforeEach(function(){ 
    angular.mock.module('card.controllers');
    angular.mock.module('card.services');
    angular.mock.module('card_request.services');
    angular.mock.module('team.services');
    angular.mock.module('app.services');
    angular.mock.module('gridColumn.services');

  });

  describe('CardsCtrl', function(){
      beforeEach(inject(function($rootScope, $controller, $httpBackend, Team, $compile) {
        scope = $rootScope.$new();
        teamFactory = Team;
        httpBackend = $httpBackend;
        ctrl = $controller('CardsCtrl', {
          $scope: scope
        });

      }));

    describe("selectTeam", function(){
      
      it("sets the team id on the filter", function(){

        scope.selectTeam(null, {item:{id: '1234'}});
        expect(scope.filter.team_id).toBe("1234");
      });
    });


  });


});
