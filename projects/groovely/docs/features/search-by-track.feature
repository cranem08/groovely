Feature: Find the records carrying a track

  Scenario: A track appearing on several records in the collection
    Given the collector owns three records carrying a track titled Blue in Green and four records that do not
    When the collector searches for Blue in Green in the track scope
    Then the collector is shown only those three records

  Scenario: A result states which track matched
    Given the collector owns a record carrying a track titled Blue in Green at position A3
    When the collector searches for Blue in Green in the track scope
    Then the collector is shown that result stating it matched the track Blue in Green at position A3

  Scenario: A record carrying the track more than once
    Given the collector owns a record carrying a track titled Blue in Green on side A and on side C
    When the collector searches for Blue in Green in the track scope
    Then the collector is shown one result stating both positions

  Scenario: A track the collector does not own
    Given the collector owns no record carrying a track titled Giant Steps
    When the collector searches for Giant Steps in the track scope
    Then the collector is shown a message stating no records matched
