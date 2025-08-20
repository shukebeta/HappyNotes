import 'dart:math';

class HappyNotesPrompts {
  HappyNotesPrompts._();
  static final List<String> _privateQuestions = [
    'What made you smile today?',
    'What\'s one thing you\'re grateful today?',
    'What\'s a moment that brought you joy?',
    'What\'s a goal you accomplished recently?',
    'What\'s something new you learned today?',
    'How did you overcome a challenge today?',
    'What\'s a kind act you witnessed today?',
    'What\'s a kind act you performed today?',
    'What\'s a favorite quote that inspires you?',
    'What\'s a favorite saying that inspires you?',
    'Describe a place you visited today.',
    'What\'s a small victory you had today?',
    'What\'s something you\'re looking forward to?',
    'What\'s a piece of advice you feel helpful?'
  ];

  static final List<String> _publicQuestions = [
    'What\'s a helpful tip you discovered recently?',
    'What\'s a helpful life hack you discovered recently?',
    'What book would you recommend and why?',
    'What movie would you recommend and why?',
    'What\'s a memorable experience you had recently?',
    'What\'s a piece of advice worth sharing today?',
    'What\'s a hobby that you love to share?',
    'What\'s an activity you love to share?',
    'What\'s an interesting fact you learned today?',
    'What\'s a piece of trivia you learned today?',
    'What\'s a recipe you tried recently?',
    'What\'s a dish you tried that others might like?',
    'What\'s a place you visited that is wonderful?',
    'What\'s a quote or saying that motivates you and why?',
    'What\'s a quote that motivates you and why?',
    'What\'s a saying that motivates you and why?',
    'What\'s a product you recently used and would recommend?',
    'What\'s a service you recently used and would recommend?'
  ];

  static String getRandom(bool isPrivate) {
    final random = Random();
    if (isPrivate) {
      return _privateQuestions[random.nextInt(_privateQuestions.length)];
    } else {
      return _publicQuestions[random.nextInt(_publicQuestions.length)];
    }
  }
}
