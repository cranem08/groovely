Feature: Sorting by title and by release year

  Scenario: A collector sorts by title
    Given the collector owns a record titled Ascension added after a record titled Blue Train
    When the collector sorts their collection by title
    Then the collector is shown the record titled Ascension before the record titled Blue Train

  Scenario: A collector sorts by release year
    Given the collector owns records released in several years that are not already in year order
    When the collector sorts their collection by release year
    Then the collector is shown their most recently released record first
