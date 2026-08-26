Feature: Matching a credited person arriving from a lookup

  Confirming a release creates credits in bulk with no selection step, so people
  are matched rather than chosen.

  Scenario: A person already in the collection under the same external identity
    Given the collector has a person credited on one record carrying an external artist identity
    When the collector confirms a candidate release crediting that same external artist identity
    Then the collector's list of people shows that person once against a count of two

  Scenario: A person already in the collection under the same name only
    Given the collector has Bill Evans credited on one record with no external artist identity
    When the collector confirms a candidate release crediting Bill Evans with no external artist identity
    Then the collector's list of people shows Bill Evans once against a count of two

  Scenario: Two musicians sharing a name
    Given the collector has a person named Bill Evans carrying one external artist identity
    When the collector confirms a candidate release crediting a different Bill Evans carrying another external artist identity
    Then the collector's list of people shows two people named Bill Evans

  Scenario: A person not previously in the collection
    Given the collector has no person named Paul Chambers
    When the collector confirms a candidate release crediting Paul Chambers
    Then the collector's list of people shows Paul Chambers once
