Feature: Barcode validation

  Only the three symbologies that appear on records are accepted.

  Scenario: A collector types a valid thirteen digit barcode
    Given the collector is on the manual entry screen
    When the collector submits a thirteen digit barcode with a valid check digit
    Then the collector is shown the new record carrying that barcode

  Scenario: A collector types a valid eight digit barcode
    Given the collector is on the manual entry screen
    When the collector submits an eight digit barcode with a valid check digit
    Then the collector is shown the new record carrying that barcode

  Scenario: A collector types a valid twelve digit barcode
    Given the collector is on the manual entry screen
    When the collector submits a twelve digit barcode with a valid check digit
    Then the collector is shown the new record carrying that barcode

  Scenario: A collector types a barcode of a length matching no symbology
    Given the collector is on the manual entry screen
    When the collector submits an eleven digit barcode
    Then the collector is shown a message stating a barcode must be eight, twelve or thirteen digits

  Scenario: A collector types a barcode whose check digit is wrong
    Given the collector is on the manual entry screen
    When the collector submits a thirteen digit barcode with an incorrect check digit
    Then the collector is shown a message stating the barcode is not valid
