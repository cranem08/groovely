Feature: The order records are shown in

  Every ordering is total, so the same query always returns the same order and no
  record is repeated or skipped across a page boundary.

  Scenario: A collector opens their collection for the first time
    Given the collector owns records added on several dates
    When the collector opens their collection
    Then the collector is shown their most recently added record first

  Scenario: A collector loads a second page
    Given the collector owns fifty records and has chosen list view
    When the collector loads more records
    Then the collector is shown twenty distinct records with none repeated

  Scenario: Records sharing the sorted value across a page boundary
    Given the collector owns thirty records by the same artist, sorted by artist, in list view
    When the collector loads more records until none remain
    Then the collector is shown all thirty of their records, each exactly once

  Scenario: The same query on a later visit
    Given the collector owns three records by the same artist and has previously been shown them sorted by artist
    When the collector sorts their collection by artist on a later visit
    Then the collector is shown those three records in the same order as before
