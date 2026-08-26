Feature: Promote a wantlist entry

  Buying a record moves it from the wantlist into the collection.

  Scenario: A collector promotes a wantlist entry
    Given the collector has a wantlist entry
    When the collector promotes that entry to their collection
    Then the collector is shown a new record in their collection

  Scenario: The wantlist after a promotion
    Given the collector has a wantlist entry
    When the collector promotes that entry to their collection
    Then the collector's wantlist no longer shows that entry
