Feature: A result says why it matched

  Where a result matched on something other than its own artist or title, the row
  states what matched. Without it a collector cannot tell a correct match from a
  search returning everything.

  Scenario: A result matched on a label
    Given the collector owns a record on Blue Note and a record on Impulse
    When the collector searches the label scope for Blue Note
    Then the collector is shown that result stating it matched the label Blue Note

  Scenario: A result matched on a catalogue number
    Given the collector owns a record with catalogue number BLP 1577 and a record with another
    When the collector searches the catalogue number scope for BLP 1577
    Then the collector is shown that result stating it matched the catalogue number BLP 1577

  Scenario: A result matched on the record's own artist
    Given the collector owns a record by John Coltrane and a record by Bill Evans
    When the collector searches the artist scope for Coltrane
    Then the collector is shown that result stating no reason beyond the artist already displayed
