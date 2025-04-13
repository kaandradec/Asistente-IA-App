class Person {
  String name;
  int age;
  // informacion adicional
  String aditionalInfo;
  String estudios;

  Person(this.name, this.age, this.estudios, this.aditionalInfo);

  @override
  String toString() {
    return 'Person{name: $name, age: $age, estudios: $estudios}, aditionalInfo: $aditionalInfo}';
  }
}

var elian = Person('Elian', 17, 'Estudiante Bachiller Técnico',
    'Su anime favorito es Shingeki no Kiojin');
var jordan = Person(
    'Jordan', 17, 'Estudiante Bachiller Técnico', 'No le gusta el anime');
var solange =
    Person('Solange', 17, 'Estudiante Bachiller Técnico', 'Le gusta el kpop');
var carolina = Person('Carolina', 17, 'Estudiante Bachiller Técnico',
    'Es la niña de los plumones');

var edison =
    Person('Edison', 17, 'Ingeniero', 'Enseña el lenguaje C++ en su clase');
