import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../application/place_geojson_builder.dart';
import '../domain/map_place.dart';
import 'pro_map_place_widgets.dart';

/// Renders the Pro map's place markers as style images: a round photo in a
/// ring of the place-type colour with a pointer underneath, or a type badge
/// (colour + icon) when a place has no photo or its photo fails to load.
///
/// Rendered PNGs ([MbxImage.data] is PNG-encoded) are cached for the
/// screen's lifetime so a base-style switch, which drops every style image,
/// re-adds them instantly.
class ProMapPlaceMarkers {
  static const _logicalSize = 46.0;
  static const _pixelRatio = 3.0;
  static const _pointer = 7.0;

  final _rendered = <String, MbxImage>{};
  final _photos = <String, Future<MbxImage?>>{};

  /// Adds every marker to [style]. Type badges go in first, also under
  /// each photo marker's id, so something shows at once; photos replace
  /// them as they arrive.
  Future<void> addTo(StyleManager style, List<MapPlace> places) async {
    final types = {
      ...ProMapPlaceTypes.known.keys,
      ...places.map((place) => place.type),
    };
    for (final type in types) {
      final id = PlaceGeoJsonBuilder.typeMarkerId(type);
      await _add(style, id, await _badge(type));
    }
    await Future.wait([
      for (final place in places)
        if (place.thumbnailUrl case final url?)
          _addPhoto(style, place, url),
    ]);
  }

  Future<void> _addPhoto(
    StyleManager style,
    MapPlace place,
    String url,
  ) async {
    final id = PlaceGeoJsonBuilder.markerIdFor(place);
    await _add(style, id, _rendered[id] ?? await _badge(place.type));
    final photo = await (_photos[id] ??= _renderPhoto(url, place.type));
    if (photo != null) await _add(style, id, photo);
  }

  Future<void> _add(StyleManager style, String id, MbxImage image) async {
    _rendered[id] = image;
    await style.addStyleImage(id, _pixelRatio, image, false, [], [], null);
  }

  Future<MbxImage> _badge(String type) async {
    final key = PlaceGeoJsonBuilder.typeMarkerId(type);
    final cached = _rendered[key];
    if (cached != null) return cached;
    return _draw(type, (canvas, rect) {
      canvas.drawOval(rect, Paint()..color = ProMapPlaceTypes.colorFor(type));
      final icon = ProMapPlaceTypes.iconFor(type);
      final painter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            fontSize: rect.width * 0.55,
            color: Colors.white,
          ),
        ),
      )..layout();
      painter.paint(
        canvas,
        rect.center - Offset(painter.width / 2, painter.height / 2),
      );
    });
  }

  Future<MbxImage?> _renderPhoto(String url, String type) async {
    final photo = await _loadImage(url);
    if (photo == null) return null;
    return _draw(type, (canvas, rect) {
      canvas.save();
      canvas.clipPath(Path()..addOval(rect));
      final side = math.min(photo.width, photo.height).toDouble();
      final src = Rect.fromCenter(
        center: Offset(photo.width / 2, photo.height / 2),
        width: side,
        height: side,
      );
      canvas.drawImageRect(
        photo,
        src,
        rect,
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
    });
  }

  /// Shadow, white border, type-colour ring and pointer, with [paintInner]
  /// filling the circle inside the ring.
  Future<MbxImage> _draw(
    String type,
    void Function(Canvas canvas, Rect inner) paintInner,
  ) async {
    const size = _logicalSize * _pixelRatio;
    const pointer = _pointer * _pixelRatio;
    const pad = 3 * _pixelRatio;
    final width = (size + pad * 2).ceil();
    final height = (size + pointer + pad * 2).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(width / 2, pad + size / 2);
    final outer = Rect.fromCircle(center: center, radius: size / 2);
    final ringColor = ProMapPlaceTypes.colorFor(type);

    final tip = Path()
      ..moveTo(center.dx - pointer, center.dy + size / 2 - pointer * 0.6)
      ..lineTo(center.dx, center.dy + size / 2 + pointer)
      ..lineTo(center.dx + pointer, center.dy + size / 2 - pointer * 0.6)
      ..close();
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2 * _pixelRatio);
    canvas.drawOval(outer.shift(const Offset(0, _pixelRatio)), shadow);
    canvas.drawPath(tip, Paint()..color = Colors.white);
    canvas.drawOval(outer, Paint()..color = Colors.white);
    canvas.drawOval(
      outer.deflate(2 * _pixelRatio),
      Paint()..color = ringColor,
    );
    paintInner(canvas, outer.deflate(4.5 * _pixelRatio));

    final image = await recorder.endRecording().toImage(width, height);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return MbxImage(
      width: width,
      height: height,
      data: png!.buffer.asUint8List(),
    );
  }

  static Future<ui.Image?> _loadImage(String url) {
    final completer = Completer<ui.Image?>();
    final stream = NetworkImage(url).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (error, stackTrace) {
        if (!completer.isCompleted) completer.complete(null);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
  }
}
