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
  // TODO(HIGH): Add `-e` or `--except` flag
  /*
  TODO(MED): Add `-ih` or `--include-hidden` flag
  (DESC): Default exclude hidden file or dir
  */
  final argParser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage details')
    ..addFlag('print-only', abbr: 'p', negatable: false, help: 'Print todo only')
    ..addOption(
      'source',
      abbr: 's',
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

    final hasSource = parser.wasParsed('source');
    final hasOutput = parser.wasParsed('output');
    bool hasPrintOnly = parser['print-only'] as bool;

    if ((hasSource && !hasPrintOnly && !hasOutput) || 
      (hasOutput && !hasPrintOnly && !hasSource)) {
      print('Error:');
      print('  Should provide \'-s\' and \'-o\'\n');
      print('  Example:');
      print('    dartodo_parser -s path/file_input.dart -o output.md');
      print('  Or');
      print('    dartodo_parser -s path/file_input.dart -p');
      return;
    }

    if (hasPrintOnly && hasSource && !hasOutput) {
      String sourcePath = parser.option('source')!;
      String type = await isFileOrDir(sourcePath);

      if (type == 'file') {
        File fileInput = File(sourcePath);
        if (await fileInput.exists()) {
          String fileContent = await fileInput.readAsString();
          List<Todo> foundTodos = Todo.parseAll(fileContent);
          printTodos(foundTodos);
        } else {
          print('Error: File "$sourcePath" not found');
        }
        return;
      } else if (type == 'directory') {
        final todos = await parseDirectory(sourcePath);
        printTodos(todos);
        return;
      }
    } else if (hasSource && hasOutput && !hasPrintOnly) {
      String sourcePath = parser.option('source')!;
      String outputPath = parser.option('output')!;
      await parseWriteTodo(sourcePath, outputPath);
    } else {
      print('Error:');
      print('  Should provide \'-s\' and \'-o\'\n');
      print('  Example:');
      print('    dartodo_parser -s path/file_input.dart -o output.md');
      print('  Or');
      print('    dartodo_parser -s path/file_input.dart -p');
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

Future<void> parseWriteTodo(String sourcePath, String outputPath) async {
  String type = await isFileOrDir(sourcePath);
  if (type == 'file') {
    File sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      print('Error: File source "$sourcePath" not found.');
      return;
    }

    String fileContent = await sourceFile.readAsString();
    List<Todo> foundTodos = Todo.parseAll(fileContent);
    final todos = sort(foundTodos);

    File outputFile = File(outputPath);
    String format = outputPath.endsWith('.md') ? 'markdown' : 'text';

    writeFile(outputFile, format, todos);
  } else if (type == 'directory') {
    final todos = await parseDirectory(sourcePath);
    File outputFile = File(outputPath);
    String format = outputPath.endsWith('.md') ? 'markdown' : 'text';

    writeFile(outputFile, format, todos);

  } else if (type == 'notFound') {
    print("Error: Source file or directory not found");
    return;
  }
}
Future<List<Todo>> parseDirectory(String sourcePath) async {
  final dir = Directory(sourcePath);
  final List<FileSystemEntity> entities = await dir
    .list(recursive: true, followLinks: false)
    .toList();

  final files = entities.whereType<File>().where((file) {
    final parts = dart_path.split(file.path);
    final isHidden = parts.any(
      (part) => part.startsWith('.') && part != '.' && part != '..',
    );
    return !isHidden;
  });

  List<Todo> foundTodos = [];

  // TODO(MED): Change `for...in` to `Future.wait`
  for (final file in files) {
    if (await isTextFile(file)) {
      String fileContent = await file.readAsString();
      foundTodos.addAll(Todo.parseAll(fileContent));
    }
  }

  final todos = sort(foundTodos);
  return todos;
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
