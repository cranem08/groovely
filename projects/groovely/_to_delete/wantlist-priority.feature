Feature: Wantlist priority

  Scenario: A new wantlist entry takes a medium priority
    Given the collector is shown a candidate release
    When the collector adds that candidate release to their wantlist
    Then the collector is shown that entry at medium priority

  Scenario: A collector sorts their wantlist by priority
    Given the collector has wantlist entries of high, medium and low priority
    When the collector sorts their wantlist by priority
    Then the collector is shown the high priority entry first
