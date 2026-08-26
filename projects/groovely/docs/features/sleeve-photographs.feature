Feature: Photograph your own copy

  One photograph per record. The collector's own photograph is authoritative over
  the catalogue image.

  Scenario: A collector photographs their sleeve
    Given the collector owns a record showing a catalogue image
    When the collector adds a sleeve photograph to that record
    Then the collector is shown that record displaying their photograph in place of that catalogue image

  Scenario: A record with no photograph and no catalogue image
    Given the collector owns a record with no photograph and no catalogue image
    When the collector opens that record
    Then the collector is shown that record displaying no image

  Scenario: A photograph is served to the collector who owns it
    Given the collector owns a record carrying a sleeve photograph
    When the collector requests the address that photograph is served from
    Then the collector is given that image

  Scenario: A second photograph replaces the first
    Given the collector owns a record carrying a sleeve photograph
    When the collector adds a different sleeve photograph to that record
    Then the collector is shown that record carrying exactly one photograph, the newer one

  Scenario: A photograph larger than the stored bound is reduced
    Given the collector owns a record with no photograph
    When the collector adds a sleeve photograph of four thousand pixels square
    Then the collector is shown that photograph at one thousand pixels square

  Scenario: A photograph one pixel over the stored bound is reduced
    Given the collector owns a record with no photograph
    When the collector adds a sleeve photograph of one thousand and one pixels square
    Then the collector is shown that photograph at one thousand pixels square

  Scenario: A photograph exactly at the stored bound is left alone
    Given the collector owns a record with no photograph
    When the collector adds a sleeve photograph of one thousand pixels square
    Then the collector is shown that photograph at one thousand pixels square

  Scenario: A photograph smaller than the stored bound is not enlarged
    Given the collector owns a record with no photograph
    When the collector adds a sleeve photograph of eight hundred pixels square
    Then the collector is shown that photograph at eight hundred pixels square

  Scenario: Reducing a photograph preserves its shape
    Given the collector owns a record with no photograph
    When the collector adds a sleeve photograph three thousand pixels wide and two thousand four hundred pixels tall
    Then the collector is shown that photograph one thousand pixels wide and eight hundred pixels tall

  Scenario: An accepted upload in another format is stored as a JPEG
    Given the collector owns a record with no photograph
    When the collector adds a sleeve photograph in PNG format
    Then the collector is served that photograph as a JPEG image

  Scenario: A collector adds a photograph carrying location metadata
    Given the collector owns a record with no photograph
    When the collector adds a sleeve photograph carrying location metadata
    Then the collector is shown that photograph carrying no location metadata

  Scenario: A collector adds a file that is not an image
    Given the collector owns a record with no photograph
    When the collector adds a file named sleeve.jpg whose contents are not an image
    Then the collector is shown a message stating only image files are accepted

  Scenario: A collector adds a photograph at the size limit
    Given the collector owns a record with no photograph
    When the collector adds a sleeve photograph of ten mebibytes
    Then the collector is shown that record displaying that photograph

  Scenario: A collector adds a photograph larger than the limit
    Given the collector owns a record with no photograph
    When the collector adds a sleeve photograph of twelve mebibytes
    Then the collector is shown a message stating a photograph may be no larger than ten mebibytes

  Scenario: A collector removes a photograph
    Given the collector owns a record carrying a sleeve photograph and a catalogue image
    When the collector removes the photograph
    Then the collector is shown that record displaying that catalogue image

  Scenario: Another collector's photograph is requested
    Given another collector owns a record carrying a sleeve photograph
    When the collector requests the address that photograph is served from
    Then that address returns the same not-found response as an address that never existed
