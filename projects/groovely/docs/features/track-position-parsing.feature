Feature: Track positions that do not parse

  The external database gives positions as free text. No track is silently dropped,
  and no side or position is ever invented.

  Scenario: A track listing that parses cleanly
    Given the collector is shown a candidate release whose tracks are positioned A1 and B1
    When the collector confirms that candidate release
    Then the collector is shown the new record listing a track at position A1 and a track at position B1

  Scenario: A track whose position cannot be parsed
    Given the collector is shown a candidate release carrying a track with no side letter
    When the collector confirms that candidate release
    Then the collector is asked to supply a side and a position for that track

  Scenario: A collector completes a track that could not be parsed
    Given the collector has been asked to supply a side and a position for a track
    When the collector supplies side C and position two
    Then the collector is shown the new record listing that track at position C2

  Scenario: A duration that parses
    Given the collector is shown a candidate release carrying a track whose duration reads 5:37
    When the collector confirms that candidate release
    Then the collector is shown that track with a duration of five minutes and thirty seven seconds

  Scenario: An unparseable duration
    Given the collector is shown a candidate release carrying a track with an unreadable duration
    When the collector confirms that candidate release
    Then the collector is shown that track with no duration
