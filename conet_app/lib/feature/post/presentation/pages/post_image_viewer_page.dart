import 'package:conet_app/core/widgets/loader.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PostImageViewerPage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const PostImageViewerPage({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<PostImageViewerPage> createState() => _PostImageViewerPageState();
}

class _PostImageViewerPageState extends State<PostImageViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: Loader(
                          color: Colors.white,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.image,
                              size: 72,
                              color: Colors.white54,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const FaIcon(
                      FontAwesomeIcons.xmark,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.imageUrls.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentIndex + 1} of ${widget.imageUrls.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
