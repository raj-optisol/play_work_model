(function () {
  'use strict';
}());

String.prototype.toDash = function(){
    return this.replace(/([A-Z])/g, function($1){return "-"+$1.toLowerCase();});
};
if (!Date.now){
  Date.now = function() { return new Date().getTime(); };
}
/* App Module */

var App = angular.module('App', [
    'ngResource',
    'ngAnimate',
    'ngSanitize',
    'LocalStorageModule',
    'KyckNotificationModule',
    'restangular',
    'directives',
    'filters',
    'ZurbFoundation',
    '$kyckui',
    'kyckForm',
    'app.controllers',
    'app.services',
    'sanctioningBody',
    'sanction',
    'search.controllers',
    'organization',
    'competition',
    'sanctioning_request',
    'competition',
    'competition_entry',
    'location',
    'adminJob',
    'user',
    'staff',
    'team',
    'events',
    'roster',
    'player',
    'request',
    'payment',
    'dashboard',
    'document',
    'card',
    'card_request',
    'card_product',
    'order',
    'account_transactions',
    'notes',
    'products',
    'registration',
    'money',
    'ui.compat',
    'ui.unique',
    // 'ui.router.compat',
    'dashboard',
    'message',
    'user_settings',
    'controllers.common',
    'directives.common',
    'services.common',
    'filters.common',
    'state',
    'import_process',
    'pasvaz.bindonce',
    'leaflet-directive',
    'background_check'
]).
config(['$routeProvider', '$locationProvider', '$httpProvider', '$stateProvider', '$urlRouterProvider', '$compileProvider', '$controllerProvider', '$provide', function($routeProvider, $locationProvider, $httpProvider, $stateProvider, $urlRouterProvider, $compileProvider, $controllerProvider, $provide) {

    App.providers = {
        $httpProvider: $httpProvider,
        $controllerProvider: $controllerProvider,
        $compileProvider: $compileProvider,
        $provide: $provide,
        $urlRouterProvider: $urlRouterProvider,
        $stateProvider: $stateProvider
    };

    App.compileProvider = $compileProvider;

    $locationProvider.html5Mode(true);

    $urlRouterProvider
    .otherwise(function(locationUrl){
        console.log("Otherwise");

        if (locationUrl.oldVal && locationUrl.oldVal != window.location.href) { // make sure it doesnt go into an infinite loop
            window.location.reload();
        }
    });



    $stateProvider.state('card_products', {
        url: "/card_products",
        templateUrl: 'card_products.html'
        // views: {
        //              'content': {
        //                templateUrl: 'card_products.html'
        //                // controller:
        //                //   [        '$scope', '$stateParams',
        //                //   function ($scope,   $stateParams) {
        //                //       console.log("INSIDE THI SCONTRO");
        //                //     // $scope.something = something;
        //                //     // $scope.contact = findById($scope.contacts, $stateParams.contactId);
        //                //   }]
        //              }
        //          }
    })
    .state('requests', {
        url: "/requests",
        templateUrl: '/requests.html'
        // templateProvider: function ($timeout, $stateParams) {
        //     console.log("TEMP PROVI");
        //   return $timeout(function () { return '<h1>HELLO THERE</h1>' }, 100);
        // },
        // controller:function($scope){
        //     console.log("INSIDE CONTROLLER");
        // },
        // views: {
        //     'content': {
        //       templateUrl: '/requests.html',
        //     }
        // }
    })
    .state('org_request', {
        url: "/organization_requests",
        templateUrl: '/organization_requests.html'
        // templateProvider: function ($timeout, $stateParams) {
        //             console.log("TEMP PROVI");
        //             console.log($stateParams);
        //             return '<h1>HELLO THERE</h1>';
        //           // return $timeout(function () { return '<h1>HELLO THERE</h1>' }, 100);
        //         }
        // controller:function($scope){
        //     console.log("INSIDE CONTROLLER");
        // },
        // views: {
        //     'content': {
        //         templateUrl: '/organization_requests.html'
        //     }
        // }
    })
    .state('org_request_edit', {
        url: "/organization_requests/:id/edit",
        templateUrl: function(params){ return '/organization_requests/'+params.id+'/edit.html'; }
        // views:{
        //     '':{
        //         templateUrl: '/requests.html',
        //     }
        // }
        // templateProvider: function ($timeout, $stateParams) {
        //     console.log("TEMP PROVI");
        //     console.log($stateParams);
        //     // return '<h1>HELLO THERE</h1>';
        //   return $timeout(function () { return '<h1>HELLO THERE</h1>' }, 100);
        // }
    })
    .state('sanctioning_bodies', {
        url: "/sanctioning_bodies/:id",
        templateUrl: function(params){ return '/sanctioning_bodies/'+params.id+'.html'; }
    })
    .state('sanctioning_bodies_staff', {
        url: "/sanctioning_bodies/:id/staff",
        templateUrl: function(params){ return '/sanctioning_bodies/'+params.id+'/staff.html'; }
    })
    .state('sanctioning_bodies_request', {
        url: "/sanctioning_bodies/:id/sanctioning_requests",
        templateUrl: function(params){ return '/sanctioning_bodies/'+params.id+'/sanctioning_requests.html'; }
    })
    .state('sanctions', {
        abstract:true,
        url:"",
        template: "<div ui-view></div>"
    })
    .state('sanctions.sanctioning_bodies_sanctions', {
        url: "/sanctioning_bodies/:id/sanctions",
        templateUrl: function(params){ return '/sanctioning_bodies/'+params.id+'/sanctions.html'; }
    })
    .state('sanctions.sanctioning_bodies_sanction', {
        url: "/sanctioning_bodies/:sanctioning_body_id/{sanctions:(?:organizations)|(?:competitions)}/:id",
        templateUrl: function(params){ return '/sanctioning_bodies/'+params.sanctioning_body_id+'/' + params.sanctions + '/' + params.id + '.html'; }
    })
    .state('organization_overview', {
        url: "/organizations/{id:[0-9a-fA-F\-]{20,40}}",
        templateUrl: function(params){ return '/organizations/'+params.id+'.html'; }
    })
    .state('organization_edit', {
        url: "/organizations/:id/edit",
        templateUrl: function(params){
            return "/organizations/"+params.id+'/edit.html';
        }
    })
    .state('organization_teams', {
        url: "/organization/:id/teams",
        templateUrl: function(params){ return '/organizations/'+params.id+'/teams.html'; }
    })
    .state('organization_players', {
        url: "/organizations/:id/players",
        templateUrl: function(params){ return '/organizations/'+params.id+'/players.html'; }
    })
    .state('organization_competitions', {
        url: "/organizations/:id/competitions",
        templateUrl: function(params){ return '/organizations/'+params.id+'/competitions.html'; }
    })
    .state('organization_competitions_new', {
        url: "/organizations/:id/competitions/new",
        templateUrl: function(params){ return '/organizations/'+params.id+'/competitions/new.html'; }
    })
    .state('organization_competition', {
        url: "/organizations/:id/competitions/:competitionID",
        templateUrl: function(params){  return '/organizations/'+params.id+'/competitions/'+params.competitionID+'.html'; }
    })
    .state('team_overview', {
        url: "/teams/:id",
        templateUrl: function(params){ return '/teams/'+params.id+'.html'; }
    })
    .state('team_rosters', {
        url: "/teams/:id/rosters",
        templateUrl: function(params){ return '/teams/'+params.id+'/rosters.html'; }
    })
    .state('team_rosters_new', {
        url: "/teams/:id/rosters/new",
        templateUrl: function(params){ return '/teams/'+params.id+'/rosters/new.html'; }
    })
    .state('team_events', {
        url: "/teams/:id/events",
        templateUrl: function(params){ return '/teams/'+params.id+'/events.html'; }
    })
    .state('team_events_new', {
        url: "/teams/:id/events/new",
        templateUrl: function(params){ return '/teams/'+params.id+'/events/new.html'; }
    })
    .state('roster_overview', {
        url: "/teams/:id/rosters/:rosterID",
        templateUrl: function(params){ return '/teams/'+params.id+'/rosters/'+params.rosterID+'.html'; }
    })
        // .state('obj_players', {
        //   url: "/{st}/:id/players",
        //     templateUrl: function(params){
        //       return "/"+params.st+"/"+params.id+'/players.html';
        //     }
        // })
    .state('team_competitions', {
        abstract:true,
        url:"",
        template: "<div ui-view=''></div>"
    })
    .state('team_competitions.available', {
        url: "/teams/:id/competitions",
        templateUrl: function(params){
            return "/teams/"+params.id+'/competitions.html';
        }
    })
    .state('team_competitions.entries', {
        url: "/teams/:id/entries",
        templateUrl: function(params){
            return "/teams/"+params.id+'/entries.html';
        }
    })
    .state('team_competitions.entry', {
        url: "/teams/:team_id/entries/:id",
        templateUrl: function(params){
            return "/teams/"+params.team_id+'/entries/'+params.id+'.html';
        }
    })
    .state('team_competitions.new_entry', {
        url: "/teams/:team_id/competitions/:id/entries/new",
        templateUrl: function(params){
            return "/teams/"+params.team_id+'/competitions/'+params.id+'/entries/new.html';
        }
    })
    .state('obj_staff', {
        url: "/{st}/:id/staff",
        templateUrl: function(params){
            return "/"+params.st+"/"+params.id+'/staff.html';
        }
    })
    .state('obj_messages', {
        url: "/{st}/:id/messages",
        templateUrl: function(params){
            return "/"+params.st+"/"+params.id+'/messages.html';
        }
    })
    .state('user_profile', {
        url: "/users/:id",
        templateUrl: function(params){
            return "/users/"+params.id+'.html';
        }
    })
    .state('user_profile_edit', {
        url: "/users/:id/edit",
        templateUrl: function(params){
            return "/users/"+params.id+'/edit.html';
        }
    })
    .state('user_notifications', {
        url: "/users/:id/notification_settings",
        templateUrl: function(params){
            return "/users/"+params.id+'/notification_settings.html';
        }
    })
    .state('user_documents', {
        url: "/users/:id/documents",
        templateUrl: function(params){
            return "/users/"+params.id+"/documents.html";
        }
    })
    .state('cards', {
        abstract:true,
        url:"",
        template: "<div ui-view=''></div>"
    })
    .state('cards.cards_overview', {
        url: "/:obj/:id/cards/overview",
        templateUrl: function(params){
            return "/"+params.obj+"/"+params.id+'/cards/overview.html';
        }
    })
    .state('cards.card_requests', {
        url: "/:obj/:id/card_requests",
        templateUrl: function(params){
            return "/"+params.obj+"/"+params.id+'/card_requests.html';
        }
    })
    .state('cards.card_request', {
        url: "/:obj/:objid/card_requests/:id",
        templateUrl: function(params){
            return "/"+params.obj+"/"+params.objid+'/card_requests/'+params.id+'.html';
        }
    })
    .state('cards.card_request_new', {
        url: "/:obj/:id/card_requests/new",
        templateUrl: function(params){
            return "/"+params.obj+"/"+params.id+'/card_requests/new.html';
        }
    })
    .state('cards.organization_sanctioning_requests', {
        url: "/organizations/:id/sanctioning_requests",
        templateUrl: function(params){ return '/organizations/'+params.id+'/sanctioning_requests.html'; }
    })
    .state('cards.organization_sanctioning_request', {
        url: "/organizations/:org_id/sanctioning_requests/:id",
        templateUrl: function(params){ return '/organizations/'+params.org_id+'/sanctioning_requests/' + params.id + '.html'; }
    })
    .state('cards.organization_new_sanctioning_request', {
        url: "/organizations/:org_id/sanctioning_requests/new",
        templateUrl: function(params){ return '/organizations/'+params.org_id+'/sanctioning_requests/new.html'; }
    })
    .state('cards.competition_new_sanctioning_request', {
        url: "/competitions/:comp_id/sanctioning_requests/new",
        templateUrl: function(params){ return '/competitions/'+params.comp_id+'/sanctioning_requests/new.html'; }
    })
    .state('cards.competition_edit_card', {
        url: "/competitions/:comp_id/cards/:id/edit",
        templateUrl: function(params){ return '/competitions/'+params.comp_id+'/cards/' + params.id + '/edit.html'; }
    })
    .state('cards.competition_manage', {
        url: "/competitions/:comp_id/cards/manage",
        templateUrl: function(params){ return '/competitions/'+params.comp_id+'/cards/manage.html'; }
    })
    .state('cards.edit_card', {
        url: "/cards/:id/edit",
        templateUrl: function(params){ return '/cards/' + params.id + '/edit.html'; }
    })
    .state('cards.print', {
        url: "/:obj/:id/cards",
        templateUrl: function(params){
            return "/"+params.obj+"/"+params.id+'/cards.html';
        }
    })
    .state('rosters', {
        abstract:true,
        url:"/",
        template: "<div ui-view=''></div>"
    })
    .state('rosters.players', {
        url: "rosters/:id/players",
        templateUrl: function(params){
            return "/rosters/"+params.id+'/players.html';
        }
    })
    .state('rosters.manage_players', {
        url: "rosters/:id/manage-players",
        templateUrl: function(params){
            return "/rosters/"+params.id+'/manage-players.html';
        }
    })
    .state('players', {
        abstract:true,
        url:"/",
        template: "<div ui-view=''></div>"
    })
    .state('players.team_players', {
        url: "teams/:id/players",
        templateUrl: function(params){
            return "/teams/"+params.id+'/players.html';
        }
    })
    .state('players.team_manage_players', {
        url: "teams/:id/manage-players",
        templateUrl: function(params){
            return "/teams/"+params.id+'/manage-players.html';
        }
    })
    .state('orders', {
        abstract:true,
        url:"",
        template: "<div ui-view=''></div>"
    })
    .state('orders.overview', {
        url:  '{obj:[a-zA-Z\-0-9\/]*}/orders',
        templateUrl: function(params){
            return params.obj+'/orders.html';
        }
    })
    .state('orders.detail', {
        url:  '{obj:[a-zA-Z\-0-9\/]*}/orders/:id',
        templateUrl: function(params){
            //this shit is causing some problems I think
            return params.obj+'/orders/' + params.id + '.html';
            //return params.obj+'/orders/'+params.id;
        }
    })
    .state('reports', {
        abstract:true,
        url:"",
        template: "<div ui-view=''></div>"
    })
    .state('reports.overview', {
        url: "/sanctioning_bodies/:id/reports/overview",
        templateUrl: function(params){
            return "/sanctioning_bodies/"+params.id+'/reports/overview.html';
        }
    })
    .state('reports.ussf_report', {
        url: "/sanctioning_bodies/:id/reports/ussf_report",
        templateUrl: function(params){
            return "/sanctioning_bodies/"+params.id+'/reports/ussf_report.html';
        }
    })
    .state('reports.player_registration_report', {
        url: "/sanctioning_bodies/:id/reports/player_registration_report",
        templateUrl: function(params){
            return "/sanctioning_bodies/"+params.id+'/reports/player_registration_report.html';
        }
    })
    .state('reports.staff_registration_report', {
        url: "/sanctioning_bodies/:id/reports/staff_registration_report",
        templateUrl: function(params){
            return "/sanctioning_bodies/"+params.id+'/reports/staff_registration_report.html';
        }
    })
    .state('reports.summary_registration_report', {
        url: "/sanctioning_bodies/:id/reports/summary_registration_report",
        templateUrl: function(params){
            return "/sanctioning_bodies/"+params.id+'/reports/summary_registration_report.html';
        }
    })
    .state('fee', {
        abstract:true,
        url:"",
        template: "<div ui-view></div>"
    })
    .state('fee.overview', {
        url: "/sanctioning_bodies/:id/fees/overview",
        templateUrl: function(params){
            return "/sanctioning_bodies/"+params.id+'/fees/overview.html';
        }
    })
    .state('fee.sb_card_products', {
        url: "/sanctioning_bodies/:sb_id/card_products",
        templateUrl: function(params){
            return "/sanctioning_bodies/"+params.sb_id+'/card_products.html';
        }
    })
    .state('fee.sb_card_products_new', {
        url: "/sanctioning_bodies/:sb_id/card_products/new",
        templateUrl: function(params){
            return "/sanctioning_bodies/"+params.sb_id+'/card_products/new.html';
        }
    })
    .state('fee.sb_card_products_manage', {
        url: "/sanctioning_bodies/:sb_id/card_products/:id/edit",
        templateUrl: function(params){
            return "/sanctioning_bodies/"+params.sb_id+'/card_products/'+params.id+'/edit.html';
        }
    })
    .state('fee.sr_request_products', {
        url: "/sanctioning_bodies/:sb_id/sanctioning_request_products",
        templateUrl: function(params){
            return "/sanctioning_bodies/"+params.sb_id+'/sanctioning_request_products.html';
        }
    })
    .state('fee.sr_request_products_new', {
        url: "/sanctioning_bodies/:sb_id/sanctioning_request_products/new",
        templateUrl: function(params){
            return "/sanctioning_bodies/"+params.sb_id+'/sanctioning_request_products/new.html';
        }
    })
    .state('fee.sr_request_products_manage', {
        url: "/sanctioning_bodies/:sb_id/sanctioning_request_products/:id/edit",
        templateUrl: function(params){
            return "/sanctioning_bodies/"+params.sb_id+'/sanctioning_request_products/'+params.id+'/edit.html';
        }
    })
        // .state('cards.card_request', {
        //   url: ":obj/:id/card_requests/new",
        //   templateUrl: function(params){
        //    return "/"+params.obj+"/"+params.id+'/card_requests/new.html';
        //   }
        // })
    ;


    $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content');
    $httpProvider.defaults.headers.common["Accept"] = "application/json, text/plain";
    $httpProvider.defaults.headers.common["X-Requested-With"] = "XMLHTTPRequest";

    // otherwise({redirectTo: '/tests'});
}])
.run(
[        '$rootScope', '$state', '$stateParams', '$location', 'currentUser',
    function ($rootScope,   $state,   $stateParams, $location, currentUser) {

        App.rootScope = $rootScope;
        $rootScope.$state = $state;
        $rootScope.$stateParams = $stateParams;
        $rootScope.showMenu = false;
        $rootScope.currentUser = currentUser;

        $rootScope.$on("$locationChangeStart", function(obj, nval, oval){
            // console.log("location change start");
            $location.oldVal = oval;

        });

        // $rootScope.$on("$routeChangeStart", function(obj, next, current){
        //     console.log("route change start");
        //     if (!current) {
        //         // obj.defaultPrevented = true;
        //     };
        //     console.log(arguments);
        // });
        $rootScope.$on( "$stateChangeSuccess", function(obj, next, nParam, current) {
            console.log("state change success");
            //$location.oldVal = window.location.href;
        });

        $rootScope.$on( "$stateChangeStart", function(obj, next, nParam, current) {

            var oindex = $location.oldVal.lastIndexOf('?');
            var oval = oindex >= 0 ? $location.oldVal.substring(0, oindex) : $location.oldVal.substring(oindex);

            App.providers['$httpProvider'].defaults.headers.common["Actual-Referer"] = $location.oldVal;

            console.log('state change start');

            if(current.abstract && ((window.location.origin+next.templateUrl(nParam) == oval && obj.targetScope.$state.$current.toString() != next.name)))
            {
                obj.defaultPrevented = true;
                $rootScope.$state.$current.name = next.name;
                $rootScope.$state.current.abstract = false;
            }
            if(current.abstract && window.location.href!=$location.oldVal)
            {
                console.log("should reload");
                obj.defaultPrevented = true;
                window.location.reload();

            }
        });

        $rootScope.$on("$stateChangeError", function(){
            console.log("state change error");
        });
        $rootScope.$on('$viewContentLoaded', function() {
            console.log("view content loaded");
            $(document).foundation();
        });
    }]);
