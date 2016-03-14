describe("User", function() {

  var http, user;
  beforeEach(angular.mock.module('user.services'))

  beforeEach(inject(function(User, $httpBackend) {
    user = User;
    http = $httpBackend;
  }));

  describe("query", function() {
    beforeEach(inject(function($httpBackend) {
      http.expectGET('/users').respond([{id: 1, first_name: 'Fred', last_name: 'Flintstone'}]); 
    }));

    it("should make the right call", function() {
      user.query();
    });

  });
});
