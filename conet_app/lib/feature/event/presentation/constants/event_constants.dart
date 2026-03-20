/// Event category with label & description for the dropdown.
class EventCategory {
  final String value;
  final String label;
  final String description;

  const EventCategory({
    required this.value,
    required this.label,
    required this.description,
  });
}

const List<EventCategory> eventCategories = [
  EventCategory(
    value: 'tech',
    label: 'Tech',
    description: 'Hackathons, coding contests, tech talks',
  ),
  EventCategory(
    value: 'workshop',
    label: 'Workshop',
    description: 'Hands-on learning sessions',
  ),
  EventCategory(
    value: 'webinar',
    label: 'Webinar',
    description: 'Online seminars and presentations',
  ),
  EventCategory(
    value: 'hackathon',
    label: 'Hackathon',
    description: 'Competitive coding and building',
  ),
  EventCategory(
    value: 'seminar',
    label: 'Seminar',
    description: 'Academic lectures and talks',
  ),
  EventCategory(
    value: 'competition',
    label: 'Competition',
    description: 'Contests and tournaments',
  ),
  EventCategory(
    value: 'cultural',
    label: 'Cultural',
    description: 'Fests, performances, exhibitions',
  ),
  EventCategory(
    value: 'social',
    label: 'Social',
    description: 'Meetups, networking, parties',
  ),
  EventCategory(value: 'other', label: 'Other', description: 'Anything else'),
];

const totalSteps = 5;
const stepTitles = [
  'Basic Details',
  'Event Details',
  'FAQs',
  'Organizer Details',
  'Review & Publish',
];
const stepSubtitles = [
  'Set the foundation for your event',
  'Tell us more about the experience',
  'Help attendees with common questions',
  'Set up your event organizer profile',
  'Check your event details before publishing',
];
