import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sattle_me/features/home/homepage/homepage.dart';
import 'package:sattle_me/features/home/profile/profile.dart';
import 'package:sattle_me/features/home/rental_service/pages/favorite_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ToDoScreen extends StatefulWidget {
  final String userId;
  const ToDoScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ToDoScreenState createState() => _ToDoScreenState();
}

class _ToDoScreenState extends State<ToDoScreen> {
  int _selectedIndex = 0;
  List<Map<String, String>> favoriteRentals = [];

  void _onItemTapped(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FavoritesPage(favoriteRentals: favoriteRentals),
        ),
      );
    } else if (index == 4) {
      // Profile Page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
      );
    } else if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  List<TaskCategory> taskCategories = [];
  late String todayDate;
  late int todayIndex;
  bool allTasksCompleted = false;

  @override
  void initState() {
    super.initState();
    todayDate = DateFormat('yyyy/MM/dd').format(DateTime.now());
    todayIndex = DateTime.now().weekday - 1;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      taskCategories = [
        TaskCategory("First Step", [
          Task("Book A Room", isUnlocked: true),
          Task("Find Ride"),
        ]),
        TaskCategory("PERSONAL", [Task("Made SIN"), Task("Open Bank Account")]),
        TaskCategory("Others", [Task("Transit Information"), Task("Library")]),
        TaskCategory("TAX FILING", [
          Task(
            "Tax filing Done or Book a professional Tax filer",
            isUnlocked: _shouldUnlockTaxFiling(),
          ),
        ]),
      ];
    });

    await _loadSavedTasks();
  }

  bool _shouldUnlockTaxFiling() {
    DateTime unlockDate = DateTime(2025, 2, 30);
    int categoryCount = taskCategories.length;
    int checkLimit = categoryCount >= 3 ? 3 : categoryCount;

    bool allPreviousTasksCompleted = taskCategories
        .sublist(0, checkLimit)
        .every((category) => category.tasks.every((task) => task.isCompleted));

    return DateTime.now().isAfter(unlockDate) && allPreviousTasksCompleted;
  }

  Future<void> _onTaskChecked() async {
    for (int i = 0; i < taskCategories.length - 1; i++) {
      bool categoryCompleted = taskCategories[i].tasks.every(
        (task) => task.isCompleted,
      );

      for (int j = 0; j < taskCategories[i].tasks.length; j++) {
        if (taskCategories[i].tasks[j].isCompleted &&
            j + 1 < taskCategories[i].tasks.length) {
          taskCategories[i].tasks[j + 1].isUnlocked = true;
        }
      }

      if (categoryCompleted && i + 1 < taskCategories.length - 1) {
        taskCategories[i + 1].tasks.first.isUnlocked = true;
      }
    }

    if (_shouldUnlockTaxFiling()) {
      setState(() {
        taskCategories.last.tasks.first.isUnlocked = true;
      });
    }

    allTasksCompleted = taskCategories.every(
      (category) => category.tasks.every((task) => task.isCompleted),
    );

    await _saveTaskCompletion();
    setState(() {});
  }

  Future<void> _saveTaskCompletion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (var category in taskCategories) {
      for (var task in category.tasks) {
        await prefs.setBool(
          '${widget.userId}_${task.title}_completed',
          task.isCompleted,
        );
        await prefs.setBool(
          '${widget.userId}_${task.title}_unlocked',
          task.isUnlocked,
        );
      }
    }
  }

  Future<void> _loadSavedTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (var category in taskCategories) {
      for (var task in category.tasks) {
        task.isCompleted =
            prefs.getBool('${widget.userId}_${task.title}_completed') ?? false;
        task.isUnlocked =
            prefs.getBool('${widget.userId}_${task.title}_unlocked') ??
            task.isUnlocked;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Today",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDateSelector(),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    for (var category in taskCategories)
                      _buildTaskCategory(category),
                    if (allTasksCompleted) _buildCompletionMessage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.grey,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: ''),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(10),
              child: Icon(Icons.add, color: Colors.white),
            ),
            label: '',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
        ],
      ),
    );
  }

  Widget _buildCompletionMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "🎉 Good job! You've completed all tasks.",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "See you soon!",
            style: TextStyle(fontSize: 16, color: Colors.green[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    List<String> days = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];
    List<int> dates = [];

    DateTime now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      dates.add(now.subtract(Duration(days: now.weekday - 1 - i)).day);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(days.length, (index) {
        bool isSelected = index == todayIndex;
        return Column(
          children: [
            Text(days[index], style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.brown[100] : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dates[index].toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTaskCategory(TaskCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          category.name.toUpperCase(),
          style: TextStyle(
            color: Colors.brown,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: category.tasks.map((task) => _buildTaskItem(task)).toList(),
        ),
      ],
    );
  }

  Widget _buildTaskItem(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged:
                task.isUnlocked
                    ? (value) {
                      setState(() {
                        task.isCompleted = value!;
                        _onTaskChecked();
                      });
                    }
                    : null,
          ),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                color: task.isUnlocked ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Task {
  final String title;
  bool isCompleted;
  bool isUnlocked;

  Task(this.title, {this.isCompleted = false, this.isUnlocked = false});
}

class TaskCategory {
  final String name;
  final List<Task> tasks;

  TaskCategory(this.name, this.tasks);
}
