abstract class BaseEntity {
  final String? id;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  BaseEntity({this.id, this.createdAt, this.updatedAt, this.deletedAt});
}
