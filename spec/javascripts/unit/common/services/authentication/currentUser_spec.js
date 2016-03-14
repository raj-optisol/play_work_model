describe("currentUser", function() {

  beforeEach(module('services.authentication.currentUser'));

  it("should be unauthenticated to begin with", function(){
    inject(function(currentUser) {
      expect(currentUser.isAuthenticated()).toBe(false);
      expect(currentUser.isAdmin()).toBe(false);
      expect(currentUser.info()).toBe(null);
    }); 
  });

  it("should be authenticated if we update the user info", function(){
    inject(function(currentUser) {
      var userInfo = {id: 1};
      currentUser.update(userInfo);
      expect(currentUser.isAuthenticated()).toBe(true);
      expect(currentUser.isAdmin()).toBe(false);
      expect(currentUser.info()).toBe(userInfo);
    }); 
  });

  it("should be admin if we update with admin user info", function(){
    inject(function(currentUser) {
      var userInfo = {id: 1, admin: true};
      currentUser.update(userInfo);
      expect(currentUser.isAuthenticated()).toBe(true);
      expect(currentUser.isAdmin()).toBe(true);
      expect(currentUser.info()).toBe(userInfo);
    }); 
  }); 

  it("should be not be authenticated or admin if we clear the user", function(){
    inject(function(currentUser) {
      var userInfo = {id: 1, admin: true};
      currentUser.update(userInfo);
      expect(currentUser.isAuthenticated()).toBe(true);
      expect(currentUser.isAdmin()).toBe(true);
      expect(currentUser.info()).toBe(userInfo);
      currentUser.clear();

      expect(currentUser.isAuthenticated()).toBe(false);
      expect(currentUser.isAdmin()).toBe(false);
      expect(currentUser.info()).toBe(null);
    }); 
  }); 

});
