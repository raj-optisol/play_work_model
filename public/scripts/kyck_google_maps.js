function defer(method) {
    if (window.App && window.App.rootScope && window.$)
    {
      method(window.$, window.App);
    }
    else
    {
      setTimeout(function() { defer(method) }, 500);
    }
}

defer(function($, app){

    window.onGoogleReady = function() {

       if(window.App)
       {
    
         var queue = angular.module('ui.map')._invokeQueue;
          for(var i=0;i<queue.length;i++) {
           var call = queue[i];
               // call is in the form [providerName, providerFunc, providerArguments]
           var provider = App.providers[call[0]];
           if(provider) {
                   // e.g. $controllerProvider.register("Ctrl", function() { ... })
           provider[call[1]].apply(provider, call[2]);
           }
         }
         App.rootScope.$broadcast("google-maps-loaded");

       }
       else
       {
         console.log("App does NOT exists");
       }
    
    }
	
		if (window.google) { 
		  
      var unregister = App.rootScope.$on("$viewContentLoaded",function(){
          App.rootScope.$broadcast("google-maps-loaded");		
          unregister();
      });

		}
		else
		{
		  $.getScript("https://maps.googleapis.com/maps/api/js?v=3.exp&sensor=false&callback=onGoogleReady", function(){
        // console.log("Script loaded and executed.");

      });
    }

});
		
