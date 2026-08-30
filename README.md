> Note: For now this tool is just support for C-style syntax only. Other programming language will add in the future.


Write todo comment to your code files and run this program.

Example:
```dart
// TODO(LOW): todo with low priority
// TODO(MED): todo with medium priority
// TODO(HIGH): todo with high priority
// TODO: todo with no priority
```
```dart
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
```

Run:
```sh
dart run bin/dartodo.dart -s . -o TODO.md
```
