Feature: Merge duplicate people

  Where two entries for one musician arise despite the suggestion list, the
  collector can combine them.

  Scenario: A collector merges two people
    Given the collector has a person credited on two records and a duplicate of that musician credited on one other record
    When the collector merges the duplicate into the first
    Then the collector is shown one person credited on three records

  Scenario: A collector is told what a merge will do before confirming
    Given the collector has a person credited on two records and a duplicate of that musician credited on one other record
    When the collector submits those two people for merging
    Then the collector is shown that one credit will move and which name will remain
