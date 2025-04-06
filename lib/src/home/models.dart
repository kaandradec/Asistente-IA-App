class Person {
  String name;
  int age;
  // informacion adicional
  String aditionalInfo;

  Person(this.name, this.age, this.aditionalInfo);

  @override
  String toString() {
    return 'Person{name: $name, age: $age}, aditionalInfo: $aditionalInfo}';
  }
}

var elian = Person('Elian', 17, 'Elian duerme mucho');
var kevin = Person('Kevin', 22, 'Kevin no baila bien');
