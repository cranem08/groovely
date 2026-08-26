Feature: Export the collection

  The collector can take their data with them. An export that omits what the
  collector actually owns discharges the principle in name only.

  Scenario: A collector exports a collection carrying tracks and credits
    Given the collector owns one record with two tracks and one credit while another collector owns a record
    When the collector requests an export of their collection
    Then the collector is given an archive containing that one record with its two tracks and its one credit and no other record

  Scenario: A collector exports a collection carrying a sleeve photograph
    Given the collector owns a record with one sleeve photograph
    When the collector requests an export of their collection
    Then the collector is given an archive containing an image file named for that record whose contents are that photograph

  Scenario: A collector with an empty collection exports it
    Given the collector owns no records
    When the collector requests an export of their collection
    Then the collector is given an archive containing column headings and no data rows

  Scenario: An export omits credentials
    Given the collector owns one record by John Coltrane, has enrolled with a known authenticator secret, and holds ten known recovery codes
    When the collector requests an export of their collection
    Then the collector is given an archive in which that record appears and neither that secret nor any of those recovery codes appears

  Scenario: A collector exports a collection containing a removed record
    Given the collector has removed a record from a collection of three
    When the collector requests an export of their collection
    Then the collector is given an archive containing the two records they still own
