/// Input payload for the scout "About Me" profile step.
class ScoutProfileInput {
  final String bio;
  final List<String> tags;

  const ScoutProfileInput({required this.bio, required this.tags});

  Map<String, dynamic> toMap() => {
    'bio': bio,
    'tags': tags.join(','),
    'status': 'active',
  };
}
