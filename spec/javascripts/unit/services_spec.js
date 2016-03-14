describe("parentOrganization", function(){

  var subject;
  beforeEach(function(){
    angular.mock.module("app.services"); 
  });

  beforeEach(inject(function(parentOrganization){
    subject = parentOrganization;
  }));

  it("should be null at first", function(){
    expect(subject.value()).toEqual({name: null, id: null}); 
  });

  it("should allow the setting of parent value", function(){
    subject.update('organizations', 4);
    expect(subject.value().name).toBe('organizations');
    expect(subject.value().id).toBe(4);
  });

  describe("updateFromPath", function(){
    it("should parse the org id from the provided URL", function(){
      subject.updateFromPath('/organizations/23');
      expect(subject.value().id).toBe('23');
      subject.updateFromPath('/organizations/51362d8d-cb82-4462-a084-361364d152ec/staff');
      expect(subject.value().id).toEqual('51362d8d-cb82-4462-a084-361364d152ec');
    }); 

      it("should have no value for /organizations", function() {
        subject.updateFromPath('/organizations');
        expect(subject.hasValue()).toBeFalsy();
      });
      
      it("should have no value for /organizations/", function() {
        subject.updateFromPath('/organizations/');
        expect(subject.hasValue()).toBeFalsy();
      });

  });

});
