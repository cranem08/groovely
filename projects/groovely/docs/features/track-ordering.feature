Feature: Track order

  Order follows side then position, so a tenth track never precedes a second one.

  Scenario: A collector views a record with more than nine tracks on a side
    Given the collector owns a record whose track at position ten on side A was added before its track at position two
    When the collector opens that record
    Then the collector is shown the track at position two before the track at position ten

  Scenario: A collector views a record with tracks on more than one side
    Given the collector owns a record whose side B tracks were added before its side A tracks
    When the collector opens that record
    Then the collector is shown every track on side A before any track on side B
