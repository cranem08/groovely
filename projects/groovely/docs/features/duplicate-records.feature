Feature: Owning more than one copy of a release

  Two copies of the same album are two records, each with its own storage location,
  notes, acquisition date and sleeve photographs.

  Scenario: A collector adds a release they already own
    Given the collector already owns a record of a release
    When the collector confirms a candidate release for that same release
    Then the collector's collection contains two records of that release
