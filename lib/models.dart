// lib/models.dart
class Instructor {
  final String name;
  final List<MainTitle> mainTitles;

  Instructor({required this.name, required this.mainTitles});

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      name: json['instructorName'],
      mainTitles: [],
    );
  }

  void addMainTitle(MainTitle mainTitle) {
    mainTitles.add(mainTitle);
  }
}

class MainTitle {
  final String title;
  final List<SubTitle> subTitles;

  MainTitle({required this.title, required this.subTitles});

  factory MainTitle.fromJson(Map<String, dynamic> json) {
    return MainTitle(
      title: json['mainTitle'],
      subTitles: [],
    );
  }

  void addSubTitle(SubTitle subTitle) {
    subTitles.add(subTitle);
  }
}

class SubTitle {
  final String title;
  final List<Question> questions;

  SubTitle({required this.title, required this.questions});

  factory SubTitle.fromJson(Map<String, dynamic> json) {
    return SubTitle(
      title: json['subTitle'],
      questions: [],
    );
  }

  void addQuestion(Question question) {
    questions.add(question);
  }
}

class Question {
  final int number;
  final String question;
  final String answer;
  final String instructorName;
  final String mainTitle;
  final String subTitle;

  Question({
    required this.number,
    required this.question,
    required this.answer,
    required this.instructorName,
    required this.mainTitle,
    required this.subTitle,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      number: json['number'],
      question: json['question'],
      answer: json['answer'],
      instructorName: json['instructorName'],
      mainTitle: json['mainTitle'],
      subTitle: json['subTitle'],
    );
  }
}
