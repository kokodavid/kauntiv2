import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'interest_icons.dart';

/// An interest's icon: the uploaded image when [imageUrl] is set (SVG or
/// PNG, tinted [color] so a one-colour image follows the tile state),
/// otherwise the named app icon. While the image loads, or if it fails, the
/// named icon shows, so a tile never goes blank or waits on the network.
class InterestIcon extends StatelessWidget {
  const InterestIcon({
    super.key,
    required this.iconName,
    this.imageUrl,
    required this.color,
    this.size = 18,
  });

  final String iconName;
  final String? imageUrl;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final named = Icon(interestIconForName(iconName), size: size, color: color);
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) return named;
    final isSvg = Uri.tryParse(url)?.path.toLowerCase().endsWith('.svg');
    return SizedBox.square(
      dimension: size,
      child: isSvg == true
          ? _CachedSvg(url: url, color: color, size: size, placeholder: named)
          : CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.contain,
              color: color,
              colorBlendMode: BlendMode.srcIn,
              placeholder: (context, url) => named,
              errorWidget: (context, url, error) => named,
            ),
    );
  }
}

class _CachedSvg extends StatefulWidget {
  const _CachedSvg({
    required this.url,
    required this.color,
    required this.size,
    required this.placeholder,
  });

  final String url;
  final Color color;
  final double size;
  final Widget placeholder;

  @override
  State<_CachedSvg> createState() => _CachedSvgState();
}

class _CachedSvgState extends State<_CachedSvg> {
  late Future<File?> _file = _load();

  Future<File?> _load() async {
    try {
      // Disk cache first; downloads once.
      return await DefaultCacheManager().getSingleFile(widget.url);
    } on Object {
      return null;
    }
  }

  @override
  void didUpdateWidget(_CachedSvg old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) _file = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _file,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) return widget.placeholder;
        return SvgPicture.file(
          file,
          width: widget.size,
          height: widget.size,
          colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
          placeholderBuilder: (_) => widget.placeholder,
        );
      },
    );
  }
}
