Feature: A barcode matching several releases

  Reissues frequently share a barcode with the original pressing, so a scan may
  legitimately match more than one release.

  Scenario: A scan matches several candidate releases
    Given the collector has granted camera access
    When the collector scans a barcode matching four releases
    Then the collector is shown all four candidate releases to choose between

  Scenario: A collector leaves several candidate releases without choosing
    Given the collector owns three records and is shown several candidate releases
    When the collector leaves the candidate list without confirming one
    Then the collector's collection contains exactly those three records
