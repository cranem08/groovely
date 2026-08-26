Feature: Add a record by manual entry

  Manual entry is a first-class path, not a fallback. Many older pressings carry
  no barcode at all.

  Scenario: A collector creates a record by typing its details
    Given the collector is on the manual entry screen
    When the collector submits an artist and a title
    Then the collector is shown the new record in their collection

  Scenario: A collector submits manual entry without an artist
    Given the collector is on the manual entry screen
    When the collector submits a title with no artist
    Then the collector is shown a message stating an artist is required

  Scenario: A collector submits the earliest permitted release year
    Given the collector is on the manual entry screen
    When the collector submits a release year of 1889
    Then the collector is shown the new record with a release year of 1889

  Scenario: A collector submits a release year outside the permitted range
    Given the collector is on the manual entry screen
    When the collector submits a release year of 1650
    Then the collector is shown a message stating the release year must be between 1889 and next year
