// lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart';

void main() {
  usePathUrlStrategy();

  runApp(const QuestionAnswerApp());
}

class QuestionAnswerApp extends StatelessWidget {
  const QuestionAnswerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Question Answer App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true
      ),
      initialRoute: "/",
      onGenerateRoute: (settings) {
        final settingsUri = Uri.parse(settings.name!);
        final questionNumber = settingsUri.pathSegments.last;

        if (settingsUri.pathSegments.contains('questionid') &&
            int.tryParse(questionNumber) != null) {
          // Load data and find the question by number
          return MaterialPageRoute(
            builder: (context) =>
                QuestionDetailLoader(questionNumber: int.parse(questionNumber)),
          );
        }

        return MaterialPageRoute(
          builder: (context) => const InstructorSelectionScreen(),
        );
      },
      routes: {
        "/": (context) => const InstructorSelectionScreen(),
      },
    );
  }
}

class QuestionDetailLoader extends StatefulWidget {
  final int questionNumber;

  const QuestionDetailLoader({super.key, required this.questionNumber});

  @override
  State<QuestionDetailLoader> createState() => _QuestionDetailLoaderState();
}

class _QuestionDetailLoaderState extends State<QuestionDetailLoader> {
  Question? question;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final jsonString = await rootBundle.loadString('assets/data.json');
    final jsonData = json.decode(jsonString) as List<dynamic>;
    final questions = jsonData.map((item) => Question.fromJson(item)).toList();

    setState(() {
      question =
          questions.where((q) => q.number == widget.questionNumber).first;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (question == null) {
      return const Scaffold(
        body: Center(child: Text('Question not found')),
      );
    }

    return QuestionDetailScreen(question: question!);
  }
}

class InstructorSelectionScreen extends StatefulWidget {
  const InstructorSelectionScreen({super.key});

  @override
  State<InstructorSelectionScreen> createState() =>
      _InstructorSelectionScreenState();
}

class _InstructorSelectionScreenState extends State<InstructorSelectionScreen> {
  List<Instructor> instructors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final jsonString = await rootBundle.loadString('assets/data.json');
    final jsonData = json.decode(jsonString) as List<dynamic>;
    final questions = jsonData.map((item) => Question.fromJson(item)).toList();
    _organizeData(questions);
  }

  void _organizeData(List<Question> questions) {
    final Map<String, Instructor> instructorMap = {};
    for (var question in questions) {
      if (!instructorMap.containsKey(question.instructorName)) {
        instructorMap[question.instructorName] =
            Instructor(name: question.instructorName, mainTitles: []);
      }
      var instructor = instructorMap[question.instructorName];
      var mainTitle = instructor!.mainTitles.firstWhere(
        (title) => title.title == question.mainTitle,
        orElse: () {
          var newMainTitle =
              MainTitle(title: question.mainTitle, subTitles: []);
          instructor.addMainTitle(newMainTitle);
          return newMainTitle;
        },
      );
      var subTitle = mainTitle.subTitles.firstWhere(
        (title) => title.title == question.subTitle,
        orElse: () {
          var newSubTitle = SubTitle(title: question.subTitle, questions: []);
          mainTitle.addSubTitle(newSubTitle);
          return newSubTitle;
        },
      );
      subTitle.addQuestion(question);
    }

    setState(() {
      instructors = instructorMap.values.toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Column(
            children: [
               Text('المعلمين', style: TextStyle(fontSize: 16)),
               Text("اختر المعلم", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
            ],
          ),
          centerTitle: true,

        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: instructors.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(instructors[index].name),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainTitleSelectionScreen(
                              instructor: instructors[index]),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class MainTitleSelectionScreen extends StatelessWidget {
  final Instructor instructor;

  const MainTitleSelectionScreen({super.key, required this.instructor});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        appBar: AppBar(
          title:  Column(
            children: [
              Text(instructor.name, style: const TextStyle(fontSize: 16 )),
              const Text("اختر القسم", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
            ],
          ),
          centerTitle: true,

        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
            itemCount: instructor.mainTitles.length,
            itemBuilder: (context, index) {
              return Card.outlined(
                elevation: 2,
                color: Theme.of(context).colorScheme.primaryContainer,

                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                child: InkWell(
      splashFactory: InkRipple.splashFactory,
                  child: Center(child: Text(instructor.mainTitles[index].title)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubTitleSelectionScreen(
                            mainTitle: instructor.mainTitles[index]),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class SubTitleSelectionScreen extends StatelessWidget {
  final MainTitle mainTitle;

  const SubTitleSelectionScreen({super.key, required this.mainTitle});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(mainTitle.title, style: const TextStyle(fontSize: 16)),
              const Text("اختر القسم الفرعي", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
            ],
          ),
          centerTitle: true,

        ),
        body: ListView.builder(
          itemCount: mainTitle.subTitles.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(mainTitle.subTitles[index].title),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuestionSelectionScreen(
                        subTitle: mainTitle.subTitles[index]),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class QuestionSelectionScreen extends StatelessWidget {
  final SubTitle subTitle;

  const QuestionSelectionScreen({super.key, required this.subTitle});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        appBar: AppBar(
          title:  Column(
            children: [
              Text(subTitle.title, style: const TextStyle(fontSize: 16)),
              const Text("اختر المسألة", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
            ],
          ),
          centerTitle: true,
        ),
        body: ListView.builder(
          itemCount: subTitle.questions.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(subTitle.questions[index].question),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        QuestionDetailScreen(question: subTitle.questions[index]),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class QuestionDetailScreen extends StatelessWidget {
  final Question question;

  const QuestionDetailScreen({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(

          centerTitle: true,

          actions: [
            Padding(
              padding: const EdgeInsets.only(left:8.0),
              child: IconButton(onPressed: () async {
                // Share the question
                // open the link of the question
                // launchUrl(Uri.parse('${Uri.base}questionid/${question.number}'));

                // open share
                final result = await Share.share('''
                المسألة رقم ${question.number}
                ${question.question}
                
                الجواب: 
                ${question.answer}
                
                للمزيد من المعلومات قم بزيارة الموقع
                ${Uri.base}questionid/${question.number}
                ''', subject: question.question);

                if (result.status == ShareResultStatus.success) {
                  debugPrint('Thank you for sharing my website!');
                }

              }, icon: const Icon(Icons.share)),
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(question.question,

                    style:
                        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(question.answer,
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
