import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as dart_path;

import 'package:args/args.dart';
import 'package:dartodo_parser/dartodo_parser.dart';

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('Error: Invalid arguments');
    print('       Try \'-h\' to see help command');
    return;
  }
  /*
  TODO(MED): Add `-ih` or `--include-hidden` flag
  (DESC): Default exclude hidden file or dir
  */
  final argParser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage details')
    ..addFlag('print-only', abbr: 'p', negatable: false, help: 'Print todo only')
    ..addMultiOption(
      'except',
      abbr: 'e',
      help: 'Except file or dir, not to be parsed',
      valueHelp: 'path'
    )
    ..addOption(
      'source',
      abbr: 's',
      help: 'The source file or dir to be parsed',
      valueHelp: 'path'
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'The output file after parsed',
      valueHelp: 'path'
    );

  try {
    final parser = argParser.parse(arguments);

    if (parser['help'] as bool) {
      showUsage(argParser);
      return;
    }

    final hasSource = parser.wasParsed('source');
    final hasOutput = parser.wasParsed('output');
    final hasExcept = parser.wasParsed('except');
    bool hasPrintOnly = parser['print-only'] as bool;

    if ((hasSource && !hasPrintOnly && !hasOutput) || 
      (hasOutput && !hasPrintOnly && !hasSource)) {
      printError();
      return;
    }

    if (hasPrintOnly && hasSource && !hasOutput) {
      String sourcePath = parser.option('source')!;
      String type = await isFileOrDir(sourcePath);

      if (type == 'file') {
        File fileInput = File(sourcePath);
        if (await fileInput.exists()) {
          String fileContent = await fileInput.readAsString();
          List<Todo> foundTodos = Todo.parseAll(fileContent, fileInput.path);
          printTodos(foundTodos);
        } else {
          print('Error: File "$sourcePath" not found');
        }
        return;
      } else if (type == 'directory') {
        List<Todo> todos = [];
        if (hasExcept) {
          List<String> exceptPath = parser.multiOption('except');
          todos = await parseDirectory(sourcePath, exceptPath: exceptPath);
        } else {
          todos = await parseDirectory(sourcePath);
        }
        printTodos(todos);
        return;
      }
    } else if (hasSource && hasOutput && !hasPrintOnly) {
      String sourcePath = parser.option('source')!;
      String outputPath = parser.option('output')!;
      if (hasExcept) {
        List<String> exceptPath = parser.multiOption('except');
        await parseWriteTodo(sourcePath, outputPath, exceptPath: exceptPath);
      } else {
        await parseWriteTodo(sourcePath, outputPath); 
      }
    } else {
      printError();
      return;
    }

  } on FormatException catch (e) {
    print('Error: ${e.message}');
  }
}

Future<String> isFileOrDir(String path) async {
  FileSystemEntityType type = await FileSystemEntity.type(path);
  return type.toString();
}

Future<void> parseWriteTodo(
  String sourcePath, 
  String outputPath, 
  {List<String>? exceptPath}
) async {
  String type = await isFileOrDir(sourcePath);
  List<Todo> todos = [];
  if (type == 'file') {
    File sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      print('Error: File source "$sourcePath" not found.');
      return;
    }

    String fileContent = await sourceFile.readAsString();
    List<Todo> foundTodos = Todo.parseAll(fileContent, sourceFile.path);
    todos = sort(foundTodos);
  } else if (type == 'directory') {
    todos = await parseDirectory(sourcePath, exceptPath: exceptPath);
  } else if (type == 'notFound') {
    print("Error: Source file or directory not found");
    return;
  }

  File outputFile = File(outputPath);
  String format = outputPath.endsWith('.md') ? 'markdown' : 'text';
  writeFile(outputFile, format, todos);
}

Future<List<Todo>> parseDirectory(
  String sourcePath, 
  {List<String>? exceptPath}
) async {
  final dir = Directory(sourcePath);
  final List<FileSystemEntity> entities = await dir
    .list(recursive: true, followLinks: false)
    .toList();

  List<File> files = entities.whereType<File>().where((file) {
    final parts = dart_path.split(file.path);
    final isHidden = parts.any(
      (part) => part.startsWith('.') && part != '.' && part != '..',
    );
    return !isHidden;
  }).toList();

  if (exceptPath != null) {
    files = await parseExceptPath(files, exceptPath);
  }

  List<Todo> foundTodos = [];

  // TODO(MED): Change `for...in` to `Future.wait`
  for (final file in files) {
    if (await isTextFile(file)) {
      String fileContent = await file.readAsString();
      foundTodos.addAll(Todo.parseAll(fileContent, file.path));
    }
  }

  final todos = sort(foundTodos);
  return todos;
}

Future<List<File>> parseExceptPath(List<File> files, List<String> exceptPath) async {
  try {
    for (int i = 0; i < exceptPath.length; i++) {
      final fileOrDir = await isFileOrDir(exceptPath[i]);
      if (fileOrDir == 'notFound') throw '$exceptPath not found';

      List<File> tempFiles = files.toList();
      // TODO(MED): Change to check if path is exists
      if (fileOrDir == 'directory' || fileOrDir == 'file') {
        for (var file in tempFiles) {
          if (file.path.contains(exceptPath[i])) {
            files.remove(file);
          }
        }
      }
    }
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
  return files;
}

Future<bool> isTextFile(File file) async {
  try {
    final Stream<List<int>> stream = file.openRead(0, 1024);
    final List<int> bytes = await stream.first;

    if (bytes.contains(0)) {
      return false;
    }

    utf8.decode(bytes, allowMalformed: false);
    return true;
  } catch (_) {
    return false;
  }
}

void printError() {
  print('''
Error:
  Should provide '-s' and '-o'\n'
  Example:'
    dartodo_parser -s path/file_input.dart -o output.md'
  Or'
    dartodo_parser -s path/file_input.dart -p'
''');
}

void showUsage(ArgParser argParser) {
  print('''
dartodo_parser - Parse TODO comments from code

Usage: dartodo_parser [options]

${argParser.usage}

Examples:
  dartodo_parser -s . -o TODO.md
  dartodo_parser -s lib -o TODO.md -e test -e build
  dartodo_parser -s lib -o TODO.md --except=test,build
  dartodo_parser -s . -p
  dartodo_parser -s main.dart -o TODO.txt
''');
}
