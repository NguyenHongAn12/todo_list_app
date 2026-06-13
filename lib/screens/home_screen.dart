import 'package:flutter/material.dart';

import '../models/task.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final FocusNode titleFocus = FocusNode();

  bool isLoading = false;
  List<Task> tasks = [];
  String selectedFilter = 'All';
  String selectedSort = 'Newest';

  final List<String> tabLabels = ['All', 'Completed', 'Incomplete'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabLabels.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Todo Manager'),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: widget.isDarkMode
                  ? 'Switch to light mode'
                  : 'Switch to dark mode',
              icon: Icon(
                widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: widget.onToggleTheme,
            ),
          ],
          bottom: TabBar(
            tabs: tabLabels.map((label) => Tab(text: label)).toList(),
            onTap: (index) {
              setState(() {
                selectedFilter = tabLabels[index];
              });
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummarySection(),
                const SizedBox(height: 16),
                _buildTaskForm(),
                const SizedBox(height: 16),
                _buildSearchAndSort(),
                const SizedBox(height: 16),
                Expanded(child: _buildTaskList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    searchController.dispose();
    titleFocus.dispose();
    super.dispose();
  }

  Widget _buildSearchAndSort() {
    return Row(
      children: [
        Expanded(child: _buildSearchBar()),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: selectedSort,
          items: const [
            DropdownMenuItem(value: 'Newest', child: Text('Newest')),
            DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              selectedSort = v;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    final total = tasks.length;
    final completed = tasks.where((task) => task.isCompleted).length;
    final incomplete = total - completed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSummaryTile('Total', total.toString(), Colors.indigo),
        _buildSummaryTile('Completed', completed.toString(), Colors.green),
        _buildSummaryTile('Pending', incomplete.toString(), Colors.orange),
      ],
    );
  }

  Widget _buildSummaryTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: titleController,
                focusNode: titleFocus,
                decoration: const InputDecoration(labelText: 'Task title'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addTask,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Add Task'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: searchController,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Search tasks',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  List<Task> get _filteredTasks {
    final query = searchController.text.trim().toLowerCase();
    return tasks.where((task) {
      final matchesQuery =
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query);
      final matchesFilter =
          selectedFilter == 'All' ||
          (selectedFilter == 'Completed' && task.isCompleted) ||
          (selectedFilter == 'Incomplete' && !task.isCompleted);
      return matchesQuery && matchesFilter;
    }).toList();
  }

  List<Task> _sortedTasks(List<Task> list) {
    final copy = List<Task>.from(list);
    if (selectedSort == 'Newest') {
      copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      copy.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    return copy;
  }

  Widget _buildTaskList() {
    final visibleTasks = _filteredTasks;

    if (visibleTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No tasks yet',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first task using the form above.',
              style: TextStyle(color: Colors.black45),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => titleFocus.requestFocus(),
              child: const Text('Add First Task'),
            ),
          ],
        ),
      );
    }

    final sorted = _sortedTasks(visibleTasks);
    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final task = sorted[index];
        final originalIndex = tasks.indexOf(task);
        return _buildTaskCard(task, originalIndex);
      },
    );
  }

  Widget _buildTaskCard(Task task, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: task.isCompleted
            ? Colors.green.withValues(alpha: 0.06)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => _toggleTask(index),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty) ...[
              Text(task.description),
              const SizedBox(height: 6),
            ],
            Text(
              'Created: ${task.createdAt.day.toString().padLeft(2, '0')}/'
              '${task.createdAt.month.toString().padLeft(2, '0')}/'
              '${task.createdAt.year}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editTask(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _deleteTask(index),
            ),
          ],
        ),
      ),
    );
  }

  void _editTask(int index) {
    final task = tasks[index];
    final titleCtrl = TextEditingController(text: task.title);
    final descCtrl = TextEditingController(text: task.description);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Task'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter title' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              setState(() {
                task.title = titleCtrl.text.trim();
                task.description = descCtrl.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addTask() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      tasks.add(
        Task(
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          createdAt: DateTime.now(),
          isCompleted: false,
        ),
      );
      titleController.clear();
      descriptionController.clear();
    });
    // Show snackbar with undo for convenience
    final addedIndex = tasks.length - 1;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task added'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              if (addedIndex >= 0 && addedIndex < tasks.length) {
                tasks.removeAt(addedIndex);
              }
            });
          },
        ),
      ),
    );
  }

  void _toggleTask(int index) {
    setState(() {
      tasks[index].isCompleted = !tasks[index].isCompleted;
    });
  }

  void _deleteTask(int index) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm delete'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true) return;
      final removed = tasks[index];
      setState(() {
        tasks.removeAt(index);
      });
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Task deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              setState(() {
                tasks.insert(index, removed);
              });
            },
          ),
        ),
      );
    });
  }
}
