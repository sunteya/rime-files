#!/usr/bin/env osascript -l JavaScript

const Contacts = Application("Contacts")
for (var index in Contacts.people) {
  var person = Contacts.people[index]
  if (person.company()) {
    console.log(person.organization())
  } else {
    console.log(person.name())
  }
}
