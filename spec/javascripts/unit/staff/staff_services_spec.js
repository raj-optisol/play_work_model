describe("Staff", function() {

  var http, staff, orgFactory;
  
  beforeEach(function(){
    angular.mock.module('staff.services');
  });

  beforeEach(inject(function(Staff, $httpBackend) {
    staff = Staff;
    http = $httpBackend;
  }));

  describe("query", function() {
    beforeEach(inject(function($httpBackend) {
      http.expectGET('/organizations/1/staff').respond([{id: 1, first_name: 'Fred', last_name: 'Flintstone', email: 'fred@flintstone.com', phone: '704-555-5555', website: 'http://bedrockisp.com/fred', title: 'Coach', address:'123 Main ST', state: 'NC', zipcode: '22222'}]); 
    }));

    it("should make the right call", function() {
      staff.query({org_id: 1});
    });

  });
});
