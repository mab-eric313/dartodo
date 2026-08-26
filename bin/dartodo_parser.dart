/*
  Write todo comment to your code files and run this program.

  Example:
  // TODO(LOW): todo with low priority
  // TODO(MED): todo with medium priority
  // TODO(HIGH): todo with high priority
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
import 'package:args/args.dart';

import 'package:dartodo_parser/dartodo_parser.dart';

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('Error: Invalid arguments');
    print('       Try \'-h\' to see help command');
    return;
  }
  final argParser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage details')
    ..addFlag('print-only', abbr: 'p', negatable: false, help: 'Print todo only')
    ..addOption(
      'source',
      abbr: 's',
      // TODO(HIGH): Add support can work with dir
      help: 'The source file to be parsed',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'The output file after parsed',
    );

  try {
    final parser = argParser.parse(arguments);

    if (parser['help'] as bool) {
      print('Usage: dartodo_parser [options]');
      print(argParser.usage);
      return;
    }

    if (parser['print-only'] as bool) {
      String fileName = 'bin/dartodo_parser.dart';
      File fileInput = File(fileName);
      if (await fileInput.exists()) {
        String fileContent = await fileInput.readAsString();
        List<Todo> foundTodos = Todo.parseAll(fileContent);
        printTodos(foundTodos);
      } else {
        print('Error: File "$fileName" not found');
      }
      return;
    }

    final hasSource = parser.wasParsed('source');
    final hasOutput = parser.wasParsed('output');

    if (hasSource && hasOutput) {
      String sourcePath = parser.option('source')!;
      String outputPath = parser.option('output')!;
      await parseWriteTodo(sourcePath, outputPath);
    } else {
      print('Error: Should provide \'-s\' and \'-o\'');
      print('Example:');
      print('  dartodo_parser -s path/file_input.dart -o output.md');
    }

  } on FormatException catch (e) {
    print('Error: ${e.message}');
  }
}

Future<void> parseWriteTodo(String sourcePath, String outputPath) async {
  File sourceFile = File(sourcePath);

  if (!await sourceFile.exists()) {
    print('Error: File source "$sourcePath" tidak ditemukan.');
    return;
  }

  String fileContent = await sourceFile.readAsString();
  List<Todo> foundTodos = Todo.parseAll(fileContent);

  File outputFile = File(outputPath);
  String format = outputPath.endsWith('.md') ? 'markdown' : 'text';

  writeFile(outputFile, format, foundTodos);
}
