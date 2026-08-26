Feature: Sort the collection

  Scenario: A collector sorts by artist
    Given the collector owns a record by Bill Evans added after a record by John Coltrane
    When the collector sorts their collection by artist
    Then the collector is shown the record by Bill Evans before the record by John Coltrane

  Scenario: A collector sorts by the date a record was added
    Given the collector owns a record added in March and a record added in September
    When the collector sorts their collection by date added
    Then the collector is shown the record added in September before the record added in March

  Scenario: A collector sorts by acquisition date
    Given the collector owns a record acquired in 1998 and a record acquired in 2015
    When the collector sorts their collection by acquisition date
    Then the collector is shown the record acquired in 2015 before the record acquired in 1998
