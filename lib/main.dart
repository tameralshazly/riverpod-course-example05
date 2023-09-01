// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(
    const ProviderScope(child: App()),
  );
}

class App extends StatelessWidget {
  // const App({super.key});
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }
}

@immutable
class Person {
  final String name;
  final int age;
  final String uuid;
  Person({required this.name, required this.age, String? uuid})
      : uuid = uuid ?? const Uuid().v4();

  Person updated([String? name, int? age]) => Person(
        name: name ?? this.name,
        age: age ?? this.age,
        uuid: uuid,
      );

  String get displayName => '$name ($age years old)';

  @override
  bool operator ==(covariant Person other) => uuid == other.uuid;

  @override
  int get hashCode => uuid.hashCode;

  @override
  String toString() => 'Person(name: $name, age: $age, uuid: $uuid)';
}

class DataModel extends ChangeNotifier {
  final List<Person> _people = [];

  int get count => _people.length;

  UnmodifiableListView<Person> get people => UnmodifiableListView(_people);

  void addPerson(Person person) {
    _people.add(person);
    notifyListeners();
  }

  void removePerson(Person person) {
    _people.remove(person);
    notifyListeners();
  }

  void updatePerson(Person person) {
    final index = _people.indexOf(person);
    final personBeforeUpdate = _people[index];
    if (personBeforeUpdate.name != person.name ||
        personBeforeUpdate.age != person.age) {
      _people[index] = personBeforeUpdate.updated(person.name, person.age);
      notifyListeners();
    }
  }
}

final peopleProvider = ChangeNotifierProvider((ref) => DataModel());

class HomePage extends ConsumerWidget {
  // const HomePage({super.key});
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page"),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final dataModel = ref.watch(peopleProvider);
          return ListView.builder(
            itemCount: dataModel.count,
            itemBuilder: (context, index) {
              final person = dataModel.people[index];
              return ListTile(
                title: GestureDetector(
                    onTap: () async {
                      final updatedPerson = await createOrUpdatePersonDialog(
                        context,
                        person,
                      );

                      if (updatedPerson != null) {
                        dataModel.updatePerson(updatedPerson);
                      }
                    },
                    child: Text(person.displayName)),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final person = await createOrUpdatePersonDialog(context);
          if (person != null) {
            final dataModel = ref.read(peopleProvider);
            dataModel.addPerson(person);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

final nameController = TextEditingController();
final ageController = TextEditingController();

Future<Person?> createOrUpdatePersonDialog(
  BuildContext context, [
  Person? exisitingPerson,
]) {
  String? name = exisitingPerson?.name;
  int? age = exisitingPerson?.age;

  nameController.text = name ?? '';
  ageController.text = age?.toString() ?? '';

  return showDialog<Person?>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Create a person'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Enter name here...',
              ),
              onChanged: (value) => name = value,
            ),
            TextField(
              controller: ageController,
              decoration: const InputDecoration(
                labelText: 'Enter age here...',
              ),
              onChanged: (value) => age = int.tryParse(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (name != null && age != null) {
                if (exisitingPerson != null) {
                  final newPerson = exisitingPerson.updated(name, age);
                  Navigator.of(context).pop(newPerson);
                } else {
                  // no existing person,create a new one
                  Navigator.of(context).pop(
                    Person(
                      name: name!,
                      age: age!,
                    ),
                  );
                }
              } else {
                // no name or age or both
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          )
        ],
      );
    },
  );
}
