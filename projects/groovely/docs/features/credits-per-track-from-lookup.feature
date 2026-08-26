Feature: Per-track credits arriving from a lookup

  A jazz album is frequently assembled from sessions with different lineups, and
  the external database records that per track.

  Scenario: A candidate release crediting a person on one track only
    Given the collector is shown a candidate release crediting a person on its second track only
    When the collector confirms that candidate release
    Then the collector is shown that person credited against that track only

  Scenario: A candidate release crediting a person across the whole record
    Given the collector is shown a candidate release crediting a person with no track named
    When the collector confirms that candidate release
    Then the collector is shown that person credited against the whole record
