describe("organizationId", function(){

  var subject;
  beforeEach(function(){
    angular.mock.module("organization.services"); 
  });

  beforeEach(inject(function(organizationId){
    subject = organizationId;
  }));

  it("should be null at first", function(){
    expect(subject.value()).toBeNull(); 
  });

  it("should allow the setting of organization id value", function(){
    subject.update(4);
    expect(subject.value()).toBe(4);
  });

  describe("updateFromPath", function(){
    it("should parse the org id from the provided URL", function(){
      expect(subject.updateFromPath('/organizations/23')).toBe('23');
      expect(subject.value()).toBe('23');
      expect(subject.updateFromPath('/organizations/51362d8d-cb82-4462-a084-361364d152ec/staff')).toBe('51362d8d-cb82-4462-a084-361364d152ec');
      expect(subject.value()).toBe('51362d8d-cb82-4462-a084-361364d152ec');
    }); 

  });

});
