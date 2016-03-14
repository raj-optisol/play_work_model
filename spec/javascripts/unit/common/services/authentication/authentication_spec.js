describe('authentication', function() {

  var $rootScope, $httpBackend, $http, userResponse, service, currentUser, queue;

  beforeEach(module('services.authentication', 'ng'));
  beforeEach(inject(function(_$rootScope_, _$httpBackend_, _$http_){
    $rootScope = _$rootScope_;
    $httpBackend = _$httpBackend_;
    $http = _$http_;
   
    userResponse = {id: 123, email: 'fred@flintstone.com', first_name: 'Fred', last_name: 'Flintstone'};

    $httpBackend.when('GET', '/profile.json').respond(200, userResponse);

  }));


  beforeEach(inject(function($injector){
    service = $injector.get('authentication');
    currentUser = $injector.get('currentUser');
    queue = $injector.get('authenticationRetryQueue');
  }));

  // TODO: Need to add logout?

  describe('authentication guards', function(){
    var resolved;
    beforeEach(function(){
      resolved = false; 
    });

    describe('requestCurrentUser', function(){
      it('makes a GET request to profile url', function(){
        expect(currentUser.isAuthenticated()).toBe(false); 
        $httpBackend.expect('GET', '/profile.json');
        service.requestCurrentUser().then(function(data){
          resolved = true;
          expect(currentUser.isAuthenticated()).toBe(true);
          expect(currentUser.info()).toBe(userResponse);
        });
        $httpBackend.flush();
        expect(resolved).toBe(true);
      }); 

      it("returns the current user immediately if they are already authenticated", function(){
        var userInfo = {id: 1};
        currentUser.update(userInfo);
        expect(currentUser.isAuthenticated()).toBe(true);
        service.requestCurrentUser().then(function(data){
          resolved = true;
          expect(currentUser.info()).toBe(userInfo);
        });

        $httpBackend.flush();
        expect(resolved).toBe(true);
      });
    });
     
  
  });
});
