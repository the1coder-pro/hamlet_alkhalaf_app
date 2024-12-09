// lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hamlet_alkhalaf_app/color_schemes.dart';
import 'package:hamlet_alkhalaf_app/contact_footer.dart';
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
      title: 'Questions & Answers App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          textTheme: textTheme,
          appBarTheme: const AppBarTheme(
              titleTextStyle: TextStyle(
                fontFamily: "Zarids",
                fontSize: 25,
              )),
          colorScheme: lightColorScheme, useMaterial3: true),
      darkTheme: ThemeData(
        textTheme: textTheme,
        appBarTheme: const AppBarTheme(
            titleTextStyle: TextStyle(
              fontFamily: "Zarids",
              fontSize: 25,
            )),
        colorScheme: darkColorScheme,
        useMaterial3: true,
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

  int _selectedPage = 0;
  List<String> pages = ['المعلمين', 'الإعلانات', 'الإعدادات'];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title:
              Text(pages[_selectedPage]),
          centerTitle: true,
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
        ),
        drawer: Drawer(


          child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer),
                child: Text.rich(TextSpan(children: [
                  TextSpan(
                    text: "حج التمتع\n",
                    style: TextStyle(
                      fontFamily: "Zarids",
                      fontSize: 35,
                      color:
                      Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: "في سؤال وجواب",
                    style: TextStyle(
                      fontFamily: "Zarids",
                      fontSize: 25,
                      color:
                      Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ])),
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text(
                  'المعلمين',
                  style: TextStyle(fontFamily: "Zarids", fontSize: 25),
                ),
                onTap: () {
                  setState(() {
                    _selectedPage = 0;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.new_releases),
                title: const Text(
                  'الإعلانات',
                  style: TextStyle(fontFamily: "Zarids", fontSize: 25),
                ),
                onTap: () {
                  setState(() {
                    _selectedPage = 1;

                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark),
                title: const Text(
                  'المفضلة',
                  style: TextStyle(fontFamily: "Zarids", fontSize: 25),
                ),
                onTap: () {
                  setState(() {
                    _selectedPage = 3;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text(
                  'الإعدادات',
                  style: TextStyle(fontFamily: "Zarids", fontSize: 25),
                ),
                onTap: () {
                  setState(() {
                    _selectedPage = 2;
                  });

                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _selectedPage == 0
                ? Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ListView.builder(
                          itemCount: instructors.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(instructors[index].name,
                                  style: const TextStyle(fontFamily: "Zarids",
                                    fontSize: 25)),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MainTitleSelectionScreen(
                                            instructor: instructors[index]),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const ContactFooter(),
                    ],
                  )
                : _selectedPage == 1
                    ? ListView(
                        children: [],
                      )
                    : ListView(
                        children: [
                          SwitchListTile(
                              value: false,
                              title: const Text("الوضع الداكن"),
                              onChanged: (value) {})
                        ],
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
          title: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("- ${instructor.name} -",
                    style: const TextStyle(fontSize: 22)),
                const Text("اختر القسم",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
              ],
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2),
            itemCount: instructor.mainTitles.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(10),
                child: Card.outlined(

                  surfaceTintColor: Theme.of(context).colorScheme.primaryFixed,
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.5),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    splashFactory: InkRipple.splashFactory,
                    child: Center(
                        child: Text(instructor.mainTitles[index].title,
                          style: TextStyle(
                              color:
                              Theme.of(context).colorScheme.primary,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Zarids"))),
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
          title: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mainTitle.title, style: const TextStyle(fontSize: 22)),
                const Text("اختر القسم الفرعي",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
              ],
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2),
            itemCount: mainTitle.subTitles.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(10),
                child: Card.outlined(
                  surfaceTintColor: Theme.of(context).colorScheme.primaryFixed,
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    child: Center(
                        child: Text(mainTitle.subTitles[index].title,
                            style: TextStyle(
                                color:
                                Theme.of(context).colorScheme.primary,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                fontFamily: "Zarids"))),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuestionSelectionScreen(
                              subTitle: mainTitle.subTitles[index]),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
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
          title: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(subTitle.title, style: const TextStyle(fontSize: 22)),
                const Text("اختر المسألة",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
              ],
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: ListView.builder(
            itemCount: subTitle.questions.length,
            itemBuilder: (context, index) {
              final question = subTitle.questions[index];

              return Padding(
                padding: const EdgeInsets.all(15),
                child: Card.filled(
                  color: Theme.of(context).colorScheme.surfaceBright,
                  // rounded
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),

                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              QuestionDetailScreen(question: question),
                        ),
                      );
                    },
                    child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                width: 2)),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    question.subTitle,
                                    style: TextStyle(
                                        fontFamily: "Zarids",
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    // if the question is bookmarked, show the bookmarked icon if not show the normal icon
                                    icon:
                                    false
                                        ? const Icon(Icons.bookmark)
                                        : const Icon(Icons.bookmark_border),
                                    onPressed: () {

                                    },
                                  )
                                ],
                              ),
                              Text(
                                question.question,
                                style: TextStyle(
                                    fontFamily: "Zarids",
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Chip(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                    padding: const EdgeInsets.all(4),
                                    label: Text(
                                      question.mainTitle,
                                      style: TextStyle(
                                          fontFamily: "Zarids",
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSecondaryContainer,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )),
                  ),
                ),
              );
            },
          ),
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
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                  onPressed: () async {
                    // Share the question
                    // open the link of the question
                    // launchUrl(Uri.parse('${Uri.base}questionid/${question.number}'));

                    // open share
                    final result = await Share.share('''
                ${question.mainTitle}/${question.subTitle}
                
                ${question.question}
                
                الجواب: 
                ${question.answer}
                
                بجواب الشيخ: ${question.instructorName}
                
                للمزيد من المعلومات قم بزيارة الموقع
                ${Uri.base}questionid/${question.number}
                ''', subject: question.question);

                    if (result.status == ShareResultStatus.success) {
                      debugPrint('Thank you for sharing my website!');
                    }
                  },
                  icon: const Icon(Icons.share)),
            )
          ],
        ),
        body: Padding(
          padding:
              const EdgeInsets.only(right: 16, left: 16, bottom: 16, top: 10),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children:  [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                        alignment: Alignment.centerRight,
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(
                                text: "${question.mainTitle!} / ",
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall!
                                    .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary)),
                            TextSpan(
                                text: question.subTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall!
                                    .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary)),
                          ]),
                        )),
                  ],
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(question.question!.trim(),
                        textAlign: TextAlign.right,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                            fontFamily: "Zarids",
                            fontSize: 35,
                            fontWeight: FontWeight.w300,
                            height: 1.2)),
                  ),
                ),
                const SizedBox(height: 10),
                //if (isAudioFileThere) questionAudioPlayer(context),
                SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: Card.outlined(
                      elevation: 0,
                      // squared
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer,
                      child: Center(
                        child: Text("نص الجواب",
                            style: TextStyle(
                                fontSize: 20,
                                fontFamily: "Zarids",
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary)),
                      ),
                    )),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: Card.outlined(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Text(
                                question.answer ??
                                    "لا يوجد نص جواب",
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontFamily: "Zarids",
                                    fontWeight: FontWeight.w400
                                   )),

                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
