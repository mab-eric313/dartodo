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

  Todo({
    required this.task,
    required this.priority,
    required this.description,
  });

  static List<Todo> parseAll(String fileContent) {
    List<Todo> todos = [];

    RegExp regex = RegExp(
      r'(?:\/\/\s*TODO(?:\(([Ll][Oo][Ww]|[Mm][Ee][Dd]|[Hh][Ii][Gg][Hh])\))?:\s*([^\n\r]*)|\/\*\s*TODO(?:\(([Ll][Oo][Ww]|[Mm][Ee][Dd]|[Hh][Ii][Gg][Hh])\))?:\s*([^\n\r]*)(?:\s*\(DESC\):\s*([\s\S]*?))?\s*\*\/)',
      multiLine: true,
      dotAll: true,
    );

    for (final match in regex.allMatches(fileContent)) {
      String? rawPriority = match.group(1) ?? match.group(3);
      String? rawTask = match.group(2) ?? match.group(4);
      String? rawDesc = match.group(5);

      String finalPriority = (rawPriority ?? '').toUpperCase();
      String finalTask = (rawTask ?? 'No Task').trim();
      String finalDesc = (rawDesc ?? '').trim();

      todos.add(
        Todo(
          task: finalTask, 
          priority: finalPriority, 
          description: finalDesc,
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

''';
    }

    return buffer;
  }
}

void printTodos(List<Todo> foundTodos) {
  String buffer = '';
  for (int i = 0; i < foundTodos.length; i++) {
    buffer += foundTodos[i].strBuffer(type: 'text');
  }
  print(buffer);
}

void writeMarkdown(File file, List<Todo> foundTodos) async {
  String buffer = '';
  for (int i = 0; i < foundTodos.length; i++) {
    buffer += foundTodos[i].strBuffer(type: 'markdown');
  }

  try {
    await file.writeAsString(buffer);
  } catch (e) {
    print('Error writing file $e');
  }
}
