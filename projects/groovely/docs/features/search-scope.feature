Feature: Saying what you are searching for

  There is no blended search. The collector states the attribute; every term must
  match within a single value of it. A result is always a record.

  Scenario: A collector searches by album
    Given the collector owns a record titled Blue Train, a record with a track titled Blue Train, and a record with neither
    When the collector searches the album scope for Blue Train
    Then the collector is shown only the record titled Blue Train

  Scenario: A collector searches by track
    Given the collector owns a record titled Blue Train, a record with a track titled Blue Train, and a record with neither
    When the collector searches the track scope for Blue Train
    Then the collector is shown only the record with the track titled Blue Train

  Scenario: A collector searches by artist
    Given the collector owns a record by John Coltrane titled Giant Steps and a record by Bill Evans titled Coltrane Sessions
    When the collector searches the artist scope for Coltrane
    Then the collector is shown only the record by John Coltrane

  Scenario: Terms must match within one value
    Given the collector owns a record titled Kind of Blue by Miles Davis
    When the collector searches the album scope for blue miles
    Then the collector is shown a message stating no records matched

  Scenario: A collector searches by label
    Given the collector owns a record on Blue Note, a record on Impulse, and a record titled Blue Note Sessions
    When the collector searches the label scope for Blue Note
    Then the collector is shown only the record on Blue Note

  Scenario: A collector searches by catalogue number
    Given the collector owns a record with catalogue number BLP 1577 and a record with a different catalogue number
    When the collector searches the catalogue number scope for BLP 1577
    Then the collector is shown only the record with catalogue number BLP 1577
