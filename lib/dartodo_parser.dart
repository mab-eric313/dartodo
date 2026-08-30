import 'dart:io';

enum Priority {
  low, 
  med, 
  high;

  Priority? fromString(String value) {
    switch (value) {
      case 'LOW': return Priority.low;
      case 'MED': return Priority.med;
      case 'HIGH': return Priority.high;
      default: return null;
    }
  }
}

int todoNumber = 0;

class Todo {
  String task = '';
  String priority = ''; // LOW/MED/HIG/NONE
  String description = '';
  String filePath = '';
  int lineNumber = 0;

  Todo({
    required this.task,
    required this.priority,
    required this.description,
    required this.filePath,
    required this.lineNumber,
  });

  static List<Todo> parseAll(String fileContent, String filePath) {
    List<Todo> todos = [];

    RegExp regex = RegExp(
      r'(?:\/\/\s*(TODO)(?:\(([Ll][Oo][Ww]|[Mm][Ee][Dd]|[Hh][Ii][Gg][Hh])\))?:\s*([^\n\r]*)|\/\*\s*(TODO)(?:\(([Ll][Oo][Ww]|[Mm][Ee][Dd]|[Hh][Ii][Gg][Hh])\))?:\s*([^\n\r]*)(?:\s*\(DESC\):\s*([\s\S]*?))?\s*\*\/)',
      multiLine: true,
      dotAll: true,
    );

    for (final match in regex.allMatches(fileContent)) {
      final isSingleLine = match.group(1) != null;
      final isMultiLine = match.group(4) != null;
      String? rawPriority = match.group(2) ?? match.group(5);
      String? rawTask = match.group(3) ?? match.group(6);
      String? rawDesc = match.group(7);

      String finalPriority = (rawPriority ?? '-').toUpperCase();
      String finalTask = (rawTask ?? 'No Task').trim();
      String finalDesc = (rawDesc ?? '').trim();
      int lineNumber = 0;
      if (isSingleLine) {
        lineNumber = fileContent.substring(0, match.start).split('\n').length;
      } else if (isMultiLine) {
        lineNumber = fileContent.substring(0, match.start).split('\n').length + 1;
      }

      todos.add(
        Todo(
          task: finalTask, 
          priority: finalPriority, 
          description: finalDesc,
          filePath: filePath,
          lineNumber: lineNumber,
        )
      );
    }

    return todos;
  }

  String strBuffer({String type = 'text'}) {
    String buffer = '';
    if (type == 'text') {
      ++todoNumber;
      if (todoNumber == 1) {
        buffer += '--- TODO ---\n';
      }
      buffer += '''
- [ ] #$todoNumber
  Priority : ${priority.isEmpty ? "-" : priority}
  Task     : $task
  Desc     : ${description.isEmpty ? "-" : description}
  File     : $filePath:$lineNumber

''';
    } else if (type == 'markdown') {
      ++todoNumber;
      if (todoNumber == 1) {
        buffer += '# TODO <br>\n';
      }
      buffer += '''
- [ ] #$todoNumber<br>
  **Priority** : ${priority.isEmpty ? "-" : priority}<br>
  **Task**     : $task<br>
  **Desc**     : ${description.isEmpty ? "-" : description}<br>
  **File**     : $filePath:$lineNumber

''';
    }

    return buffer;
  }

  @override
  String toString() {
    final buffer = '''
- [ ]
  Priority : ${priority.isEmpty ? "-" : priority}
  Task     : $task
  Desc     : ${description.isEmpty ? "-" : description}
  File     : $filePath:$lineNumber
''';
    return buffer;
  }
}

List<Todo> sort(List<Todo> foundTodos) {
  List<Todo> highPriority = [];
  List<Todo> medPriority = [];
  List<Todo> lowPriority = [];
  List<Todo> nonePriority = [];

  for (int i = 0; i < foundTodos.length; i++) {
    if (foundTodos[i].priority == 'HIGH') {
      highPriority.add(foundTodos[i]);
    } else if (foundTodos[i].priority == 'MED') {
      medPriority.add(foundTodos[i]);
    } else if (foundTodos[i].priority == 'LOW') {
      lowPriority.add(foundTodos[i]);
    } else if (foundTodos[i].priority == '-') {
      nonePriority.add(foundTodos[i]);
    }
  }

  List<Todo> todos = [];
  todos.addAll(highPriority);
  todos.addAll(medPriority);
  todos.addAll(lowPriority);
  todos.addAll(nonePriority);

  return todos;
}

void printTodos(List<Todo> foundTodos) {
  String buffer = '';
  for (int i = 0; i < foundTodos.length; i++) {
    buffer += foundTodos[i].strBuffer(type: 'text');
  }
  print(buffer);
}

void writeFile(File file, String type, List<Todo> foundTodos) async {
  String buffer = '';
  for (int i = 0; i < foundTodos.length; i++) {
    buffer += foundTodos[i].strBuffer(type: type);
  }

  try {
    await file.writeAsString(buffer);
    print('Successfully created \'${file.uri}\' file');
  } catch (e) {
    print('Error writing file $e');
  }
}
