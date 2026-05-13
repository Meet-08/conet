import 'package:conet_app/feature/message/domain/entities/shared_media_item.dart';
import 'package:equatable/equatable.dart';

class SharedContentPage extends Equatable {
  final List<SharedMediaItem> items;
  final bool hasMore;
  final DateTime? nextBefore;

  const SharedContentPage({
    required this.items,
    required this.hasMore,
    this.nextBefore,
  });

  @override
  List<Object?> get props => [items, hasMore, nextBefore];
}
