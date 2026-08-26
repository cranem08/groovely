Feature: A barcode matching no release

  Scenario: A scan matches no candidate release
    Given the collector has granted camera access
    When the collector scans a barcode matching no release
    Then the collector is shown a message offering manual entry because no release was found
