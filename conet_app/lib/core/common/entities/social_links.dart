import 'package:json_annotation/json_annotation.dart';

part 'social_links.g.dart';

@JsonSerializable()
class SocialLinks {
  final String name;
  final String link;

  SocialLinks({required this.name, required this.link});

  factory SocialLinks.fromJson(Map<String, dynamic> json) =>
      _$SocialLinksFromJson(json);

  Map<String, dynamic> toJson() => _$SocialLinksToJson(this);
}
