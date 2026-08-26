Feature: Remove a wantlist entry

  Scenario: A collector removes a wantlist entry
    Given the collector has a wantlist entry
    When the collector removes that entry
    Then the collector's wantlist no longer shows that entry
