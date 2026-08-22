/*
  Write todo comment to your code files and run this program.

  Example:
  // TODO(LOW): todo with low priority
  // TODO(MED): todo with medium priority
  // TODO(HIG): todo with high priority
  // TODO: todo with no priority
  /*
  TODO(LOW): todo low priority 
  (DESC): 
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum interdum 
    elementum diam, eu cursus erat tristique eu. Mauris gravida sodales tristique. 
    Sed eget commodo sem. Etiam rutrum dolor at nunc ultricies volutpat. Donec a 
    risus sed diam faucibus bibendum. Nulla sit amet lorem eget ex cursus vulputate 
    vitae sit amet urna. Cras aliquam purus a neque posuere, nec varius ligula 
    faucibus. 
  */

  Run:
  $ dartodo_parser -f 'your/code/file'

*/

import 'dart:io';

import 'package:dartodo_parser/dartodo_parser.dart';

void main(List<String> arguments) async {
  String fileName = 'bin/dartodo_parser.dart';
  File fileInput = File(fileName);
  File fileOutput = File('TODO.md');

  if (await fileInput.exists()) {
    String fileContent = await fileInput.readAsString();
    List<Todo> foundTodos = Todo.parseAll(fileContent);

    // printTodos(foundTodos);
    writeMarkdown(fileOutput, foundTodos);
  } else {
    print('Error: File "$fileName" not found');
  }
}
