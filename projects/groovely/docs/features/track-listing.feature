Feature: Record the track listing

  What is printed on the sleeve. Groovely holds no audio and plays nothing.

  Scenario: A collector confirms a release that has a track listing
    Given the collector is shown a candidate release with a track listing
    When the collector confirms that candidate release
    Then the collector is shown the new record listing those tracks in their printed order

  Scenario: A collector adds a track by hand
    Given the collector owns a record with no tracks
    When the collector adds a track on side A at position one with a title
    Then the collector is shown that record listing that track at position A1

  Scenario: A collector saves a record without any tracks
    Given the collector is on the manual entry screen
    When the collector submits an artist and a title without adding any tracks
    Then the collector is shown the new record in their collection
