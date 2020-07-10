#!/usr/bin/env osascript -l JavaScript

const Contacts = Application("Contacts")
for (var index in Contacts.people) {
  var person = Contacts.people[index]
  if (person.company()) {
    console.log(person.organization())
  } else {
    const names = [
      person.lastName(),
      person.middleName(),
      person.firstName()
    ]
    const name = names.filter(item => item).join("")
    const phonetics = [
      person.phoneticLastName(),
      person.phoneticMiddleName(),
      person.phoneticFirstName()
    ]
    const phonetic = phonetics.filter(item => item).join("")
    console.log(`${name} || ${phonetic}`)
  }
}
