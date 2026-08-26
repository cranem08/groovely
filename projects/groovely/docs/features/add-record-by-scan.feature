Feature: Add a record by scanning a barcode

  The collector scans the barcode on a sleeve and Groovely offers candidate
  releases from a lookup.

  Scenario: A scan matches exactly one candidate release
    Given the collector has granted camera access
    When the collector scans a barcode matching one release
    Then the collector is shown that candidate release for confirmation

  Scenario: A collector confirms a candidate release
    Given the collector is shown a candidate release carrying a label, a catalogue number and a release year
    When the collector confirms that candidate release
    Then the collector is shown the new record carrying that release's artist, title, label, catalogue number and release year

  Scenario: A saved record after the entry it came from is changed externally
    Given the collector owns a record confirmed from a candidate release that has since been retitled in the external music database
    When the collector opens that record
    Then the collector is shown the title the record was confirmed with
