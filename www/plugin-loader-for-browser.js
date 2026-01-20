var event = require('cordova-plugin-google-maps-sdk.event'),
  BaseClass = require('cordova-plugin-google-maps-sdk.BaseClass'),
  BaseArrayClass = require('cordova-plugin-google-maps-sdk.BaseArrayClass'),
  execCmd = require('cordova-plugin-google-maps-sdk.commandQueueExecutor'),
  cordovaGoogleMaps = new(require('cordova-plugin-google-maps-sdk.js_CordovaGoogleMaps'))(execCmd);

module.exports = {
  event: event,
  Animation: {
    BOUNCE: 'BOUNCE',
    DROP: 'DROP'
  },
  BaseClass: BaseClass,
  BaseArrayClass: BaseArrayClass,
  Map: {
    getMap: cordovaGoogleMaps.getMap.bind(cordovaGoogleMaps)
  },
  StreetView: {
    getPanorama: cordovaGoogleMaps.getPanorama.bind(cordovaGoogleMaps),
    Source: {
      DEFAULT: 'DEFAULT',
      OUTDOOR: 'OUTDOOR'
    }
  },
  HtmlInfoWindow: require('cordova-plugin-google-maps-sdk.HtmlInfoWindow'),
  LatLng: require('cordova-plugin-google-maps-sdk.LatLng'),
  LatLngBounds: require('cordova-plugin-google-maps-sdk.LatLngBounds'),
  MapTypeId: require('cordova-plugin-google-maps-sdk.MapTypeId'),
  environment: require('cordova-plugin-google-maps-sdk.Environment'),
  Geocoder: require('cordova-plugin-google-maps-sdk.Geocoder')(execCmd),
  ElevationService: require('cordova-plugin-google-maps-sdk.ElevationService')(execCmd),
  DirectionsService: require('cordova-plugin-google-maps-sdk.DirectionsService')(execCmd),
  LocationService: require('cordova-plugin-google-maps-sdk.LocationService')(execCmd),
  geometry: {
    encoding: require('cordova-plugin-google-maps-sdk.encoding'),
    spherical: require('cordova-plugin-google-maps-sdk.spherical'),
    poly: require('cordova-plugin-google-maps-sdk.poly')
  }
};

cordova.addConstructor(function () {
  if (!window.Cordova) {
    window.Cordova = cordova;
  }
  window.plugin = window.plugin || {};
  window.plugin.google = window.plugin.google || {};
  window.plugin.google.maps = window.plugin.google.maps || module.exports;
});
