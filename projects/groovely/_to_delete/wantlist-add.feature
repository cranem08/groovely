Feature: Add to the wantlist

  Scenario: A collector adds a release they do not own to their wantlist
    Given the collector is shown a candidate release
    When the collector adds that candidate release to their wantlist
    Then the collector is shown that entry in their wantlist

  Scenario: A collector sets how badly they want something
    Given the collector has a wantlist entry of medium priority
    When the collector raises that entry's priority to high
    Then the collector is shown that entry at high priority

  Scenario: A collector adds a wantlist entry without adding a record
    Given the collector is shown a candidate release
    When the collector adds that candidate release to their wantlist
    Then the collector's collection gains no record
