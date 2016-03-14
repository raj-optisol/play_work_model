angular.module("card.controllers", []).
  controller("CardsCtrl", ["$scope", "parentOrganization", "CardRequest", "columnService", "Team",
             function($scope,  parentOrganization, CardRequest, columnService, Team) {

  $scope.url = window.location.pathname + ".json";
  $scope.filter = {status:"new_and_approved"};
  $scope.filterOptions = {status_in:$scope.filter.status.split("_and_")};
  $scope.printCardsUrl = window.location.pathname+".pdf?";
  $scope.card_selection = [];
  $scope.max_card_selection = 30;
  $scope.selectedUsers = false;

  $scope.$watch("params", function(nval, oval)
  {
    if($scope.card_selection.length > 0)
    {
      $scope.printCardsUrl = window.location.pathname+".pdf?"+$scope.getSelectedUsers();
    }
    else
    {
      $scope.printCardsUrl = window.location.pathname+".pdf?"+$scope.getParams();
    }
  });

  $scope.printCards = function() {
    window.open($scope.printCardsUrl);
    $scope.clearSelection();
  }

  $scope.showCheckbox = function() {
    return true;
  }

  $scope.updateCardSelection = function(id)
  {
    var add_card = true;

    for(var i = 0; i < $scope.card_selection.length; i++)
    {
      if(id == $scope.card_selection[i])
      {
        add_card = false;
        $scope.card_selection.splice(i, 1);
      }
    }

    if(add_card)
    {
      $scope.card_selection.push(id);
    }

    if($scope.card_selection.length >= $scope.max_card_selection)
    {
      alert("You've selected the maximum amount of cards. Please print or edit your selection before selecting anymore cards.");
    }

    $scope.resetUrl();
  }

  $scope.maxSelected = function(id) {
    if($scope.card_selection.length >= $scope.max_card_selection){
      if($scope.userSelected(id)){
        return false
      } else {
        return true
      }
    } else {
      return false
    }
  }

  $scope.clearSelection = function() {
    $scope.card_selection = [];
    $scope.resetUrl();
  }

  $scope.resetUrl = function() {
    if($scope.card_selection.length > 0)
    {
      $scope.printCardsUrl = window.location.pathname+".pdf?"+$scope.getSelectedUsers();
    }
    else
    {
      $scope.printCardsUrl = window.location.pathname+".pdf?"+$scope.getParams();
    }
  }

  // This is not an efficient solution
  $scope.userSelected = function(id)
  {
    var in_selection = false;
    for(var i = 0; i< $scope.card_selection.length; i++)
    {
      if(id == $scope.card_selection[i])
      {
        in_selection = true;
      }
    }
    return in_selection;
  }

  $scope.getSelectedUsers = function() {
    if($scope.card_selection.length > 0)
      return "&kyck_ids=" + $scope.card_selection;
    else
      return "";
  }

  $scope.columnDefs = [
    columnService.userTemplate,
    {field: 'kind', width: "10%"},
    {field: "teams", displayName: 'Teams', cellTemplate:'/assets/templates/grid/teams_template.html', width: "20%"},
    {field: 'status', width: "10%"},
    {field: 'created_at', displayName: 'Requested', cellFilter: "kyckDate", width: "8%"},
    {field: 'approved_on', displayName: 'Approved', cellFilter: "kyckDate", width: "8%"},
    {field: 'expires_on', displayName: 'Expires', cellFilter: "kyckDate", width: "8%"},
    {field: 'Print', displayName: 'Print', width: '100', cellTemplate: '<div class="ngCellText"><a href="/cards/{{row.entity.id}}.pdf" class="btn small" ng-show="showPrintButton(row)" target="_blank">Print</a></div>'}
  ];

  $scope.showPrintButton = function(row) {
    return /approved/i.test(row.entity.status);
  };

  $scope.clearFilterOptions = function() {
    $scope.filterOptions = {};
  };

  $scope.applyFilter = function(){
    $scope.clearFilterOptions();
    if ($scope.filter.last_name) $scope.filterOptions.last_name_like = $scope.filter.last_name;
    if (_.isEmpty($scope.filter.team_name)) $scope.filter.team_id = null;
    if ($scope.filter.team_id) $scope.filterOptions.team_id = $scope.filter.team_id;
    if ($scope.filter.status) $scope.filterOptions.status_in = $scope.filter.status.split("_and_");
  };

  $scope.clearFilter = function() {
    $scope.filter={};
    $scope.applyFilter();
  };

  $scope.getParams = function(){
    if($scope.params)
      return jQuery.param( $scope.params );
    return "";
  };
}]).
controller("TeamCardsCtrl", ["$scope", "parentOrganization", "columnService",
           function($scope,  parentOrganization, columnService) {

  $scope.url = window.location.pathname + ".json";

  var parval = parentOrganization.value();
  $scope.filter = {status:"new_and_approved"};
  $scope.filterOptions = {status_in:$scope.filter.status.split("_and_")};

  $scope.printCardsUrl = window.location.pathname+".pdf?";

  /* select-print-cards code */
  $scope.card_selection = [];
  $scope.max_card_selection = 30;
  $scope.selectedUsers = false;

  $scope.showCheckbox = function() {
    return true;
  }

  $scope.updateCardSelection = function(id)
  {
    var add_card = true;

    for(var i = 0; i < $scope.card_selection.length; i++)
    {
      if(id == $scope.card_selection[i])
      {
        add_card = false;
        $scope.card_selection.splice(i, 1);
      }
    }

    if(add_card)
    {
      $scope.card_selection.push(id);
    }

    if($scope.card_selection.length >= $scope.max_card_selection)
    {
      alert("You've selected the maximum amount of cards. Please print or edit your selection before selecting anymore cards.");
    }

    $scope.resetUrl();
  }

  $scope.maxSelected = function(id) {
    if($scope.card_selection.length >= $scope.max_card_selection){
      if($scope.userSelected(id)){
        return false
      } else {
        return true
      }
    } else {
      return false
    }
  }

  $scope.printCards = function() {
    window.open($scope.printCardsUrl);
    $scope.clearSelection();
  }

  $scope.clearSelection = function() {
    $scope.card_selection = [];
    $scope.resetUrl();
  }

  $scope.resetUrl = function() {
    if($scope.card_selection.length > 0)
    {
      $scope.printCardsUrl = window.location.pathname+".pdf?"+$scope.getSelectedUsers();
    }
    else
    {
      $scope.printCardsUrl = window.location.pathname+".pdf?"+$scope.getParams();
    }
  }


  // This is not an efficient solution
  $scope.userSelected = function(id)
  {
    var in_selection = false;
    for(var i = 0; i< $scope.card_selection.length; i++)
    {
      if(id == $scope.card_selection[i])
      {
        in_selection = true;
      }
    }
    return in_selection;
  }

  $scope.getSelectedUsers = function() {
    if($scope.card_selection.length > 0)
      return "&kyck_ids=" + $scope.card_selection;
    else
      return "";
  }

  $scope.showPrintButton = function(row) {
    return /approved/i.test(row.entity.status);
  };

  $scope.$watch("params", function(nval, oval){
    if($scope.card_selection.length > 0)
    {
      $scope.printCardsUrl = window.location.pathname+".pdf?"+$scope.getSelectedUsers();
    }
    else
    {
      $scope.printCardsUrl = window.location.pathname+".pdf?"+$scope.getParams();
    }
  });
  /* ----------------------- */

  $scope.columnDefs = [
    columnService.userTemplate,
    {field: 'kind'},
    { field: "teams", displayName: 'Teams', cellTemplate:'/assets/templates/grid/teams_template.html', width: "30%"},
    {field: 'status'},
    {field: 'Print', displayName: 'Print', width: '100', cellTemplate: '<div class="ngCellText"><a href="/cards/{{row.entity.id}}.pdf" class="btn small" target="_blank" ng-show="showPrintButton(row)">Print</a></div>'}
  ];

  $scope.applyFilter = function(){
    $scope.filterOptions.status_in = $scope.filter.status.split("_and_");
    // $scope.filterOptions.kind = $scope.filter.kind;
    $scope.filterOptions.last_name_like = $scope.filter.last_name;
  };

  $scope.clearFilter = function() {
    $scope.filter={};
    $scope.applyFilter();

  };

  $scope.getParams = function(){
    if($scope.params)
      return jQuery.param( $scope.params );
    return "";
  };

  $scope.showPrintButton = function(row) {
    return /approved/i.test(row.entity.status);
  };
}])
.controller("SanctioningBodyCardsCtrl", ["$scope", "columnService", "Sanction", "parentOrganization", 'Restangular', 'Card',
            function($scope, columnService, Sanction, parentOrganization, Restangular, Card) {
  $scope.url = "";

  $scope.orgData = Sanction.bind({sb_id: parentOrganization.value().id});
  $scope.selectedRowForView = {entity: {}, time: null};

  $scope.columnDefs = [
    {field: "user", displayName: 'Name', width: "250", sortable: false, cellTemplate: '/assets/templates/grid/user_card_template.html'},
    {field: 'birthdate', displayName: 'Birthdate', width: '100'},
    {field: 'kind', width: '100'},
    {field: "org_name", displayName: 'Organization'},
    {field: 'status'},
    {field: 'message_status', displayName: "Messages?", sortable: false, cellTemplate:'<div bindonce class="ngCellText"><i bo-class="{true: \'icn-clock\', false: \'\' }[waitingForMessage(row)]"></i><i bo-class="{true: \'icn-check\', false: \'\' }[hasNewMessage(row)]"></i>'},
    columnService.viewRowTemplate,
    {field: 'Action', displayName: 'Action', width: '100', cellTemplate: '<div class="ngCellText" ><a class="small btn" href="/cards/{{row.entity.id}}/edit">Edit</a></div>'}
  ];

  $scope.hasNewMessage = function(row) {
    return row.entity.message_status == "requestor_response_received";
  };
  $scope.waitingForMessage = function(row) {
    return row.entity.message_status == "requestor_response_required";
  };

  var addFirstName = function() {
    return $scope.filter.first_name &&
      $scope.filter.last_name &&
      $scope.filter.last_name.length >= 3;
  };

  $scope.applyFilter = function(){
    $scope.clearFilterOptions();

    if($scope.filter.status) $scope.filterOptions.status_in = $scope.filter.status.split("_and_");

    if(addFirstName())
      $scope.filterOptions.first_name = $scope.filter.first_name;
    else
      $scope.filter.first_name = null;

    if($scope.filter.last_name) $scope.filterOptions.last_name = $scope.filter.last_name;
    if($scope.filter.birthdate) $scope.filterOptions.birthdate = $scope.filter.birthdate;
    if (_.isEmpty($scope.filter.organization_name)) $scope.filter.sanction_id = null;
    if($scope.filter.sanction_id) $scope.filterOptions.sanction_id = $scope.filter.sanction_id;
    if ($scope.url === "") $scope.url = window.location.pathname + ".json";
    console.dir($scope.filterOptions);


  };

  $scope.clearFilterOptions = function() {
    $scope.filterOptions = {};
  };

  $scope.clearFilter = function() {
    $scope.filter = {};
    $scope.orgData = Sanction.bind({sb_id: parentOrganization.value().id});
  };

  $scope.selectOrg =function(e, val) {
    $scope.filter.sanction_id = val.item.id;
  };

  $scope.setSelectedRowForView = function(row) {
    $scope.selectedRow = row;
    $scope.selectedAvatar = row.getProperty('user.avatar');
    $scope.selectedRowForView.entity = row.entity;
    $scope.selectedRowIndex = row.rowIndex;
    $scope.selectedRowForView.time = new Date();
  };

  $scope.approveCard = function(row) {
    var rows = _.isArray(row) ? row : [row];
    rowIds = _.map(rows, function(row) {return row.entity.id;});
    Restangular.one("sanctioning_bodies", parentOrganization.value().id).one("cards").customPOST( {card_ids: rowIds}, "approve").then(function(resp) {
      _.each(rows, function(row) {
        row.entity.status = "Approved";
      });
    });
  };

  $scope.makeInactive = function(row) {
    var c = new Card({org_kind: 'sanctioning_bodies', org_id: parentOrganization.value().id, id: row.entity.id});
    c.status = 'inactive';
    c.$update(function() {
      row.entity.status = "Inactive";
    });
  };
}])
.controller("ManageCompetitionCardsCtrl", ["$scope", "columnService", "parentOrganization", 'Restangular', 'CompetitionOrganization', 'Team', 'Card', 'sessionStorageService', function($scope, columnService, parentOrganization, Restangular, CompetitionOrganization, Team, Card, sessionStorageService) {
  var keyPrefix = 'comp-cards-filter-';
  var filterKeys = ['organization_id', 'message_status', 'status', 'last_name', 'team_id', 'team_name', 'organization_name'];

  // Remove 'manage' from the url
  $scope.url = window.location.pathname.replace(/\/manage/i, '');

  $scope.teamData = Team.bind({competition_id: parentOrganization.value().id});
  $scope.teams = $scope.teamData.query();
  $scope.selectedRowForView = {entity: {}, time: null};
  $scope.filter = jQuery.extend({status: "new", kind: "player"}, sessionStorageService.get(keyPrefix, filterKeys));
  filter = jQuery.extend({}, $scope.filter);
  delete filter.organization_name;
  delete filter.team_name;
  if (typeof filter.last_name != 'undefined') {
    filter.last_name_like = filter.last_name;
    delete filter.last_name;
  }
  $scope.filterOptions = filter;

  $scope.columnDefs = [
    {field: "user", displayName: 'Name', width: "*", sortable: false, cellTemplate: '/assets/templates/grid/user_card_template.html'},
    {field: 'kind', width: '6%'},
    {field: "org_name", displayName: 'Organization'},
    {field: 'teams', displayName: 'Teams', cellTemplate:'/assets/templates/grid/teams_template.html'},
    {field: 'status'},
    {field: 'message_status'},
    columnService.viewRowTemplate,
    {
      field: 'Action', displayName: 'Action', width: '100', sortable: false,
      cellTemplate: '<div class="ngCellText" ng-class="col.colIndex()"><a ng-hide="showProcessButton(row.entity)" href="/competitions/' + parentOrganization.value().id + '/cards/{{row.entity.id}}/edit" class="btn">Edit</a><a ng-show="showProcessButton(row.entity)" href="/competitions/' + parentOrganization.value().id + '/cards/{{row.entity.id}}/edit" class="btn">Process</a></div>'
    }
  ];

  $scope.showProcessButton = function(card) {
    return /new|processed/i.test(card.status);
  };

  $scope.queryOrgs = function(request, response) {
    $scope.filter.organization_id = undefined;
    console.log("SCOPE", $scope.url.replace(/(\/competitions\/)|(\/cards)/g, ''));
    CompetitionOrganization.query({'competition_id': $scope.url.replace(/(\/competitions\/)|(\/cards)/g, ''), 'filter[name_like]':request.term}, function(orgs){
      var items = [];
      angular.forEach(orgs, function(item){
        items.push({id:item.id, label:item.name});
      });
      response(items);
    });
  };

  $scope.doSomethingToOrg = function() {
    if (!$scope.filter.organization_name || $scope.filter.organization_name === '') {
      sessionStorageService.clear(keyPrefix, ['organization_name', 'organization_id']);
      delete $scope.filter.organization_id;
      delete $scope.filter.organization_name;
      $scope.applyFilter();
    }
  };

  $scope.doSomethingToTeam = function() {
    if (!$scope.filter.team_name || $scope.filter.team_name === '') {
      sessionStorageService.clear(keyPrefix, ['team_name', 'team_id']);
      delete $scope.filter.team_id;
      delete $scope.filter.team_name;
      $scope.applyFilter();
    }
  };

  $scope.selectOrg = function(event, selectedOrg){
    event.preventDefault();
    $scope.filter.organization_id = selectedOrg.item.id;
    $scope.filter.organization_name= selectedOrg.item.label;
    if (!$scope.$$phase) $scope.$apply();
  };

  $scope.applyFilter = function(){
    sessionStorageService.store(keyPrefix, filterKeys, $scope.filter);
    $scope.filterOptions = {};
    $scope.filterOptions.kind = "player";
    if ($scope.filter.status) $scope.filterOptions.status = $scope.filter.status;
    if ($scope.filter.message_status) $scope.filterOptions.message_status = $scope.filter.message_status;
    if ($scope.filter.organization_id) $scope.filterOptions.organization_id = $scope.filter.organization_id;
    if ($scope.filter.last_name) $scope.filterOptions.last_name_like = $scope.filter.last_name;
    if ($scope.filter.team_id) $scope.filterOptions.team_id = $scope.filter.team_id;
  };

  $scope.clearFilter = function() {
    sessionStorageService.clear(keyPrefix, filterKeys);
    $scope.filter={};
    $scope.applyFilter();
  };

  $scope.selectTeam =function(e, val) {

    $scope.filter._id = val.itmem.id;
  };

  $scope.setSelectedRowForView = function(row) {
    $scope.selectedRow = row;
    $scope.selectedAvatar = row.getProperty('user.avatar');
    $scope.selectedRowForView.entity = row.entity;
    $scope.selectedRowIndex = row.rowIndex;
    $scope.selectedRowForView.time = new Date();
  };

  $scope.approveCard = function(row) {
    var rows = _.isArray(row) ? row : [row];
    rowIds = _.map(rows, function(row) {return row.entity.id;});
    Restangular.one("competitions", parentOrganization.value().id).one("cards").customPOST( {card_ids: rowIds}, "approve").then(function(resp) {
      _.each(rows, function(row) {
        row.entity.status = "Approved";
      });
    });
  };

  $scope.makeInactive = function(row) {
    var c = new Card({org_kind: 'competitions', org_id: parentOrganization.value().id, id: row.entity.id});
    c.status = 'inactive';
    c.$update(function() {
      row.entity.status = "Inactive";
    });
  };
}])
.controller("PrintCompetitionCardsCtrl", ["$scope", "parentOrganization", "CardRequest", "columnService", "Team", function($scope, parentOrganization, CardRequest, columnService, Team) {

  $scope.url = window.location.pathname + ".json";

  var parval = parentOrganization.value();
  $scope.teams = Team.query({owner:parval.name, owner_id:parval.id});
  $scope.filter = {};
  $scope.filterOptions = {status: 'approved'};
  $scope.printCardsUrl = window.location.pathname+".pdf?";

  /* select-print-cards code */
  $scope.card_selection = [];
  $scope.max_card_selection = 30;
  $scope.selectedUsers = false;

  $scope.printCards = function() {
    window.open($scope.printCardsUrl);
    $scope.clearSelection();
  }

  $scope.showCheckbox = function() {
    return true;
  }

  $scope.updateCardSelection = function(id)
  {
    var add_card = true;

    for(var i = 0; i < $scope.card_selection.length; i++)
    {
      if(id == $scope.card_selection[i])
      {
        add_card = false;
        $scope.card_selection.splice(i, 1);
      }
    }

    if(add_card)
    {
      $scope.card_selection.push(id);
    }

    if($scope.card_selection.length >= $scope.max_card_selection)
    {
      alert("You've selected the maximum amount of cards. Please print or edit your selection before selecting anymore cards.");
    }

    $scope.resetUrl();
  }

  $scope.maxSelected = function(id) {
    if($scope.card_selection.length >= $scope.max_card_selection){
      if($scope.userSelected(id)){
        return false
      } else {
        return true
      }
    } else {
      return false
    }
  }

  $scope.clearSelection = function() {
    $scope.card_selection = [];
    $scope.resetUrl();
  }

  $scope.resetUrl = function() {
    if($scope.card_selection.length > 0)
    {
      $scope.printCardsUrl = window.location.pathname+".pdf?"+$scope.getSelectedUsers();
    }
    else
    {
      $scope.printCardsUrl = window.location.pathname+".pdf?"+$scope.getParams();
    }
  }


  // This is not an efficient solution
  $scope.userSelected = function(id)
  {
    var in_selection = false;
    for(var i = 0; i< $scope.card_selection.length; i++)
    {
      if(id == $scope.card_selection[i])
      {
        in_selection = true;
      }
    }
    return in_selection;
  }

  $scope.getSelectedUsers = function() {
    if($scope.card_selection.length > 0)
      return "&kyck_ids=" + $scope.card_selection;
    else
      return "";
  }

  $scope.showPrintButton = function(row) {
    return /approved/i.test(row.entity.status);
  };

  $scope.$watch("params", function(nval, oval){
    if($scope.card_selection.length > 0)
    {
      $scope.printCardsUrl = window.location.pathname+".pdf?"+$scope.getSelectedUsers();
    }
    else
    {
      $scope.printCardsUrl = window.location.pathname+".pdf?"+$scope.getParams();
    }
  });
  /* ----------------------- */

  $scope.selectTeam =function(e, val) {
    $scope.filter.team_id =  val.item.id;
  };

  $scope.queryTeams = function(request, response) {
    $scope.filter.team_id = undefined;
    Team.query({lite: true, owner: parentOrganization.value().name, owner_id: parentOrganization.value().id, 'filter[name_like]':request.term}, function(teams){
      var items = [];
      angular.forEach(teams, function(item){
        items.push({id:item.id, label:item.name});
      });
      response(items);
    });
  };
  $scope.columnDefs = [
    columnService.printCardUserTemplate,
    {field: 'kind', width: "10%"},
    {field: "teams", displayName: 'Teams', cellTemplate:'/assets/templates/grid/teams_template.html', width: "20%"},
    {field: 'status', width: "10%"},
    {field: 'created_at', displayName: 'Requested', cellFilter: "kyckDate", width: "8%"},
    {field: 'approved_on', displayName: 'Approved', cellFilter: "kyckDate", width: "8%"},
    {field: 'expires_on', displayName: 'Expires', cellFilter: "kyckDate", width: "8%"},
    {field: 'Print', displayName: 'Print', width: '100', cellTemplate: '<div class="ngCellText"><a href="/cards/{{row.entity.id}}.pdf" class="btn small" target="_blank">Print</a></div>'}
  ];

  $scope.applyFilter = function(){
    $scope.filterOptions.kind = $scope.filter.kind;
    $scope.filterOptions.last_name_like = $scope.filter.last_name;
    $scope.filterOptions.team_id = $scope.filter.team_id;
    $scope.filterOptions.status = 'approved';
  };

  $scope.clearFilter = function() {
    $scope.filter={};
    $scope.applyFilter();

  };

  $scope.getParams = function(){
    if($scope.params)
      return jQuery.param( $scope.params );
    return "";
  };

}]).
  controller("EditCardCtrl", ["$scope", "Card", "cloudinary_factory", "Restangular", "parentOrganization", function($scope, Card, cloudinary, Restangular, parentOrganization) {

  $scope.rowsToDecline = [];
  $scope.newNote = {title: 'Add Reason', time: null, text: ''};
  $scope.rejectNote = {title: 'Add Reason', time: null, text: '', added: new Date()};

  $scope.setCard = function(props) {
    $scope.card = new Card(props);
    $scope.selectedRow = {entity: $scope.card};

    if (parentOrganization.value().name == 'competitions') {
      var params = { 'competition_id': parentOrganization.value().id };
      Restangular.one("cards", $scope.card.id).getList("duplicates", params).then(function(resp) {
        $scope.duplicateCards = resp;
      });

    } else {

      Restangular.one("cards", $scope.card.id).getList("duplicates").then(function(resp) {
        $scope.duplicateCards = resp;
      });

      Restangular.one("orders", $scope.card.order_id).get().then(function(resp) {
        $scope.order = resp;
      });
    }
  };

  $scope.cardFormIsDirty = function() {
    return $scope.cardForm.$dirty;
  };

  $scope.cardIsApproved = function() {
    return /Approved/i.test($scope.card.status);
  };

  $scope.approvedCards = function(card){
    return /Approved|New/i.test(card.status);
  };

  $scope.expiredCards = function(card){
    return /Expired|Inactive/i.test(card.status);
  };

  $scope.declineCard = function() {
    if(!$scope.card) return;

    $scope.rowsToDecline.push( $scope.card );
    $scope.rejectNote.time= new Date();
  };

  $scope.deleteAvatar = function() {
    $scope.promptDelete = true;
  };

  $scope.doDecline = function(with_refund) {
    var rows = $scope.rowsToDecline,
    rowIds = _.map(rows, function(row) {return row.id;});
    var props = {card_ids: rowIds, reason: $scope.rejectNote.text, refund: with_refund};
    var promise;
    if (parentOrganization.value().name == 'competitions'){
      promise = Restangular.one("competitions", parentOrganization.value().id).one("cards").customPOST(props , "decline");
    }
    else {
      promise = Restangular.one("card_requests", $scope.card.order_id).one("cards").customPOST(props , "decline");
    }


    promise.then(function(resp) {
      _.each(rows, function(row) {
        row.status = "Denied";
      });
      $scope.rejectNote.added= new Date();
      $scope.rowsToDecline = [];
      $scope.rejectNote.text='';

      if (parentOrganization.value().name == 'competitions'){
          window.location.replace('/competitions/' + parentOrganization.value().id + '/cards/manage');
      } else {
        if($scope.order && $scope.order.pending_item_count - 1 > 0) {
          window.location.replace('/sanctioning_bodies/' + $scope.card.sanctioning_body_id + '/card_requests/' + $scope.order.id);
        } else {
          window.location.replace('/sanctioning_bodies/' + $scope.card.sanctioning_body_id + '/card_requests');
        }
      }
    });
  };

  $scope.deleteAvatarConfirmed = function() {
    var c_id = $scope.card.id;
    var c = new Card({id: c_id});
    c.avatar = "user_avatar_syy1gy";
    //c.avatar_uri = '';
    //c.avatar_url = $scope.defaultAvatar;
    c.$update(function(c) {
      $scope.card.avatar = c.avatar;
      //$scope.card.avatar_url = $scope.defaultAvatar;
      $scope.resetAvatar();
    });
  };

  $scope.resetAvatar = function() {
    if ($scope.oldAvatarUrl) {
      $scope.card.avatar_url = $scope.oldAvatarUrl;
      $scope.oldAvatarUrl = null;
    }
    $scope.promptDelete = false;
    $scope.promptEdit = false;
  };

  $scope.showMessagesFor = function() {
    $scope.notes = [];
    $scope.newNote.time = new Date();

    Restangular.one("cards", $scope.card.id).getList("notes").then(function(resp) {
      $scope.notes= resp;
    });
  };

  $scope.addNote = function() {
    Restangular.one("cards", $scope.card.id)
    .all("notes")
    .post({note: {text: $scope.newNote.text}})
    .then(function(resp) {
      $scope.newNote.added= new Date();
      $scope.newNote.text = "";
      $scope.notes.push({
        created_at: resp.created_at,
        id: resp.id,
        text: resp.text,
        username: resp.username
      });
    });
  };

  //TODO: Remove this, right?
  $scope.$watch("card", function(val) {
    var tags=[], parms={};
    cloudinary.getUploadAttrs($scope, $scope.card, parms);
  });
}]).
  controller("RejectCardCtrl", ["$scope", function($scope) {

    $scope.canRefund = function() {
      if (!$scope.order) return false;
      return /completed/i.test($scope.order.payment_status);
    };
}]);
