// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//
// Vendor assets
//= require imagesloaded.pkgd.min
//= require marked.min
//= require simplemde.min
//= require jquery-ui.min
//= require highcharts
//= require tag-it
//= require select2.full
//
//= require ./application.js
//= require ./merge_requests.js
//= require ./projects.js
//= require ./serviceworker-companion.js

// "It's not advisable to add code directly here..." bla bla bla... but I did it!! Yeah!!
var alreadyTriedToRegisterNotifications = false;
var ready = function() {
  var func = window[document.body.dataset.whoAmI];
  if (func)
    func();

  $(".markdown").each(function(idx, item) {
      item.innerHTML = marked(item.textContent, { sanitize: true });
  });

  $('.select2select').each(function(idx, item) {
    $(item).select2({ allowClear: true, placeholder: item.dataset.placeholder});
  });

  // If we are not in a devise layout
  if (!alreadyTriedToRegisterNotifications && document.body.className !== "devise") {
    registerWebPushNotifications();
    alreadyTriedToRegisterNotifications = true
  }
}
$(document).ready(ready);
$(document).on('page:load', ready);
//= require serviceworker-companion
