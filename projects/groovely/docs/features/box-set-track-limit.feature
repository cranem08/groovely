Feature: Track listings on a very large box set

  Sides run A to Z. A box set of more than thirteen discs is catalogued in full,
  but its track listing stops at side Z.

  Scenario: A collector catalogues a box set of more than thirteen discs
    Given the collector is on the manual entry screen
    When the collector submits an artist and a title with a disc count of eighteen
    Then the collector is shown the new record with a disc count of eighteen

  Scenario: A collector opens the track editor for a record of thirteen discs
    Given the collector owns a record with a disc count of thirteen
    When the collector opens that record's track listing
    Then the collector is shown no message about side Z

  Scenario: A collector opens the track editor for such a box set
    Given the collector owns a record with a disc count of fourteen
    When the collector opens that record's track listing
    Then the collector is shown a message stating tracks can be recorded only as far as side Z
