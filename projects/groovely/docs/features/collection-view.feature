Feature: Choose how the collection is laid out

  Some collectors browse by cover, others scan detail. The choice is remembered.

  Scenario: A new collector opens their collection for the first time
    Given the collector has never chosen a collection view
    When the collector opens their collection
    Then the collector is shown their collection as a list of rows

  Scenario: A collector switches to grid view
    Given the collector is shown their collection as a list of rows
    When the collector switches to grid view
    Then the collector is shown their collection as a grid of sleeves

  Scenario: A collector returns after choosing a view
    Given the collector has chosen grid view
    When the collector opens their collection on a later visit
    Then the collector is shown their collection as a grid of sleeves
