(function (factory) {
  'use strict';
  if (typeof define === 'function' && define.amd) {
    // Register as an anonymous AMD module:
    define([
      'jquery.cloudinary'
    ], factory);
  } else {
    // Browser globals:
    factory();
  }
}(function () {
  'use strict';

  angular.module('cloudinary', [])
  /**
   *
   * HTML:
   *
   * <img cl-image class="..." id="..."  height="..." data-crop="fit" public-id="cloudinaryPublicId"/>
   *
   */
  .directive('clImage', function() {
    return {
      restrict : 'EA',
      replace : true,
      transclude : false,
      scope : {
        publicId : "="
      },
      // The linking function will add behavior to the template
      link : function(scope, element, attrs) {
        scope.$watch('publicId', function(value) {
          if (!value) return;

          element.webpify({'src' : value + '.jpg'});
        });
      }
    };
  })
  .directive('clUploadNew', function($compile) {
    return {
restrict : 'EA',
         replace : false,
    scope : {
      data : "="
    },
    link : function(scope, element, attrs) {
      scope.uploadInProgress = false;
      scope.selectedFileName = '';

      scope.$watch('data', function(data) {

        if(data){

          var defaultData = {
            headers: {"X-Requested-With": "XMLHttpRequest"},
          };

          var addIndicator = function(propt){
            var bool      = propt == 'start',
            funcClone = data[propt] || function(){};
            return function(){
              scope.uploadInProgress = bool;
              scope.selectedFileName = scope.uploadInProgress ? 'Uploading...' : '';
              funcClone.apply(this, arguments);
            };
          };

          data.start = addIndicator('start');
          data.done  = addIndicator('done');

          data.add = function (e, data) {
            scope.uploadErrors =  [];

            var acceptFileTypes = /\/(pdf|png|gif|jpeg|jpg)$/i;
            if(data.originalFiles[0]['type'].length && !acceptFileTypes.test(data.originalFiles[0]['type'])) {
              scope.uploadErrors.push('File type not allowed');
            }

            console.log(data.originalFiles[0]['size']) ;
            if(data.originalFiles[0]['size'] > 2097152) {
              scope.uploadErrors.push('File size must be less than 2MB');
            }
            if(scope.uploadErrors.length > 0) {
              console.log(scope.uploadErrors.join("\n"));
            } else {
              scope.fileName = data.originalFiles[0]['name']
              data.submit();
            }};

            var wrapWithApply = function(callback) {
              return function(e, cbdata) {
                var phase = scope.$root.$$phase;
                if (phase == "$apply")
                  {
                    callback(e, cbdata);
                  } else {
                    scope.$apply(function() {
                      callback(e, cbdata);
                    });
                  }
              }
            }

            // This wraps each function in data with an angular $apply()
            // so that changes to scoped variables will be recognized.
            for (var propt in data) {
              if (typeof(data[propt]) === "function") {
                data[propt] = wrapWithApply(data[propt]);
              }
            }

            var completeData = angular.extend(defaultData, data);

            element.cloudinary_fileupload(
              completeData
            );

        }
      });
    }

    };
  })
  .directive('clUpload', function($compile) {
    /**
     *
     * HTML:
     *
     * <div id="photo-upload-btn" class="photo-upload-btn" cl-upload data="cloudinaryData"/>
     *
     * JavaScript:
     *
     *  cloudinaryData = {
     *    url: 'https://api.cloudinary.com/v1_1/YOUR_CLOUD_NAME/auto/upload',
     *    formData : {
     *       timestamp : 1375363550;
     *       tags : sampleTag,
     *       api_key : YOUR_API_KEY,
     *       callback : URL TO cloudinary_cors.html,
     *       signature : '53ebfe998d4018c3329aba08237d23f7458851a5'
     *    }
     *    start : function() { ... },
     *    progress : function() { ... },
     *    done : function() { ... }
     *  }
     *
     *  The start, progress, and done functions are optional callbacks. Other jquery.fileupload callbacks
     *  should be supported, but are untested.
     *
     *  Functions are automatically wrapped in scope.$apply() so it is safe to change variable values
     *  in your callbacks.
     *
     */
    return {
restrict : 'EA',
         replace : true,
         //template : '<input name="file" type="file" class="cloudinary-fileupload" data-cloudinary-field="image_id" />',

    template :  '<div class="file-inputs">'+
      '    <input name="file" type="file" class="cloudinary-fileupload hidden-input" data-cloudinary-field="image_id" ng-disabled="uploadInProgress" />'+
      '    <div class="fake-input">'+
      '        <button type="button" class="btn" ng-hide="uploadInProgress">Choose File</button>'+
      '        <i class="icn-spinner icn-blue medium ng-hide" ng-show="uploadInProgress"></i>'+
      '        <input class="fake-path" placeholder="No file chosen" value="{{selectedFileName}}" />'+
      '    </div>'+
      '    <ul style="margin-top: .5em; color: red">' +
      '      <li ng-repeat="error in uploadErrors">{{error}}</li>' +
      '    </ul>' +
      '</div>',
    scope : {
      data : "="
    },
    // The linking function will add behavior to the template
    link : function(scope, element, attrs) {
      scope.uploadInProgress = false;
      scope.selectedFileName = '';

      scope.$watch('data', function(data) {

        if(data){

          var defaultData = {
            headers: {"X-Requested-With": "XMLHttpRequest"},
          };

          var addIndicator = function(propt){
            var bool      = propt == 'start',
            funcClone = data[propt] || function(){};
            return function(){
              scope.uploadInProgress = bool;
              scope.selectedFileName = scope.uploadInProgress ? 'Uploading...' : '';
              funcClone.apply(this, arguments);
            };
          };

          data.start = addIndicator('start');
          data.done  = addIndicator('done');

          data.add = function (e, data) {
            scope.uploadErrors =  [];

            var acceptFileTypes = /\/(pdf|png|gif|jpeg|jpg)$/i;
            if(data.originalFiles[0]['type'].length && !acceptFileTypes.test(data.originalFiles[0]['type'])) {
              scope.uploadErrors.push('File type not allowed');
            }

            console.log(data.originalFiles[0]['size']) ;
            if(data.originalFiles[0]['size'] > 2097152) {
              scope.uploadErrors.push('File size must be less than 2MB');
            }
            if(scope.uploadErrors.length > 0) {
              console.log(scope.uploadErrors.join("\n"));
            } else {
              data.submit();
            }};

            var wrapWithApply = function(callback) {
              return function(e, cbdata) {
                var phase = scope.$root.$$phase;
                if (phase == "$apply")
                  {
                    callback(e, cbdata);
                  } else {
                    scope.$apply(function() {
                      callback(e, cbdata);
                    });
                  }
              }
            }

            // This wraps each function in data with an angular $apply()
            // so that changes to scoped variables will be recognized.
            for (var propt in data) {
              if (typeof(data[propt]) === "function") {
                data[propt] = wrapWithApply(data[propt]);
              }
            }

            var completeData = angular.extend(defaultData, data);

            element.cloudinary_fileupload(
              completeData
            );

        }
      });
    }

    };
  })
  .config(function() {
    $.cloudinary.config(CLOUDINARY_CONFIG);
  });
}));
