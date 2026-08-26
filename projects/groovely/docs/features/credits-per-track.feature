Feature: Crediting a person on one track

  Jazz albums are frequently assembled from sessions recorded months apart with
  different lineups, so a credit may apply to one track rather than the record.

  Scenario: A collector credits a person on a single track
    Given the collector owns a record with several tracks
    When the collector credits a person on one of those tracks
    Then the collector is shown that person credited against that track only

  Scenario: A collector credits a person on the whole record
    Given the collector owns a record with several tracks
    When the collector credits a person against the whole record
    Then the collector is shown that person credited against the whole record

  Scenario: A record with no tracks offers no track choice
    Given the collector owns a record with no tracks
    When the collector adds a credit to that record
    Then the collector is not offered a track to attribute the credit to
