Feature: Changes are actually saved

  Every scenario elsewhere asserts what the collector sees in the response to their
  own action. An optimistic update whose write silently failed looks identical.
  These reopen the record to establish that the change reached the collection.

  Scenario: A storage location after the collector returns
    Given the collector has set a record's storage location
    When the collector opens that record from their collection on a later visit
    Then the collector is shown that record with that storage location

  Scenario: A credit after the collector returns
    Given the collector has credited a person on a record
    When the collector opens that record from their collection on a later visit
    Then the collector is shown that record listing that person

  Scenario: A track after the collector returns
    Given the collector has added a track to a record
    When the collector opens that record from their collection on a later visit
    Then the collector is shown that record listing that track

  Scenario: A removed record after the collector returns
    Given the collector has removed one record from a collection of three
    When the collector opens their collection on a later visit
    Then the collector is shown the two records they still own

  Scenario: A removed record is no longer found by a search that matched it
    Given the collector has removed a record that a search for Coltrane used to match
    When the collector searches the artist scope for Coltrane
    Then the collector is shown a message stating no records matched
