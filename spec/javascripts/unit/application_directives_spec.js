'use strict';

describe("Common Directives", function (){

  var ctrl, scope, currUser, userFactory, httpBackend;

  beforeEach( function() {
    angular.mock.module("App");
    angular.mock.module("directives")
  });

  describe('Grid', function(){

    var ctrl, gscope, scope, httpMock, elm;

    beforeEach(inject(function($rootScope, $controller, $httpBackend, $compile) {
      scope = $rootScope.$new();
      httpMock = $httpBackend;
      httpMock.when('GET', '/users?page=1&per_page=30').respond([{first_name: 'Fred', last_name: 'Flintstone', email:'fred@flintstone.com', id: 1}, {first_name: 'Barney', last_name: 'Rubble', email: 'barney@idigwilma.com', id: 2}]);           

      scope.url = '/users';

      elm = angular.element('<div class="mygrid" grid-data="users"></div>');
      $compile(elm)(scope);
      scope.$digest();

      var ng = elm.find('.ngGrid');
      gscope = angular.element(ng).scope();

      httpMock.flush();

    }));

    it("should have 2 users", function() {
      expect(scope.users.length).toBe(2); 
    });

    it("should have 4 headers", function() {
      expect(elm.find('.ngHeaderCell').length).toBe(4); 
    });


    it("should have 2 rows", function() {
      expect(gscope.renderedRows.length).toBe(2); 
    });
  });

  //    it("should have 1 row", function() {
  //      httpMock.when('GET', '/users?page=1&per_page=1').respond([{id: 1, first_name: 'Fred', last_name: 'Flintstone', email:'fred@flintstone.com'}]);         
  //      scope.$apply(function(){
  //        scope.pagingOptions.pageSize = 1;
  //      });
  //      httpMock.flush();
  //      expect(gscope.renderedRows.length).toBe(1);         
  //    });
  //
  //    it("should have 1 row with filter last_name_like", function() {
  //      httpMock.when('GET', '/users?filter=%7B%22last_name_like%22:%22stone%22%7D&page=1&per_page=2').respond([{id: 1, first_name: 'Fred', last_name: 'Flintstone', email:'fred@flintstone.com'}]);         
  //      scope.$apply(function(){
  //        scope.filterOptions.last_name_like = 'stone';
  //      });
  //      httpMock.flush();
  //      expect(gscope.renderedRows.length).toBe(1);         
  //    });     

});

describe('NavMenu', function(){

  var ctrl, gscope, scope, elm;

  beforeEach( function() {
    angular.mock.module("App");
    angular.mock.module("directives")
  });
  beforeEach(inject(function($rootScope, $injector, $httpBackend, $compile, $timeout) {
    scope = $rootScope.$new();

    scope.menu = [{text: 'HOME', href:'/app/index.html', children: [
      {text:'MANAGE Dashboard', href:'/dashb'}
    ]
    },
    {text: 'MANAGE', href:'/manage', children: [
      {text:'MANAGE PEOPLE', href:'/manage-people', children: [
      {text:'MANAGE STAFF', href:'/manage-staff'},
      {text:'MANAGE CLIENTS', href:'/manage-clients'}              
    ]}
    ]},
    {text: 'REPORTS', href:'/reports', children: [
      {text: 'REPORT NUMERO UNO', href: '#'},
      {text: 'REP NUMERO 2', href: '#', children: [{text:'Third Tier', href: '#'}, {text:'Another Third Tier', href: '#', children: [
        {text:'SUB SUB NAV', href:'#'}
      ]}]}
    ]},
    {text: 'MY INFO', href:'/my-info' },
    ]

    var temp = angular.element('<nav class="nav-menu" menu-data="menu"></nav>');
    $compile(temp)(scope);
    scope.$digest();


    elm = angular.element(temp.children('ul'));
    gscope = angular.element(elm).scope();

    // https://github.com/angular/angular.js/issues/4023
    // ngAnimate effs with ng-class if it's a dependency
    // of the app.  This fixes it.
    $timeout.flush();

  }));

  it("should have 4 top level li", function() {
    expect(elm.children('li').length).toBe(4); 
  });

  it("first li should have a drop down", function() {
    expect(elm.children('li').eq(0)).toHaveClass('has-dropdown'); 
    expect(elm.children('li').eq(0)).toHaveClass('has-dropdown');          
  });

  it("last li should not a drop down", function() {
    expect(elm.children('li').eq(3)).not.toHaveClass('has-dropdown'); 
  });

  // it("all uls should be hidden", function() {
  //     console.log("all uls hidden");
  //     console.log(elm.find('ul').eq(0).is(":visible"));
  //     expect(elm.find('ul').eq(0)).toBeHidden(); 
  // });

});

describe("subNavigation", function() {

  beforeEach( function() {
    angular.mock.module("App");
    angular.mock.module("directives")
  });
  var elm, scope;
  beforeEach(inject(function($rootScope, $compile){
    scope = $rootScope.$new();
    elm = angular.element("<h3 sub-navigation>My Stuff</h3><ul class='nav-subnav'><li>Toggle Me Elmo</li></ul>");
    elm = $compile(elm)(scope);
    scope.$digest();
  }));

  it("should hide the subnav when clicked", function(){
    var ev = $.Event("click");
    var h3 = elm.find("h3"), ul = $(elm[1]); 
    elm.click();
    expect(elm[1]).toBeHidden();
  });

  it("should show the subnav when clicked and it is hidden", function(){
    var ev = $.Event("click");
    var h3 = elm.find("h3"), ul = $(elm[1]);
    ul.hide();
    elm.click();
    expect(ul.css("display")).toEqual('block');
  });
});

