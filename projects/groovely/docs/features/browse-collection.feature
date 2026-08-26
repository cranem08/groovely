Feature: Browse the collection

  Scenario: A collector with no records opens their collection
    Given the collector owns no records
    When the collector opens their collection
    Then the collector is shown a message inviting them to add their first record

  Scenario: A collector opens a collection larger than one page in list view
    Given the collector owns two hundred records and has chosen list view
    When the collector opens their collection
    Then the collector is shown ten records rather than two hundred

  Scenario: A collector opens a collection larger than one page in grid view
    Given the collector owns two hundred records and has chosen grid view
    When the collector opens their collection
    Then the collector is shown twelve records rather than two hundred
