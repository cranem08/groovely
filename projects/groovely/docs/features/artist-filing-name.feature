Feature: Filing an artist where a record shelf would put them

  Groovely never guesses whether a name belongs to a person or a group. The
  collector says so, once, and every record by that artist follows.

  Scenario: An artist with no filing name
    Given the collector owns a record by Miles Davis and a record by Duke Ellington
    When the collector sorts their collection by artist
    Then the collector is shown the record by Duke Ellington before the record by Miles Davis

  Scenario: A collector files an artist under a surname
    Given the collector owns a record by Miles Davis and a record by Duke Ellington, sorted by artist
    When the collector files Miles Davis as Davis, Miles
    Then the collector is shown the record by Miles Davis before the record by Duke Ellington

  Scenario: A filing name applies to a record added afterwards
    Given the collector has filed Miles Davis as Davis, Miles and owns a record by Duke Ellington, sorted by artist
    When the collector adds a new record by Miles Davis
    Then the collector is shown that new record before the record by Duke Ellington
