Feature: One collector never reaches another's collection

  Ownership is enforced at every query, not only on the record page. Each route
  below runs its own query and so needs its own assertion.

  Scenario: Another collector's record is requested directly
    Given another collector owns a record
    When the collector navigates directly to that record
    Then the collector is shown a message stating the record was not found

  Scenario: A search never reaches another collector's records
    Given another collector owns Giant Steps by John Coltrane while the collector owns Blue Train by John Coltrane
    When the collector searches the artist scope for Coltrane
    Then the collector is shown only the record titled Blue Train

  Scenario: The list of people never includes another collector's people
    Given another collector has credited Paul Chambers while the collector has credited only Bill Evans
    When the collector opens their list of people
    Then the collector is shown exactly one person, named Bill Evans

  Scenario: An export never contains another collector's records
    Given another collector owns a record by Thelonious Monk while the collector owns records by John Coltrane and Bill Evans
    When the collector requests an export of their collection
    Then the collector is given an archive containing exactly the records by John Coltrane and Bill Evans
