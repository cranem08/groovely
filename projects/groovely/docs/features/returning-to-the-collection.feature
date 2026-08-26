Feature: Returning to where you were

  Opening a record must not cost the collector their place.

  Scenario: A collector opens a record and goes back
    Given the collector has opened a record from the second page of a filtered collection
    When the collector goes back
    Then the collector is shown that same filtered collection at that same point

  Scenario: A collector returns to a bookmarked view
    Given the collector has bookmarked a filtered and sorted view of their collection
    When the collector opens that bookmark
    Then the collector is shown that same filtered and sorted view

  Scenario: A collector switches view while further down the collection
    Given the collector has loaded a second page in list view
    When the collector switches to grid view
    Then the collector is shown twelve records rather than twenty
