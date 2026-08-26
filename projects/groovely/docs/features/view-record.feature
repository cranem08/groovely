Feature: View a record

  Scenario: A collector opens a record from their collection
    Given the collector owns a record by John Coltrane titled Blue Train of format LP kept in Crate B with notes reading slight warp side two
    When the collector opens that record
    Then the collector is shown that record's artist, title, format, storage location and notes

  Scenario: A collector navigates directly to their own record
    Given the collector owns a record by John Coltrane
    When the collector navigates directly to that record
    Then the collector is shown that record's artist and title

  Scenario: A collector opens a record belonging to another collector
    Given another collector owns a record
    When the collector navigates directly to that record
    Then the collector is shown a message stating the record was not found
