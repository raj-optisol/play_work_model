// Karma configuration
// Generated on Tue Feb 11 2014 08:46:18 GMT-0500 (EST)

module.exports = function(config) {
  config.set({

    // base path, that will be used to resolve files and exclude
    basePath: '',


    // frameworks to use
    frameworks: ['jasmine'],


    // list of files / patterns to load in the browser
    files: [
     
	'../lib/jquery.js',
	'../lib/jquery-ui-1.10.2.custom.js',
	'../lib/vendor/jquery.fileupload.js',
	'../lib/jasmine-jquery.js',  
	'../lib/sinon-1.8.2.js',  
	'../lib/jquery.cloudinary.js',  
      '../lib/angular/angular.js',
      '../lib/angular/angular-mocks.js',
      '../lib/angular/angular-resource.js',
      '../lib/angular/angular-animate.min.js',
      '../lib/angular/angular-ui-states.js',
      '../lib/angular/angular-ui-router.js',
      '../lib/angular/angular-ui-event.js',
      '../lib/angular/angular-ui-map.js',
      '../lib/angular/angular-ui-unique.js',
      '../lib/angular/ng-grid.debug.js',
      '../lib/vendor/angular.cloudinary.js',
      '../lib/vendor/leaflet.js',
      '../lib/vendor/leaflet-google.js',
      '../lib/vendor/angular-leaflet-directive.min.js',
      '../lib/vendor/restangular.min.js',
      '../lib/vendor/underscore-min.js',
      '../lib/application/services.js',
      '../lib/application/directives.js',
      '../lib/application/**/*.js',
      '../unit/**/*.js'
    ],


    // list of files to exclude
    exclude: [
      '**/*.swp',
      '**/*.swo'
    ],


    // test results reporter to use
    // possible values: 'dots', 'progress', 'junit', 'growl', 'coverage'
    reporters: ['progress'],


    // web server port
    port: 9876,


    // enable / disable colors in the output (reporters and logs)
    colors: true,


    // level of logging
    // possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO,


    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: true,


    // Start these browsers, currently available:
    // - Chrome
    // - ChromeCanary
    // - Firefox
    // - Opera (has to be installed with `npm install karma-opera-launcher`)
    // - Safari (only Mac; has to be installed with `npm install karma-safari-launcher`)
    // - PhantomJS
    // - IE (only Windows; has to be installed with `npm install karma-ie-launcher`)
    browsers: ['Chrome'],


    // If browser does not capture in given timeout [ms], kill it
    captureTimeout: 60000,


    // Continuous Integration mode
    // if true, it capture browsers, run tests and exit
    singleRun: false
  });
};
