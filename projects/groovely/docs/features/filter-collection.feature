Feature: Filter the collection

  Format is the only filter facet. It matches how a collection physically exists:
  singles live in a different box from albums.

  Scenario: A collector filters by one format
    Given the collector owns two records of format 7", one of format 12" single and one of format LP
    When the collector filters by the format 7"
    Then the collector is shown exactly those two records of format 7"

  Scenario: A collector filters by two formats
    Given the collector owns two records of format 7", one of format 12" single and one of format LP
    When the collector filters by the formats 7" and 12" single
    Then the collector is shown exactly those three records

  Scenario: A collector clears an applied filter
    Given the collector has filtered a collection of four records down to two
    When the collector clears the filter
    Then the collector is shown all four of their records
