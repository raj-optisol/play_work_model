angular.module("card.services", ["ngResource"] ).
  factory('Card', ["$resource", function($resource) {
  return  $resource('/:org_kind/:org_id/cards/:id', {org_kind: '@org_kind', org_id: '@org_id', id: "@id"},
                    {
                      update:  {method: 'PUT'},
                      approve: { params:{action:'approve'},method: 'POST'}
                    });
}]);
