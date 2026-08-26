Feature: Browse the collection by person

  The question no external database can answer, because none of them knows which
  copies the collector owns.

  Scenario: A collector opens the list of people in their collection
    Given the collector owns Miles Davis credited on three records and Paul Chambers credited on one
    When the collector opens the list of people
    Then the collector is shown Miles Davis against a count of three and Paul Chambers against a count of one

  Scenario: A person credited twice on one record counts once
    Given the collector owns one record crediting Miles Davis on trumpet and as arranger
    When the collector opens the list of people
    Then the collector is shown Miles Davis against a count of one

  Scenario: A collector opens a person
    Given the collector owns records crediting a person as both credited artist and contributor alongside records not crediting them
    When the collector opens that person
    Then the collector is shown only the records crediting that person with their role on each
