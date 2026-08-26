Feature: Searching within a filtered collection

  A filter and a search narrow together. Neither discards the other.

  Scenario: A collector searches while a filter is applied
    Given the collector owns a 7" by John Coltrane, an LP by John Coltrane and a 7" by Bill Evans, filtered to format 7"
    When the collector searches the artist scope for Coltrane
    Then the collector is shown only the 7" by John Coltrane

  Scenario: A collector clears the search but keeps the filter
    Given the collector owns a 7" by John Coltrane, a 7" by Bill Evans and an LP by John Coltrane, filtered to format 7" and searched for Coltrane
    When the collector clears the search
    Then the collector is shown exactly the two records of format 7"
