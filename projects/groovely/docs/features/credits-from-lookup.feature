Feature: Credits arriving from a lookup

  Where the external music database holds credited personnel, they are offered to
  the collector without any typing.

  Scenario: A collector confirms a release that has credited personnel
    Given the collector is shown a candidate release with credited personnel
    When the collector confirms that candidate release
    Then the collector is shown the new record carrying those people and their roles

  Scenario: A collector confirms a release that has no credited personnel
    Given the collector is shown a candidate release with no credited personnel
    When the collector confirms that candidate release
    Then the collector is shown the new record with no credits
