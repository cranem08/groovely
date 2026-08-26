Feature: Sorting where the value is missing or awkward

  An ordering that is only defined for tidy data is not an ordering.

  Scenario: A collector sorts by acquisition date with some dates missing
    Given the collector owns two records with acquisition dates and one without
    When the collector sorts their collection by acquisition date
    Then the collector is shown the record without an acquisition date after both records that have one

  Scenario: A collector reverses a sort where a value is missing
    Given the collector owns a record acquired in 1998, a record acquired in 2015 and a record with no acquisition date
    When the collector reverses the sort by acquisition date
    Then the collector is shown the record acquired in 1998 first and the record with no acquisition date last

  Scenario: A collector sorts by artist where a name begins with an article
    Given the collector owns a record by The Beatles and a record by Duke Ellington
    When the collector sorts their collection by artist
    Then the collector is shown the record by The Beatles before the record by Duke Ellington

  Scenario: A collector sorts by artist where a name carries an accent
    Given the collector owns a record by Müller spelled with an umlaut and a record by Muzak
    When the collector sorts their collection by artist
    Then the collector is shown the record by Müller before the record by Muzak

  Scenario: A collector reverses a sort
    Given the collector is shown their collection sorted by artist ascending
    When the collector reverses the sort direction
    Then the collector is shown their records in the opposite order
