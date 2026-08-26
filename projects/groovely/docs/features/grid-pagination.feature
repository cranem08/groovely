Feature: Loading more records in grid view

  Grid and list carry different page sizes, so each needs its own assertion.

  Scenario: A collector loads a second page in grid view
    Given the collector owns fifty records and has chosen grid view
    When the collector loads more records
    Then the collector is shown twenty four distinct records with none repeated

  Scenario: A collector reaches the end of their collection
    Given the collector owns fifteen records and has chosen grid view
    When the collector loads more records
    Then the collector is no longer offered more records to load
