/// Estilo JSON de Google Maps alineado a la paleta Neon Steel Blue (#01203d).
const String googleMapNeonStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#01203d"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#c6f7fd"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#01203d"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#18e8bc"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#c6f7fd"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#082f4d"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#082f4d"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#18e8bc", "weight": 0.5}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#0a3a5c"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#ffffff"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#082f4d"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#001528"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#18e8bc"}]}
]
''';
