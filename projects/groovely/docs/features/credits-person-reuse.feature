Feature: Reusing a person already in the collection

  Selecting an existing person rather than retyping their name is what prevents a
  collection accumulating several spellings of one musician. Whether it worked is
  observable in the list of people, not on the record.

  Scenario: A collector begins typing the name of a person already credited elsewhere
    Given the collector has credited Miles Davis on one record and Bill Evans on another
    When the collector types Mil into the person name on a third record
    Then the collector is offered Miles Davis and not Bill Evans

  Scenario: A collector selects an offered person
    Given the collector has credited a person on one record and is offered that person on a second
    When the collector selects that person
    Then the collector's list of people shows that person once against a count of two

  Scenario: A collector types a name nobody in the collection carries
    Given the collector has credited Miles Davis on one record
    When the collector credits Paul Chambers on a second record
    Then the collector's list of people shows Miles Davis once and Paul Chambers once
